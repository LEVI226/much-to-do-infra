# ALB: accepts HTTP/HTTPS from the internet
resource "aws_security_group" "alb" {
  name        = "much-to-do-alb-sg"
  description = "Allow inbound HTTP/HTTPS to the Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "much-to-do-alb-sg" }
}

# Backend EC2: only accepts traffic from the ALB on port 8080
resource "aws_security_group" "backend" {
  name        = "much-to-do-backend-sg"
  description = "Allow inbound 8080 from ALB only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "API from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "much-to-do-backend-sg" }
}

# MongoDB EC2: only accepts traffic from backend instances
resource "aws_security_group" "mongodb" {
  name        = "much-to-do-mongodb-sg"
  description = "Allow inbound 27017 from backend EC2 only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "MongoDB from backend"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "much-to-do-mongodb-sg" }
}

# ElastiCache Redis: only accepts traffic from backend instances
resource "aws_security_group" "redis" {
  name        = "much-to-do-redis-sg"
  description = "Allow inbound 6379 from backend EC2 only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Redis from backend"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "much-to-do-redis-sg" }
}
