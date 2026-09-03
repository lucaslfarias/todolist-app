module "kind_cluster" {
  source = "../../modules/kind-cluster"

  cluster_name                  = var.cluster_name
  kubernetes_version            = var.kubernetes_version
  worker_count                  = var.worker_count
  control_plane_host_port       = var.control_plane_host_port
  control_plane_host_port_https = var.control_plane_host_port_https
}
