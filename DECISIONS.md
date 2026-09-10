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

---

## Desafios encontrados

Problemas reais enfrentados durante o desafio e como foram resolvidos.

### HPA sempre em `<unknown>`

O kind não inclui metrics-server. Sem ele o HPA reporta `TARGETS <unknown>` indefinidamente, emite `FailedGetResourceMetric` e nunca escala. A instalação foi para o Terraform (`infra/envs/local/metrics-server.tf`), com duas flags obrigatórias no kind: `--kubelet-insecure-tls`, porque o kubelet serve métricas com certificado auto-assinado fora da CA do cluster, e `--kubelet-preferred-address-types=InternalIP,...`, porque o padrão tenta `Hostname` primeiro e o hostname do nó não resolve dentro da rede de pods.

### O HPA não reagia à carga mesmo com métricas funcionando

O `CMD` da imagem não passa `--workers`, então o gunicorn subia com 1 worker sync: uma requisição por vez por pod. Nesse regime o pod satura em latência muito antes de a CPU média indicar carga, e o sinal do HPA fica inútil. Resolvido com `WEB_CONCURRENCY`, lido pelo próprio gunicorn, sem alterar a imagem da aplicação.

### `helm upgrade` sobrescrevendo a decisão do autoscaler

Com `spec.replicas` renderizado no manifesto, cada sync do ArgoCD com `selfHeal` reescrevia o valor do `values.yaml` por cima do número de réplicas escolhido pelo HPA. O campo passou a ser omitido quando o HPA está ligado, e o `Application` do ArgoCD ignora diferenças em `/spec/replicas` geradas pelo `kube-controller-manager`.

### 502 durante scale-down e rollout

Quando um pod entra em `Terminating`, o gunicorn começa a fechar conexões antes de o endpoint sair das tabelas do kube-proxy e do ingress-nginx. Foram necessárias duas mudanças: um hook `preStop` segurando o container por alguns segundos e `maxUnavailable: 0` na estratégia de rollout, para a atualização nunca reduzir a capacidade abaixo do número atual de réplicas e não conflitar com o PDB.

### PDB de réplica única travando o drain

Um PDB com `minAvailable: 1` sobre o StatefulSet de uma réplica do Postgres equivale a proibir toda disrupção voluntária: o `kubectl drain` fica preso indefinidamente. O PDB do banco vem desabilitado por padrão, assumindo o downtime durante manutenção de nó. Faz sentido reativar apenas com replicação real.

### Pods mortos durante o scale-up

Um pod criado pelo HPA em nó carregado podia ser morto pela `livenessProbe` antes de terminar de subir, gerando um ciclo de criar e matar. Uma `startupProbe` suspende a liveness durante a inicialização e resolve o caso.

### PDB sem distribuição entre nós não protege nada

Com todas as réplicas no mesmo worker, drenar esse nó derruba tudo de uma vez, independentemente do budget. Foram adicionados `topologySpreadConstraints` com `whenUnsatisfiable: ScheduleAnyway` — `DoNotSchedule` deixaria pods `Pending` e travaria o scale-up do HPA.

### CRDs do ArgoCD no Terraform

O provider `hashicorp/kubernetes` não aplica recursos de CRDs que ainda não existem no momento do plan. O `Application` do ArgoCD é aplicado com `gavinbunney/kubectl`, que trabalha com YAML bruto e não precisa do schema no plan.
