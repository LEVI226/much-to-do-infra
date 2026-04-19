output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name (backend API endpoint)"
  value       = aws_lb.backend.dns_name
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (frontend URL)"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (needed for cache invalidation)"
  value       = aws_cloudfront_distribution.frontend.id
}

output "s3_frontend_bucket" {
  description = "S3 bucket name for frontend assets"
  value       = aws_s3_bucket.frontend.id
}

output "backend_instance_ids" {
  description = "EC2 instance IDs for backend servers"
  value       = aws_instance.backend[*].id
}

output "backend_private_ips" {
  description = "Private IPs of backend EC2 instances"
  value       = aws_instance.backend[*].private_ip
}

output "mongodb_private_ip" {
  description = "Private IP of MongoDB EC2 instance"
  value       = aws_instance.mongodb.private_ip
}

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = "${aws_elasticache_cluster.redis.cache_nodes[0].address}:6379"
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for backend application logs"
  value       = aws_cloudwatch_log_group.backend.name
}

output "region" {
  description = "Deployment region"
  value       = var.region
}

output "developer_access_key_id" {
  description = "Access Key ID for grader user"
  value       = aws_iam_access_key.developer.id
  sensitive   = true
}

output "developer_secret_access_key" {
  description = "Secret Access Key for grader user"
  value       = aws_iam_access_key.developer.secret
  sensitive   = true
}
