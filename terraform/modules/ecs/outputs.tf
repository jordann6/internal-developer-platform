output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.idp.id
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.idp.name
}

output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.backstage.name
}

output "task_definition_arn" {
  description = "Task definition ARN"
  value       = aws_ecs_task_definition.backstage.arn
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs.id
}
