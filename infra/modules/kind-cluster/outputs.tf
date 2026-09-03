output "cluster_name" {
  description = "Nome do cluster criado"
  value       = kind_cluster.this.name
}

output "kubeconfig" {
  description = "Kubeconfig do cluster (conteúdo)"
  value       = kind_cluster.this.kubeconfig
  sensitive   = true
}

output "kubeconfig_path" {
  description = "Caminho do kubeconfig gerado pelo provider"
  value       = kind_cluster.this.kubeconfig_path
}

output "endpoint" {
  description = "Endpoint da API do cluster"
  value       = kind_cluster.this.endpoint
}

output "client_certificate" {
  value     = kind_cluster.this.client_certificate
  sensitive = true
}

output "client_key" {
  value     = kind_cluster.this.client_key
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = kind_cluster.this.cluster_ca_certificate
  sensitive = true
}
