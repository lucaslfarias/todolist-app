variable "cluster_name" {
  description = "Nome do cluster kind do ambiente de demonstracao"
  type        = string
  default     = "demo-cluster"
}

variable "kubernetes_version" {
  description = "Imagem do no kind (node image)"
  type        = string
  default     = "kindest/node:v1.30.0"
}

variable "worker_count" {
  description = "Quantidade de nos worker. Minimo 1: o control-plane tem taint NoSchedule."
  type        = number
  default     = 1
}

variable "control_plane_host_port" {
  description = "Porta HTTP no host. PRECISA ser diferente da usada pelo env local (8080)."
  type        = number
  default     = 9080
}

variable "control_plane_host_port_https" {
  description = "Porta HTTPS no host. PRECISA ser diferente da usada pelo env local (8443)."
  type        = number
  default     = 9443
}

variable "app_image_tag" {
  description = "Tag da imagem no GHCR. Fixa de proposito: o demo nao acompanha o CI."
  type        = string
  default     = "be07be5"
}

variable "app_color" {
  description = "Cor do tema. Diferente do local para a plateia distinguir os ambientes."
  type        = string
  default     = "blue"
}
