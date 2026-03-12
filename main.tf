locals {
  name_prefix = "${var.project_name}-${var.environment}"
  namespace   = "${var.project_name}/${var.environment}"
}

# ── SNS Alert Topic ───────────────────────────────────────────────────────────

resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ── CloudWatch Log Groups ─────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "application" {
  name              = "/app/${local.name_prefix}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/api/${local.name_prefix}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "infra" {
  name              = "/infra/${local.name_prefix}"
  retention_in_days = var.log_retention_days
}

# ── Custom Metric Filters ─────────────────────────────────────────────────────

resource "aws_cloudwatch_log_metric_filter" "app_errors" {
  name           = "${local.name_prefix}-app-errors"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "[timestamp, level=ERROR, ...]"

  metric_transformation {
    name          = "AppErrorCount"
    namespace     = local.namespace
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "api_errors" {
  name           = "${local.name_prefix}-api-errors"
  log_group_name = aws_cloudwatch_log_group.api.name
  pattern        = "[timestamp, level=ERROR, ...]"

  metric_transformation {
    name          = "ApiErrorCount"
    namespace     = local.namespace
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

# ── Alarms on Custom Metrics ──────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "app_error_rate" {
  alarm_name          = "${local.name_prefix}-app-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = aws_cloudwatch_log_metric_filter.app_errors.metric_transformation[0].name
  namespace           = local.namespace
  period              = 60
  statistic           = "Sum"
  threshold           = var.alarm_error_count_threshold
  alarm_description   = "Application error count exceeded threshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "api_error_rate" {
  alarm_name          = "${local.name_prefix}-api-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = aws_cloudwatch_log_metric_filter.api_errors.metric_transformation[0].name
  namespace           = local.namespace
  period              = 60
  statistic           = "Sum"
  threshold           = var.alarm_error_count_threshold
  alarm_description   = "API error count exceeded threshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# ── CloudWatch Dashboard ──────────────────────────────────────────────────────

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0; y = 0; width = 12; height = 6
        properties = {
          title  = "Application Error Count"
          region = var.aws_region
          metrics = [
            [local.namespace, "AppErrorCount", { stat = "Sum", label = "App Errors", color = "#d62728" }]
          ]
          period = 60
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12; y = 0; width = 12; height = 6
        properties = {
          title  = "API Error Count"
          region = var.aws_region
          metrics = [
            [local.namespace, "ApiErrorCount", { stat = "Sum", label = "API Errors", color = "#ff7f0e" }]
          ]
          period = 60
          view   = "timeSeries"
        }
      },
      {
        type   = "alarm"
        x      = 0; y = 6; width = 24; height = 4
        properties = {
          title  = "Active Alarms"
          alarms = [
            aws_cloudwatch_metric_alarm.app_error_rate.arn,
            aws_cloudwatch_metric_alarm.api_error_rate.arn,
          ]
        }
      },
      {
        type   = "log"
        x      = 0; y = 10; width = 24; height = 6
        properties = {
          title  = "Recent Application Errors"
          region = var.aws_region
          query  = "SOURCE '${aws_cloudwatch_log_group.application.name}' | fields @timestamp, @message | filter level = 'ERROR' | sort @timestamp desc | limit 50"
          view   = "table"
        }
      }
    ]
  })
}

# ── Composite Alarm ───────────────────────────────────────────────────────────

resource "aws_cloudwatch_composite_alarm" "overall_health" {
  alarm_name        = "${local.name_prefix}-overall-health"
  alarm_description = "Fires when any service alarm is in ALARM state"

  alarm_rule = join(" OR ", [
    "ALARM(${aws_cloudwatch_metric_alarm.app_error_rate.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.api_error_rate.alarm_name})",
  ])

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}
