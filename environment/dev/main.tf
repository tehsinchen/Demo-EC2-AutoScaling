locals {
  common = {
    # Infra releated variables
    region     = data.aws_region.current.id
    account_id = data.aws_caller_identity.current.account_id
  }

  vpc = {
    name                 = "${var.identity}-management-vpc"
    cidr                 = "10.10.0.0/16"
    private_subnet_cidrs = ["10.10.1.0/24", "10.10.2.0/24"]
  }

  asg = {
    name                = "app"
    type                = "t3.medium"
    detailed_monitoring = true
    user_data           = file("./app_user_data.sh")
    bounds = {
      min     = 1
      max     = 5
      desired = 1
    }
    thresholds = {
      scale_out = 60
      scale_in  = 10
      cooldown  = 180
    }
    periods = {
      scale_out     = 60 # sec
      scale_in      = 60 # sec
      scale_in_eval = 3
    }
    thresholds_alb = {
      scale_out = 500
    }
    periods_alb = {
      period   = 60
      eval_out = 1
    }
  }

  alb = {
    name     = "${var.identity}-alb"
    port     = 8080
    health   = "/health"
    internal = true
  }

  ec2 = {
    name      = "jmeter"
    type      = "t3.small"
    ami_id    = var.jmeter_ami_id
    user_data = file("./jmeter_user_data.sh")
    params = {
      threads     = 150
      rampup      = 20
      duration    = 180
      cores       = 2
      sec_per_req = 30
    }
  }


  services = merge(
    { vpc = local.vpc },
    { asg = local.asg },
    { alb = local.alb },
    { ec2 = local.ec2 }
  )
}

module "shared" {
  source   = "../../services/shared"
  common   = local.common
  services = local.services
}
