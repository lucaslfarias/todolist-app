# =============================================================================
# ENV DEMO — ambiente descartavel para mostrar a aplicacao funcionando.
#
# Diferencas propositais em relacao ao env local:
#   - SEM ArgoCD        : o chart e instalado direto por helm_release. Aqui o
#                         assunto e "a aplicacao funciona", nao GitOps.
#   - SEM metrics-server: sem ele o HPA fica <unknown>/70% para sempre, entao
#                         o HPA vem desligado (app.hpa.enabled = false) e o
#                         Deployment usa app.replicas.
#   - 1 worker          : o control-plane do kind tem taint NoSchedule, logo
#                         worker_count = 0 deixaria todos os pods Pending.
#   - Portas 9080/9443  : os dois clusters coexistem enquanto o local sobe.
#
# Este env e destruido durante a apresentacao, antes da parte de ArgoCD.
# =============================================================================

module "kind_cluster" {
  source = "../../modules/kind-cluster"

  cluster_name                  = var.cluster_name
  kubernetes_version            = var.kubernetes_version
  worker_count                  = var.worker_count
  control_plane_host_port       = var.control_plane_host_port
  control_plane_host_port_https = var.control_plane_host_port_https
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

# -----------------------------------------------------------------------------
# A aplicacao, instalada direto do chart local — sem ArgoCD no meio.
# -----------------------------------------------------------------------------
resource "helm_release" "todolist" {
  name             = "todolist"
  chart            = "${path.module}/../../../todolist-chart"
  namespace        = "todolist"
  create_namespace = true

  values = [
    yamlencode({
      app = {
        image = {
          tag = var.app_image_tag
        }
        replicas = 2
        env = {
          APP_NAME  = "TodoList (demo)"
          APP_COLOR = var.app_color
        }
        # Sem metrics-server neste cluster: com o HPA ligado ele nunca leria
        # metrica alguma. Desligado, o Deployment volta a declarar replicas.
        hpa = {
          enabled = false
        }
      }
    })
  ]

  wait    = true
  timeout = 600

  depends_on = [helm_release.ingress_nginx]
}
