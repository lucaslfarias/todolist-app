variable "cluster_name" {
  description = "Nome do cluster kind"
  type        = string
  default     = "local-cluster"
}

variable "kubernetes_version" {
  description = "Imagem do nó kind (node image)"
  type        = string
  default     = "kindest/node:v1.30.0"
}

variable "worker_count" {
  description = "Quantidade de nós worker"
  type        = number
  default     = 2
}

variable "control_plane_host_port" {
  description = "Porta do host mapeada para HTTP (container_port 80) do Ingress"
  type        = number
  default     = 8080
}

variable "control_plane_host_port_https" {
  description = "Porta do host mapeada para HTTPS (container_port 443) do Ingress"
  type        = number
  default     = 8443
}

variable "api_server_port" {
  description = "Porta fixa do API server no host"
  type        = number
  default     = 46443
}
