variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "demo"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
  default     = "ops@example.com"
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch log groups"
  type        = number
  default     = 30
}

variable "alarm_cpu_threshold" {
  description = "CPU utilization % threshold to trigger an alarm"
  type        = number
  default     = 80
}

variable "alarm_error_count_threshold" {
  description = "Number of errors within one evaluation period to trigger an alarm"
  type        = number
  default     = 5
}

variable "alarm_latency_p95_threshold_seconds" {
  description = "p95 response time in seconds to trigger an alarm"
  type        = number
  default     = 2
}
