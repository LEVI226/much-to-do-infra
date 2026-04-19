# Self-hosted MongoDB on a private EC2 instance
resource "aws_instance" "mongodb" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.mongodb_instance_type
  subnet_id              = module.vpc.database_subnets[0]
  vpc_security_group_ids = [aws_security_group.mongodb.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_backend.name

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/../scripts/mongodb-userdata.sh", {
    db_name = var.mongo_db_name
  }))

  tags = { Name = "much-to-do-mongodb" }
}
