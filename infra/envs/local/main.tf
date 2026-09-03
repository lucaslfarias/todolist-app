# ─────────────────────────────────────────────────────────────────────────────
# 1. Cluster kind
# ─────────────────────────────────────────────────────────────────────────────
module "kind_cluster" {
  source = "../../modules/kind-cluster"

  cluster_name                  = var.cluster_name
  kubernetes_version            = var.kubernetes_version
  worker_count                  = var.worker_count
  control_plane_host_port       = var.control_plane_host_port
  control_plane_host_port_https = var.control_plane_host_port_https
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. NGINX Ingress Controller
# ─────────────────────────────────────────────────────────────────────────────
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.10.1"
  namespace        = "ingress-nginx"
  create_namespace = true

  # Configura o controller para usar as hostPorts mapeadas no kind
  # (container_port 80 → host_port 8080, conforme extraPortMappings do módulo)
  set {
    name  = "controller.hostPort.enabled"
    value = "true"
  }

  set {
    name  = "controller.service.type"
    value = "NodePort"
  }

  # Garante que o controller só suba no nó marcado como ingress-ready
  # (label aplicado pelo kubeadm_config_patches no módulo kind-cluster)
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

  # Aguarda o controller estar healthy antes de prosseguir
  wait    = true
  timeout = 300

  depends_on = [module.kind_cluster]
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. Aplicação TodoList (Helm Chart local)
# ─────────────────────────────────────────────────────────────────────────────
resource "helm_release" "todolist" {
  name             = "todolist"
  chart            = "${path.module}/../../../todolist-chart"
  namespace        = var.app_namespace
  create_namespace = true

  # ── Imagem ──────────────────────────────────────────────────────────────
  set {
    name  = "app.image.repository"
    value = var.app_image_repository
  }

  set {
    name  = "app.image.tag"
    value = var.app_image_tag
  }

  # ── Segredos da app (sensíveis) ──────────────────────────────────────────
  set_sensitive {
    name  = "app.secret.SESSION_KEY"
    value = var.app_session_key
  }

  set_sensitive {
    name  = "app.secret.ADMIN_PASSWORD"
    value = var.app_admin_password
  }

  set_sensitive {
    name  = "app.secret.CLEANUP_TOKEN"
    value = var.app_cleanup_token
  }

  set {
    name  = "app.secret.ADMIN_USER"
    value = var.app_admin_user
  }

  # ── Segredos do PostgreSQL (sensíveis) ───────────────────────────────────
  set_sensitive {
    name  = "postgresql.secret.POSTGRES_PASSWORD"
    value = var.db_password
  }

  # ── Ingress ──────────────────────────────────────────────────────────────
  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "ingress.host"
    value = var.ingress_host
  }

  wait    = true
  timeout = 300

  depends_on = [helm_release.ingress_nginx]
}
