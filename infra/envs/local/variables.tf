# ── Cluster ───────────────────────────────────────────────────────────────────
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

# ── Aplicação ─────────────────────────────────────────────────────────────────
variable "app_namespace" {
  description = "Namespace Kubernetes da aplicação"
  type        = string
  default     = "todolist"
}

variable "app_image_repository" {
  description = "Repositório da imagem Docker da app"
  type        = string
  default     = "todolist-app"
}

variable "app_image_tag" {
  description = "Tag da imagem Docker da app"
  type        = string
  default     = "v1"
}

variable "app_session_key" {
  description = "Chave de sessão da aplicação"
  type        = string
  sensitive   = true
  default     = "dev-session-key"
}

variable "app_admin_user" {
  description = "Usuário administrador da aplicação"
  type        = string
  default     = "admin"
}

variable "app_admin_password" {
  description = "Senha do administrador da aplicação"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "app_cleanup_token" {
  description = "Token para operações de limpeza"
  type        = string
  sensitive   = true
  default     = "dev-cleanup-token"
}

# ── Banco de dados ────────────────────────────────────────────────────────────
variable "db_password" {
  description = "Senha do PostgreSQL"
  type        = string
  sensitive   = true
  default     = "todolist"
}

# ── Ingress ───────────────────────────────────────────────────────────────────
variable "ingress_host" {
  description = "Host do Ingress (usar 'localhost' para ambiente kind local)"
  type        = string
  default     = "localhost"
}
