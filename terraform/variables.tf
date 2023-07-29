variable "cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks for the subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "ebs_az" {
  description = "The AWS Availability Zone in which to create the EBS volume"
  type        = string
  default     = "us-east-2c"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones for the subnets"
  default     = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "demo_server_ip" {
  description = "The IP address of the demo server"
  type        = string
  default     = "3.131.245.27"
}

variable "key_name" {
  description = "The name of the key pair"
  type        = string
  default     = "mongodb-in-eks.pem"
}

variable "aws_region" {
  description = "The AWS region"
  type        = string
  default     = "us-east-2"
}

variable "aws_user" {
  description = "The AWS user"
  type        = string
  default     = "eksuser"
}

variable "vpc_cidr" {
  description = "The VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "bucket_name" {
  description = "The S3 bucket name"
  type        = string
  default     = "mongodb-on-eks"
}

variable "instance_type" {
  description = "Instance type of bastion instance"
  type        = string
  default     = "t3.small"
}

variable "server_name" {
  description = "The name of the server"
  type        = string
  default     = "bastion-server"  # Name of the server
}

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
}
