variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "key_name" {
  description = "Name of an existing EC2 key pair (optional if using SSM only)"
  type        = string
  default     = null
  nullable    = true
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}
