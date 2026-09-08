# =============================================================================
# metrics-server — PRE-REQUISITO DO HPA
#
# O kind NAO traz metrics-server. Sem ele o HPA fica assim para sempre:
#
#   $ kubectl get hpa -n todolist
#   NAME       REFERENCE             TARGETS              MINPODS  MAXPODS  REPLICAS
#   todolist   Deployment/todolist   <unknown>/70%        2        5        2
#
# e o evento correspondente e:
#   FailedGetResourceMetric  failed to get cpu utilization:
#   unable to get metrics for resource cpu: no metrics returned from resource
#   metrics API
#
# Os dois args abaixo sao obrigatorios no kind:
#
#   --kubelet-insecure-tls
#       o kubelet do kind serve as metricas com certificado auto-assinado que
#       nao esta na CA do cluster; sem essa flag o scrape falha com
#       "x509: cannot validate certificate".
#
#   --kubelet-preferred-address-types=InternalIP,...
#       o padrao tenta Hostname primeiro, e o hostname do no do kind nao
#       resolve dentro da rede de pods.
#
# Coloque este arquivo em infra/envs/local/ ao lado do main.tf.
# =============================================================================

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.1"
  namespace  = "kube-system"

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }

  set {
    name  = "args[1]"
    value = "--kubelet-preferred-address-types=InternalIP\\,ExternalIP\\,Hostname"
  }

  # Janela de resolucao das metricas. 15s deixa o HPA reagir mais rapido que
  # o padrao de 60s, o que importa para demonstrar scale-up em teste de carga.
  set {
    name  = "args[2]"
    value = "--metric-resolution=15s"
  }

  # Um unico no de metrics-server basta no local; evita disputa por CPU
  # no cluster kind rodando em laptop.
  set {
    name  = "replicas"
    value = "1"
  }

  wait    = true
  timeout = 300

  depends_on = [module.kind_cluster]
}
