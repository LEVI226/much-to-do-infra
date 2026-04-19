resource "aws_cloudwatch_log_group" "backend" {
  name              = "/much-to-do/backend"
  retention_in_days = 14

  tags = { Name = "much-to-do-backend-logs" }
}

resource "aws_cloudwatch_log_group" "mongodb" {
  name              = "/much-to-do/mongodb"
  retention_in_days = 7

  tags = { Name = "much-to-do-mongodb-logs" }
}
