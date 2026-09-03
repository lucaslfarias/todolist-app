variable "cluster_name" {
  description = "Nome do cluster kind"
  type        = string
  default     = "local-cluster"
}

variable "kubernetes_version" {
  description = "Versão da imagem do nó kind (node image)"
  type        = string
  # Consulte: https://github.com/kubernetes-sigs/kind/releases
  default     = "kindest/node:v1.30.0"
}

variable "worker_count" {
  description = "Quantidade de nós worker"
  type        = number
  default     = 2
}

variable "control_plane_host_port" {
  description = "Porta do host mapeada para o NodePort/Ingress HTTP (80) do control-plane"
  type        = number
  default     = 8080
}

variable "control_plane_host_port_https" {
  description = "Porta do host mapeada para o NodePort/Ingress HTTPS (443) do control-plane"
  type        = number
  default     = 8443
}
