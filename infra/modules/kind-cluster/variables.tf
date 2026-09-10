variable "cluster_name" {
  description = "Nome do cluster kind"
  type        = string
}

variable "kubernetes_version" {
  description = "Imagem do nó kind (node image)"
  type        = string
}

variable "worker_count" {
  description = "Quantidade de nós worker"
  type        = number
}

variable "control_plane_host_port" {
  description = "Porta do host mapeada para HTTP (container_port 80) do Ingress"
  type        = number
}

variable "control_plane_host_port_https" {
  description = "Porta do host mapeada para HTTPS (container_port 443) do Ingress"
  type        = number
}

variable "api_server_port" {
  description = "Porta fixa do API server no host. Precisa ser única por cluster."
  type        = number
  default     = 46443
}

variable "api_server_address" {
  description = "Endereço em que o API server escuta no host"
  type        = string
  default     = "127.0.0.1"
}
