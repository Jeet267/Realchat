output "ecr_repository_url" {
  description = "ECR repository URL for pushing Docker images"
  value       = aws_ecr_repository.app_repo.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.app_cluster.name
}

output "ecs_service_name" {
  description = "Name of the ECS Fargate service"
  value       = aws_ecs_service.app_service.name
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}
