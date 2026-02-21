resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "demo-asg-alb"
  dashboard_body = jsonencode({
    widgets = [
      {
        "type" : "metric", "x" : 0, "y" : 0, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "ASG CPU",
          "metrics" : [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name, { "stat" : "Average" }],
          ],
          "annotations" : {
            "horizontal" : [
              [
                { "label" : "Scale OUT", "value" : var.config.thresholds.scale_out, "color" : "#9467bd", "visible" : true, "yAxis" : "left" },
                { "label" : "Scale IN", "value" : var.config.thresholds.scale_in }
              ]
            ]
          },
          "view" : "timeSeries", "stacked" : false,
          "region" : var.common.region, "period" : 60
        }
      },
      {
        "type" : "metric", "x" : 0, "y" : 6, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "ALB Request Count",
          "metrics" : [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { "stat" : "Sum", "label" : "total" }],
            # ["AWS/ApplicationELB", "RequestCountPerTarget", "LoadBalancer", var.tg_arn_suffix, { "stat" : "Sum", "label" : "per target" }]
          ],
          "annotations" : {
            "horizontal" : [
              { "label" : "Scale OUT", "value" : var.config.thresholds_alb.scale_out, "color" : "#9467bd", "visible" : true, "yAxis" : "left" },
            ]
          },
          "view" : "timeSeries", "stacked" : false,
          "region" : var.common.region, "period" : 60
        }
      },
      {
        "type" : "metric", "x" : 12, "y" : 0, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "ASG Status",
          "metrics" : [
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", var.asg_name, { "stat" : "Sum", "label" : "# of Instance" }]
          ],
          "annotations" : {
            "horizontal" : [
              { "visible" : true, "color" : "#9467bd", "label" : "min", "value" : var.config.bounds.min, "yAxis" : "left" },
              { "visible" : true, "color" : "#9467bd", "label" : "max", "value" : var.config.bounds.max, "yAxis" : "left" },
              { "visible" : true, "color" : "#9467bd", "label" : "desired", "value" : var.config.bounds.desired, "yAxis" : "left" }
            ]
          },
          "view" : "timeSeries", "stacked" : false,
          "region" : var.common.region, "period" : 60
        }
      },
      {
        "type" : "metric", "x" : 12, "y" : 6, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "ASG Detail",
          "metrics" : [
            ["AWS/AutoScaling", "GroupPendingInstances", "AutoScalingGroupName", var.asg_name, { "stat" : "Sum", "label" : "Pending" }],
            [".", "GroupTerminatingInstances", ".", ".", { "stat" : "Sum", "label" : "Terminating" }]
          ],
          "view" : "timeSeries", "stacked" : false,
          "region" : var.common.region, "period" : 60
        }
      },
      {
        "type" : "metric", "x" : 0, "y" : 12, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "Target Group HTTP 2xx",
          "metrics" : [
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "TargetGroup", var.tg_arn_suffix, "LoadBalancer", var.alb_arn_suffix, { "stat" : "Sum" }]
          ],
          "view" : "timeSeries", "stacked" : false,
          "region" : var.common.region, "period" : 60
        }
      },
      {
        "type" : "metric", "x" : 12, "y" : 12, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "ALB TargetResponseTime (Average & p95)",
          "metrics" : [
            ["AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", var.tg_arn_suffix, "LoadBalancer", var.alb_arn_suffix, { "stat" : "Average", "label" : "Avg" }],
            [".", ".", ".", ".", ".", ".", { "stat" : "p95", "label" : "p95" }]
          ],
          "view" : "timeSeries", "stacked" : false,
          "region" : var.common.region, "period" : 60
        }
      },
      {
        "type" : "metric", "x" : 0, "y" : 18, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "5xx Breakdown (Target vs ELB)",
          "metrics" : [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "TargetGroup", var.tg_arn_suffix, "LoadBalancer", var.alb_arn_suffix, { "stat" : "Sum", "label" : "Target 5xx" }],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { "stat" : "Sum", "label" : "ELB 5xx" }]
          ],
          "view" : "timeSeries", "stacked" : false,
          "region" : var.common.region, "period" : 60
        }
      },
      {
        "type" : "metric", "x" : 12, "y" : 18, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "TargetConnectionErrorCount",
          "metrics" : [
            ["AWS/ApplicationELB", "TargetConnectionErrorCount", "TargetGroup", var.tg_arn_suffix, "LoadBalancer", var.alb_arn_suffix, { "stat" : "Sum" }]
          ],
          "view" : "timeSeries", "stacked" : false,
          "region" : var.common.region, "period" : 60
        }
      },
      {
        "type" : "metric", "x" : 0, "y" : 24, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "Target Group Health",
          "metrics" : [
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", var.tg_arn_suffix, "LoadBalancer", var.alb_arn_suffix, { "stat" : "Maximum", "label" : "Healthy" }],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", var.tg_arn_suffix, "LoadBalancer", var.alb_arn_suffix, { "stat" : "Maximum", "label" : "UnHealthy" }]
          ],
          "yAxis" : {
            "left" : { "label" : "Hosts" }
          },
          "view" : "timeSeries", "stacked" : false,
          "region" : var.common.region, "period" : 60
        }
      }
    ]
  })
}
