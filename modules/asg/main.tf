# ---- IAM for the ASG instances (put near top of this file) ----
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "asg_instance_role" {
  name               = "${var.config.name}-asg-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_instance_profile" "asg_instance_profile" {
  name = "${var.config.name}-asg-instance-profile"
  role = aws_iam_role.asg_instance_role.name
}

# SSM core so you can use Session Manager on the app instances
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.asg_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_launch_template" "this" {
  name_prefix            = "${var.config.name}-lt-"
  image_id               = data.aws_ssm_parameter.al2023_ami.value
  instance_type          = var.config.type
  vpc_security_group_ids = [var.app_sg_id]
  user_data              = base64encode(var.config.user_data)

  iam_instance_profile {
    name = aws_iam_instance_profile.asg_instance_profile.name
  }

  monitoring {
    enabled = var.config.detailed_monitoring
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      encrypted             = true
      delete_on_termination = true
    }
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.config.name}-app" }
  }
}

resource "aws_autoscaling_group" "this" {
  name                      = "${var.config.name}-asg"
  max_size                  = var.config.bounds.max
  min_size                  = var.config.bounds.min
  desired_capacity          = var.config.bounds.desired
  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = 300
  target_group_arns         = [var.target_group_arn]
  default_cooldown          = var.config.thresholds.cooldown

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 9 # Keep 90% of capacity up during updates
      instance_warmup        = 120
    }
    triggers = ["launch_template"]
  }

  metrics_granularity = "1Minute"
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  lifecycle { create_before_destroy = true }
}

resource "aws_autoscaling_policy" "scale_out" {
  name                      = "cpu-scale-out"
  autoscaling_group_name    = aws_autoscaling_group.this.name
  policy_type               = "StepScaling"
  adjustment_type           = "ChangeInCapacity"
  metric_aggregation_type   = "Average"
  estimated_instance_warmup = 120

  step_adjustment {
    metric_interval_lower_bound = 20
    scaling_adjustment          = 2
  }

  step_adjustment {
    scaling_adjustment          = 1
    metric_interval_upper_bound = 20
    metric_interval_lower_bound = 0
  }
}

resource "aws_autoscaling_policy" "scale_in" {
  name                    = "cpu-scale-in"
  autoscaling_group_name  = aws_autoscaling_group.this.name
  policy_type             = "StepScaling"
  adjustment_type         = "ChangeInCapacity"
  metric_aggregation_type = "Average"
  step_adjustment {
    scaling_adjustment          = -1
    metric_interval_upper_bound = 0
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${aws_autoscaling_group.this.name}-cpu>=${var.config.thresholds.scale_out}"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = var.config.periods.scale_out
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.config.thresholds.scale_out
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]
  dimensions          = { AutoScalingGroupName = aws_autoscaling_group.this.name }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name         = "${aws_autoscaling_group.this.name}-cpu<=${var.config.thresholds.scale_in}"
  namespace          = "AWS/EC2"
  metric_name        = "CPUUtilization"
  statistic          = "Average"
  period             = var.config.periods.scale_in
  evaluation_periods = var.config.periods.scale_in_eval
  # datapoints_to_alarm = var.config.periods.scale_in_eval
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = var.config.thresholds.scale_in
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]
  dimensions          = { AutoScalingGroupName = aws_autoscaling_group.this.name }
}

resource "aws_autoscaling_policy" "alb_reqcount_scale_out" {
  name                      = "alb-reqcount-scale-out"
  autoscaling_group_name    = aws_autoscaling_group.this.name
  policy_type               = "StepScaling"
  adjustment_type           = "ChangeInCapacity"
  metric_aggregation_type   = "Average"
  estimated_instance_warmup = 120

  step_adjustment {
    scaling_adjustment          = 1
    metric_interval_lower_bound = 0
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_reqcount_high" {
  alarm_name          = "${aws_autoscaling_group.this.name}-alb-RequestCount>=${var.config.thresholds_alb.scale_out}"
  alarm_description   = "Scale out when ALB RequestCount >= ${var.config.thresholds_alb.scale_out} in one ${var.config.periods_alb.period}s period"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.config.periods_alb.eval_out
  threshold           = var.config.thresholds_alb.scale_out
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_autoscaling_policy.alb_reqcount_scale_out.arn]

  metric_name = "RequestCount"
  namespace   = "AWS/ApplicationELB"
  period      = var.config.periods_alb.period
  statistic   = "Sum"
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}