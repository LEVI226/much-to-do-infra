# Two backend EC2 instances — one per AZ for high availability
resource "aws_instance" "backend" {
  count = 2

  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.backend_instance_type
  subnet_id              = module.vpc.private_subnets[count.index]
  vpc_security_group_ids = [aws_security_group.backend.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_backend.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = base64encode(templatefile("${path.module}/../scripts/backend-userdata.sh", {
    mongo_uri      = "mongodb://${aws_instance.mongodb.private_ip}:27017/${var.mongo_db_name}"
    db_name        = var.mongo_db_name
    redis_addr     = "${aws_elasticache_cluster.redis.cache_nodes[0].address}:6379"
    jwt_secret_key = var.jwt_secret_key
    port           = "8080"
    allowed_origins = aws_cloudfront_distribution.frontend.domain_name
  }))

  tags = { Name = "much-to-do-backend-${count.index + 1}" }

  depends_on = [aws_instance.mongodb, aws_elasticache_cluster.redis]
}

# ALB target group registration
resource "aws_lb_target_group_attachment" "backend" {
  count            = 2
  target_group_arn = aws_lb_target_group.backend.arn
  target_id        = aws_instance.backend[count.index].id
  port             = 8080
}
