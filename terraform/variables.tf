variable "aws_region" {
  description = "The AWS region to deploy into (e.g. us-east-1)."
  default     = "us-east-1"
}

variable "state_s3_bucket" {
  description = "The s3 bucket to store the terraform state information"
}

variable "app_name" {
  type        = string
  description = "naming for this deployment, change this for multiple deployments"
}

variable "vpc_id" {
  type        = string
  description = "The id of the vpc to deploy in"
}

variable "hub_image" {
  type        = string
  description = "The selenium container image to use for the hub node"
  default = "selenium/hub:3.141.59"
}

variable "chrome_image" {
  type        = string
  description = "The selenium container image to use for the chrome nodes"
  default = "selenium/node-chrome:3.141.59-20210713"
}

variable "firefox_image" {
  type        = string
  description = "The selenium container image to use for the firefox nodes"
  default = "selenium/node-firefox:3.141.59-20210713"
}

variable "subnet_ids_elb" {
   type    = list(string)
   description = "The subnet ids for the elb"
}

variable "idle_timeout_elb" {
   type    = number
   description = "time in seconds that the elb connection is allowed to be idle"
   default = 4000
}

variable "subnet_ids_nodes" {
  type    = list(string)  
  description = "The subnet ids for the node containers"
}

variable "subnet_ids_hub" {
   type    = list(string)
   description = "The subnet ids for the hub containers"
}

variable "chrome_scale_up" {
  description = "The number of containers to add when scaling out"
  type = number
  default = 3
}

variable "firefox_scale_up" {
  description = "The number of containers to add when scaling out"
  type = number
  default = 3
}

variable "chrome_cpu_scale_in_threshold" {
  type = number
  default = 10
}

variable "firefox_cpu_scale_in_threshold" {
  type = number
  default = 10
}

variable "chrome_cpu_scale_out_threshold" {
  type = number
  default = 90
}

variable "firefox_cpu_scale_out_threshold" {
  type = number
  default = 90
}

variable "chrome_min_tasks" {
  type = number
  default = 1
}

variable "firefox_min_tasks" {
  type = number
  default = 1
}

variable "chrome_max_tasks" {
  type = number
  default = 10
}

variable "firefox_max_tasks" {
  type = number
  default = 10
}

variable "hub_cpu" {
  type = number
}

variable "hub_mem" {
  type = number
}

variable "chrome_cpu" {
  type = number
}

variable "chrome_mem" {
  type = number
}

variable "firefox_cpu" {
  type = number
}

variable "firefox_mem" {
  type = number
}
