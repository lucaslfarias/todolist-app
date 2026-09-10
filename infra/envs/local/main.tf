module "kind_cluster" {
  source = "../../modules/kind-cluster"

  cluster_name                  = var.cluster_name
  kubernetes_version            = var.kubernetes_version
  worker_count                  = var.worker_count
  control_plane_host_port       = var.control_plane_host_port
  control_plane_host_port_https = var.control_plane_host_port_https
  api_server_port               = var.api_server_port
}

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.10.1"
  namespace        = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.hostPort.enabled"
    value = "true"
  }

  set {
    name  = "controller.service.type"
    value = "NodePort"
  }

  set {
    name  = "controller.nodeSelector.ingress-ready"
    value = "true"
    type  = "string"
  }

  set {
    name  = "controller.tolerations[0].key"
    value = "node-role.kubernetes.io/control-plane"
  }

  set {
    name  = "controller.tolerations[0].effect"
    value = "NoSchedule"
  }

  wait    = true
  timeout = 300

  depends_on = [module.kind_cluster]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.3.11"
  namespace        = "argocd"
  create_namespace = true

  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }

  set {
    name  = "configs.cm.timeout\\.reconciliation"
    value = "30s"
  }

  wait    = true
  timeout = 600

  depends_on = [helm_release.ingress_nginx]
}

resource "kubectl_manifest" "argocd_application" {
  yaml_body = file("${path.module}/../../argocd/application.yaml")

  depends_on = [helm_release.argocd]
}
