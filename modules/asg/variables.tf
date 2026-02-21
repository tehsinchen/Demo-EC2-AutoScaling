variable "common" {
  default = {}
}

variable "config" {
  default = {}
}

variable "vpc_id" {
  default = ""
}

variable "subnet_ids" {
  default = []
}

variable "app_sg_id" {
  default = ""
}

variable "target_group_arn" {
  default = ""
}

variable "alb_arn_suffix" {
  default = ""
}

variable "tg_arn_suffix" {
  default = ""
}
