output "cluster_name" {
  description = "Nome do cluster kind do demo"
  value       = module.kind_cluster.cluster_name
}

output "kubeconfig_path" {
  description = "Caminho do kubeconfig gerado pelo provider"
  value       = module.kind_cluster.kubeconfig_path
}

output "app_url" {
  description = "URL da aplicacao no ambiente de demo"
  value       = "http://localhost:${var.control_plane_host_port}"
}

output "app_healthz" {
  description = "Health check do demo"
  value       = "http://localhost:${var.control_plane_host_port}/healthz"
}
