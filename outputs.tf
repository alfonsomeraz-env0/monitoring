output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_url" {
  description = "URL to view the CloudWatch dashboard in the AWS console"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "application_log_group" {
  description = "CloudWatch log group for application logs"
  value       = aws_cloudwatch_log_group.application.name
}

output "api_log_group" {
  description = "CloudWatch log group for API logs"
  value       = aws_cloudwatch_log_group.api.name
}

output "infra_log_group" {
  description = "CloudWatch log group for infrastructure logs"
  value       = aws_cloudwatch_log_group.infra.name
}

output "composite_alarm_arn" {
  description = "ARN of the composite health alarm"
  value       = aws_cloudwatch_composite_alarm.overall_health.arn
}
