variable "cluster_name" {
  type    = string
  default = "local-cluster"
}

variable "kubernetes_version" {
  type    = string
  default = "kindest/node:v1.30.0"
}

variable "worker_count" {
  type    = number
  default = 2
}

variable "control_plane_host_port" {
  type    = number
  default = 8080
}

variable "control_plane_host_port_https" {
  type    = number
  default = 8443
}
