# Infra Kind — Bloco 1: Cluster Kubernetes local com Terraform

## Pré-requisitos

| Ferramenta | Versão mínima | Verificar |
|---|---|---|
| Docker | 24+ | `docker version` |
| kind | 0.22+ | `kind version` |
| Terraform | 1.6+ | `terraform version` |
| kubectl | qualquer recente | `kubectl version --client` |

> **WSL2 / macOS Docker Desktop**: certifique-se de que o Docker daemon está rodando
> e acessível via socket padrão (`/var/run/docker.sock`).

---

## Estrutura de arquivos

```
infra-kind/
├── modules/
│   └── kind-cluster/        # módulo reutilizável
│       ├── main.tf          # recurso kind_cluster
│       ├── variables.tf
│       └── outputs.tf
└── envs/
    └── local/               # ambiente local (entry point)
        ├── providers.tf     # required_providers + provider "kind"
        ├── main.tf          # chama o módulo
        ├── variables.tf
        ├── outputs.tf
        └── terraform.tfvars # valores padrão — edite aqui
```

---

## Por que mapeamos portas?

O kind cria nós Kubernetes como **containers Docker**.
Serviços do tipo `NodePort` ou um Ingress Controller rodam *dentro* desses containers —
e o Docker não expõe portas automaticamente para o host.

O mapeamento abaixo faz o Docker "furar" essa barreira:

```
Sua máquina :8080  →  container control-plane :80
Sua máquina :8443  →  container control-plane :443
```

Assim, `curl http://localhost:8080` chega até o Ingress/NodePort do cluster.

---

## Passo a passo

### 1. Inicializar o Terraform

```bash
cd envs/local
terraform init
```

Saída esperada:
```
Initializing provider plugins...
- Finding tehcyx/kind versions matching "~> 0.4"...
- Installing tehcyx/kind v0.4.x...
Terraform has been successfully initialized!
```

### 2. Revisar o plano

```bash
terraform plan
```

Você verá `1 to add` — o recurso `kind_cluster.this`.

### 3. Criar o cluster

```bash
terraform apply
```

Digite `yes` quando solicitado.
O provider aguarda o cluster ficar `Ready` (`wait_for_ready = true`) antes de finalizar.
Tempo médio: **1–3 minutos** dependendo da velocidade do download da imagem.

Saída final esperada:
```
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:
cluster_name    = "local-cluster"
endpoint        = "https://127.0.0.1:XXXXX"
kubeconfig_path = "/home/<user>/.kube/kind-local-cluster"
```

### 4. Configurar o kubectl

O provider já escreve o kubeconfig automaticamente.
Para usar o contexto do cluster:

```bash
# Opção A — setar a variável de ambiente
export KUBECONFIG=$(terraform output -raw kubeconfig_path)

# Opção B — mesclar com o kubeconfig padrão
kind export kubeconfig --name local-cluster
```

### 5. Validar o cluster

```bash
kubectl get nodes -o wide
```

Saída esperada (1 control-plane + 2 workers):
```
NAME                          STATUS   ROLES           AGE   VERSION
local-cluster-control-plane   Ready    control-plane   2m    v1.30.0
local-cluster-worker          Ready    <none>          90s   v1.30.0
local-cluster-worker2         Ready    <none>          90s   v1.30.0
```

```bash
# Verificações extras
kubectl cluster-info
kubectl get namespaces
kubectl get pods -A          # pods do sistema (coredns, kindnet, etc.)
```

---

## Destruir o cluster

```bash
terraform destroy
```

---

## Customizações comuns

### Mudar versão do Kubernetes

Edite `terraform.tfvars`:
```hcl
kubernetes_version = "kindest/node:v1.29.4"
```
Veja todas as tags disponíveis: https://github.com/kubernetes-sigs/kind/releases

### Mais workers

```hcl
worker_count = 3
```

### Mudar as portas do host (se 8080/8443 já estiverem ocupadas)

```hcl
control_plane_host_port       = 9080
control_plane_host_port_https = 9443
```
