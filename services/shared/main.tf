module "vpc" {
  source = "../../modules/vpc"
  common = var.common
  config = var.services.vpc
}

module "sg" {
  source = "../../modules/sg"
  common = var.common
  # config = var.services.ec2
  vpc_id = module.vpc.vpc_id
}

module "alb" {
  source            = "../../modules/alb"
  common            = var.common
  config            = var.services.alb
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.sg.alb_sg_id
}

module "asg" {
  source           = "../../modules/asg"
  common           = var.common
  config           = var.services.asg
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnet_ids
  app_sg_id        = module.sg.app_sg_id
  alb_arn_suffix   = module.alb.alb_arn_suffix
  tg_arn_suffix    = module.alb.tg_arn_suffix
  target_group_arn = module.alb.target_group_arn
}

module "observe" {
  source         = "../../modules/cloudwatch"
  common         = var.common
  config         = var.services.asg
  asg_name       = module.asg.asg_name
  alb_arn_suffix = module.alb.alb_arn_suffix
  tg_arn_suffix  = module.alb.tg_arn_suffix
}

module "jmeter" {
  source            = "../../modules/ec2"
  common            = var.common
  config            = var.services.ec2
  subnet_id         = module.vpc.private_subnet_ids[0]
  vpc_id            = module.vpc.vpc_id
  security_group_id = module.sg.jmeter_sg_id
}
