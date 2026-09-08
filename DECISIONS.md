# Registro de decisões

Decisões técnicas relevantes tomadas durante o desafio.
## Kubernetes local: kind

**Escolha:** kind (Kubernetes in Docker)

kind cria nós Kubernetes como containers Docker, o que elimina a necessidade de VMs e funciona diretamente no Docker Desktop ou em WSL2. O provider Terraform `tehcyx/kind` permite criar e destruir o cluster via `terraform apply/destroy`, mantendo tudo reproduzível.

**Descartado:**
- **minikube:** cria uma VM por padrão.
- **k3s/k3d:** opção válida, porem teria que instalar wsl ou usar VM.
- **Cloud (EKS, GKE, AKS):** o desafio pede ambiente local; cloud adicionaria custo e dependência de conta externa.

---

## Provisionamento: Terraform

**Escolha:** Terraform com módulo `kind-cluster` reutilizável

Terraform garante que o ambiente é criado da mesma forma em qualquer máquina, sem passos manuais. A separação em módulo (`modules/kind-cluster`) e environment (`envs/local`) deixa a estrutura pronta para adicionar outros environments futuramente.

**Descartado:**
- **Scripts shell:** funcionam para criação, mas não gerenciam estado nem destruição de forma confiável.
- **Helm direto:** Helm gerencia aplicações, não infraestrutura. Usar Terraform para o cluster e Helm para as aplicações é a separação correta de responsabilidades.

---

## Empacotamento: Helm Chart

**Escolha:** Helm chart local em `todolist-chart/`

Helm permite parametrizar todos os recursos Kubernetes em um único pacote versionado. O chart inclui Deployment, StatefulSet (Postgres), HPA, PDB, Ingress, Secrets, RBAC e CronJob — tudo configurável via `values.yaml`.

**Descartado:**
- **Manifests YAML puros:** sem parametrização, difícil de manter em múltiplos environments.
- **Kustomize:** boa opção, mas Helm é mais adequado quando há muita parametrização e o chart pode ser publicado em um registry.

---

## CD: ArgoCD

**Escolha:** ArgoCD com `syncPolicy.automated`

O ArgoCD roda dentro do próprio cluster e observa o repositório Git. Quando o CI atualiza a tag da imagem no `values.yaml` e faz push, o ArgoCD detecta a divergência e aplica o chart automaticamente — sem que o GitHub Actions precise de acesso ao cluster. Isso é especialmente importante no ambiente local, onde o cluster não é acessível externamente.

`prune: true` remove recursos que saíram do chart. `selfHeal: true` reverte mudanças manuais no cluster, garantindo que o repositório é sempre a fonte da verdade.

**Descartado:**
- **`helm upgrade` no CI:** o runner do GitHub Actions não tem como alcançar um cluster kind local. Funcionaria em cloud, mas não aqui.
- **Flux:** alternativa GitOps equivalente ao ArgoCD. A escolha pelo ArgoCD foi pela UI que facilita a demonstração ao vivo e pela familiaridade.
- **Watchtower:** faz rolling update de containers Docker, não é adequado para Kubernetes.

---

## CI: GitHub Actions + GHCR

**Escolha:** GitHub Actions para build e push; GHCR como registry

GitHub Actions é nativo ao repositório, sem configuração adicional de infraestrutura. O GHCR (GitHub Container Registry) aceita autenticação via `GITHUB_TOKEN` sem segredos extras. A tag da imagem usa o SHA curto do commit, garantindo rastreabilidade direta entre imagem e código.

O CI atualiza a tag no `values.yaml` e faz push com `[skip ci]` para evitar loop. O ArgoCD detecta essa mudança e fecha o loop de CD.

---

## PostgreSQL: StatefulSet com PVC

**Escolha:** StatefulSet com `volumeClaimTemplates`

StatefulSet garante identidade estável ao pod e gerencia o PVC automaticamente. `terminationGracePeriodSeconds: 60` evita corrupção de dados ao garantir que o processo anterior terminou antes de o novo subir.

**Descartado:**
- **Deployment com PVC externo:** Deployment não garante que apenas um pod acessa o volume por vez.
- **Operator PostgreSQL (CloudNativePG, CrunchyData):** adiciona complexidade desnecessária para o escopo do desafio. Vale mencionar como evolução natural para produção.

---

## Limitações conhecidas

- **PostgreSQL sem réplica:** ponto único de falha no banco. Em produção, usar um operator com suporte a replicação.
- **Secrets no `values.yaml`:** as credenciais estão em texto no repositório. Em produção, usar External Secrets Operator com um vault externo ou `values-secret.yaml` ignorado pelo git.
- **Cluster local:** o ambiente kind não é acessível externamente, o que limita o CD a pull-based (ArgoCD). Em cloud, o CI poderia fazer push direto via `helm upgrade`.
