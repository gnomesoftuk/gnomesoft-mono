output "alb_domain" {
  value = module.alb.dns_name
}

output "ecs_cluster_id" {
  value = module.ecs_cluster
}