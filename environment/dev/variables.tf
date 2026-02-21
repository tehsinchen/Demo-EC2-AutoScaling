variable "profile_infra" {
  type        = string
  description = "AWS CLI profile used for provisioning infrastructure"
  default     = "aws-test"
}

variable "identity" {
  type        = string
  description = "Unique identity string used for tagging and naming"
  default     = "derek"
}

variable "product" {
  type        = string
  description = "Name of the product or application"
  default     = "demo"
}

variable "phase" {
  type        = string
  description = "Deployment phase (e.g., dev, test, staging, prod)"
  default     = "test"
}

variable "service" {
  type        = string
  description = "Name of the service being deployed"
  default     = "template"
}

variable "region" {
  type        = string
  description = "AWS region where resources will be deployed"
  default     = "ap-southeast-1"
}

variable "jmeter_ami_id" {
  type    = string
  default = "ami-081c455957d523535"
}