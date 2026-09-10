# Infraestrutura

Provisionamento do ambiente com Terraform. O caminho de execução completo, do zero ao browser, está no [README raiz](../README.md).

## Estrutura

```
infra/
├── modules/
│   └── kind-cluster/     # módulo reutilizável: cria o cluster kind
├── envs/
│   └── local/            # ambiente local — entry point do terraform apply
│       ├── providers.tf         # required_providers e configuração dos providers
│       ├── main.tf              # módulo do cluster + ingress-nginx + ArgoCD + Application
│       ├── metrics-server.tf    # pré-requisito do HPA
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars     # valores padrão — edite aqui
└── argocd/
    └── application.yaml  # Application do ArgoCD apontando para o chart
```

## O que um `terraform apply` cria

1. Cluster kind com 1 control-plane e 2 workers
2. NGINX Ingress Controller (Helm)
3. metrics-server (Helm) — sem ele o HPA fica em `<unknown>` e nunca escala
4. ArgoCD (Helm)
5. `Application` do ArgoCD, que sincroniza o chart e sobe a aplicação

## Por que as portas são mapeadas

O kind cria nós Kubernetes como containers Docker. Um Ingress Controller roda *dentro* desses containers, e o Docker não expõe portas para o host automaticamente. O mapeamento resolve isso:

```
host :8080  →  control-plane :80
host :8443  →  control-plane :443
```

Assim `curl http://localhost:8080` chega ao Ingress do cluster.

## Customizações

Edite `envs/local/terraform.tfvars`:

| Variável | Padrão | Uso |
|---|---|---|
| `cluster_name` | `local-cluster` | Nome do cluster kind |
| `kubernetes_version` | `kindest/node:v1.30.0` | [Tags disponíveis](https://github.com/kubernetes-sigs/kind/releases) |
| `worker_count` | `2` | Quantidade de workers |
| `control_plane_host_port` | `8080` | Altere se a porta já estiver em uso |
| `control_plane_host_port_https` | `8443` | Idem |
| `api_server_port` | `46443` | Porta fixa do API server no host |

## Destruir

```bash
cd envs/local
terraform destroy
```

## Notas

- O estado do Terraform é local (`terraform.tfstate`), adequado para um ambiente de desenvolvimento de uma pessoa só. Em ambiente compartilhado, usar backend remoto com lock.
- Os providers `helm` e `kubectl` são configurados a partir de outputs do módulo do cluster. Em um `apply` sobre estado vazio, o Terraform resolve isso na mesma execução, mas um `plan` isolado antes do cluster existir não consegue avaliar a configuração dos providers.
