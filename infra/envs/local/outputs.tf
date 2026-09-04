output "cluster_name" {
  description = "Nome do cluster kind criado"
  value       = module.kind_cluster.cluster_name
}

output "kubeconfig_path" {
  description = "Caminho do kubeconfig gerado pelo provider"
  value       = module.kind_cluster.kubeconfig_path
}

output "endpoint" {
  description = "Endpoint da API do cluster"
  value       = module.kind_cluster.endpoint
}

output "app_url" {
  description = "URL de acesso à aplicação via Ingress"
  value       = "http://localhost:${var.control_plane_host_port}"
}

output "app_healthz" {
  description = "Endpoint de health check da aplicação"
  value       = "http://localhost:${var.control_plane_host_port}/healthz"
}

output "ingress_nginx_status" {
  description = "Status do helm release do ingress-nginx"
  value       = helm_release.ingress_nginx.status
}

output "todolist_status" {
  description = "Status do helm release da aplicação"
  value       = helm_release.todolist.status
}
