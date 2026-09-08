# metrics-server — pre-requisito do HPA.
#
# O kind nao inclui metrics-server. Sem ele o HPA reporta TARGETS <unknown>
# indefinidamente e emite FailedGetResourceMetric, nunca escalando.
#
# As duas primeiras flags sao obrigatorias no kind:
#   --kubelet-insecure-tls
#     o kubelet do kind serve metricas com certificado auto-assinado fora da
#     CA do cluster; sem a flag o scrape falha com "x509: cannot validate
#     certificate".
#   --kubelet-preferred-address-types
#     o padrao tenta Hostname primeiro, e o hostname do no do kind nao resolve
#     dentro da rede de pods.

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

  # Resolucao de 15s (padrao: 60s) para o HPA reagir mais rapido a variacao
  # de carga.
  set {
    name  = "args[2]"
    value = "--metric-resolution=15s"
  }

  # Replica unica: o ambiente local nao precisa de HA e o cluster kind roda
  # em uma unica maquina.
  set {
    name  = "replicas"
    value = "1"
  }

  wait    = true
  timeout = 300

  depends_on = [module.kind_cluster]
}
