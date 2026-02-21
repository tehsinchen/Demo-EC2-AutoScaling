resource "aws_lb" "this" {
  name               = "${var.config.name}-alb"
  internal           = var.config.internal
  load_balancer_type = "application"
  idle_timeout       = 120
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids
}

resource "aws_lb_target_group" "this" {
  name                 = "${var.config.name}-tg"
  port                 = var.config.port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = 120
  health_check {
    enabled             = true
    matcher             = "200"
    path                = var.config.health
    interval            = 30
    timeout             = 6
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}