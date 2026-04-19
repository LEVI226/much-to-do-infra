# EC2 instance profile — grants CloudWatch agent + SSM access to backend instances
resource "aws_iam_role" "ec2_backend" {
  name = "much-to-do-ec2-backend-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "much-to-do-ec2-backend-role" }
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2_backend.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_backend.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_backend" {
  name = "much-to-do-ec2-backend-profile"
  role = aws_iam_role.ec2_backend.name
}

# Grader IAM user — ReadOnly access so the assessor can verify all resources
resource "aws_iam_user" "developer" {
  name = var.developer_username
  path = "/"

  tags = {
    Name        = "Much-To-Do Grader View User"
    Description = "Read-only access for assessment grading"
  }
}

resource "aws_iam_user_policy_attachment" "developer_readonly" {
  user       = aws_iam_user.developer.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_access_key" "developer" {
  user = aws_iam_user.developer.name
}
