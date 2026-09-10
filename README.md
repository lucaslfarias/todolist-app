# TodoList

Aplicação web de lista de tarefas rodando em Kubernetes local.

![Tela principal](assets/todolist.png)

## Índice

- [Stack](#stack)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Execução — do zero ao browser](#execução--do-zero-ao-browser)
- [Variáveis de ambiente](#variáveis-de-ambiente)
- [Endpoints](#endpoints)
- [Operação](#operação)
- [Executando localmente (sem Kubernetes)](#executando-localmente-sem-kubernetes)

---

## Stack

**Aplicação:** Python 3.11 · Flask · SQLAlchemy · gunicorn  
**Banco:** PostgreSQL 16  
**Kubernetes:** kind · NGINX Ingress Controller  
**Infraestrutura:** Terraform  
**CD:** ArgoCD  
**CI:** GitHub Actions · GHCR

---

## Estrutura do repositório

```
.
├── app.py                        # aplicação Flask
├── Dockerfile
├── requirements.txt
├── todolist-chart/               # Helm chart da aplicação
│   ├── values.yaml
│   └── templates/
├── infra/
│   ├── argocd/
│   │   └── application.yaml      # Application do ArgoCD
│   ├── modules/kind-cluster/     # módulo Terraform reutilizável
│   └── envs/local/               # entry point — terraform apply aqui
└── scripts/
    └── smoke-test.sh
```

---

## Execução — do zero ao browser

### Pré-requisitos

| Ferramenta | Versão mínima |
|---|---|
| Docker | 24+ |
| kind | 0.22+ |
| Terraform | 1.6+ |
| kubectl | qualquer recente |

### 1. Clone o repositório

```bash
git clone https://github.com/lucaslfarias/todolist-app
cd todolist-app
```

### 2. Inicialize o Terraform

```bash
cd infra/envs/local
terraform init
```

Esse passo baixa os providers (`tehcyx/kind`, `hashicorp/helm`, `gavinbunney/kubectl`).

### 3. Suba o cluster e a infraestrutura

```bash
terraform apply
```

O `apply` executa em ordem:

1. Cria o cluster kind (1 control-plane + 2 workers)
2. Instala o NGINX Ingress Controller via Helm
3. Instala o ArgoCD via Helm
4. Registra o `Application` do ArgoCD apontando para este repositório

Tempo médio: **5–8 minutos** (download de imagens incluso).

### 4. Configure o kubectl

```bash
export KUBECONFIG=$(terraform output -raw kubeconfig_path)
```

### 5. Aguarde o ArgoCD sincronizar

```bash
kubectl get pods -n todolist -w
```

O ArgoCD detecta o repositório, aplica o Helm chart e sobe a aplicação automaticamente. Aguarde todos os pods ficarem `Running`.

### 6. Acesse a aplicação

```
http://localhost:8080
```

Credenciais padrão: `admin` / `admin`

### 7. (Opcional) Smoke test

```bash
cd ../../..
bash scripts/smoke-test.sh
```

### Destruir o ambiente

```bash
cd infra/envs/local
terraform destroy
```

---

## Variáveis de ambiente

### Aplicação

| Variável | Padrão | Descrição |
|---|---|---|
| `APP_NAME` | `TodoList` | Título exibido na interface |
| `APP_PORT` | `5000` | Porta do servidor |
| `APP_COLOR` | *(cinza)* | Cor do tema (`purple`, `green`, `blue`, `cyan`, `pink`, `red`, `orange`, `brown`, `yellow`) |
| `SESSION_KEY` | `dev-only-insecure-key` | Assina os cookies de sessão |
| `ADMIN_USER` | `admin` | Usuário de login |
| `ADMIN_PASSWORD` | `admin` | Senha de login |
| `CLEANUP_TOKEN` | *(vazio)* | Token exigido pelo endpoint `POST /cleanup` |

### Banco de dados

| Variável | Padrão | Descrição |
|---|---|---|
| `DB_HOST` | `localhost` | Host do PostgreSQL |
| `DB_PORT` | `5432` | Porta |
| `DB_NAME` | `todolist` | Nome do banco |
| `DB_USER` | `todolist` | Usuário |
| `DB_PASSWORD` | *(vazio)* | Senha |

O schema é criado pela aplicação na inicialização. O banco precisa existir antes da app subir.

### Credenciais em arquivo

A aplicação procura credenciais em `SECRETS_DIR` (padrão: `/var/run/secrets/todolist`) antes de ler a variável de ambiente. No Kubernetes, os Secrets são montados nesse diretório.

Variáveis que aceitam arquivo: `DB_USER`, `DB_PASSWORD`, `SESSION_KEY`, `ADMIN_USER`, `ADMIN_PASSWORD`, `CLEANUP_TOKEN`.

---

## Endpoints

| Endpoint | Método | Autenticação | Descrição |
|---|---|---|---|
| `/` | GET | Sessão | Lista de tarefas |
| `/login` | GET, POST | — | Formulário de login |
| `/logout` | GET | Sessão | Encerra a sessão |
| `/add` | POST | Sessão | Cria uma tarefa |
| `/toggle/<id>` | POST | Sessão | Alterna entre feita e pendente |
| `/delete/<id>` | POST | Sessão | Remove uma tarefa |
| `/healthz` | GET | — | Health check (verifica conexão com o banco) |
| `/cleanup` | POST | `X-Cleanup-Token` | Remove tarefas concluídas |
| `/pods` | GET | Sessão | Lista pods do namespace |
| `/cleanup/status` | GET, POST | Sessão | Histórico de limpezas; POST pausa/retoma o CronJob |

---

## Operação

### Fluxo de deploy

```
git push → GitHub Actions (build + push GHCR + atualiza tag no values.yaml)
                                          ↓
                              ArgoCD detecta mudança no repositório
                                          ↓
                              helm upgrade automático no cluster
```

### Limpeza de tarefas concluídas

Um CronJob executa a cada 5 minutos chamando `POST /cleanup` com o token configurado. O histórico de execuções e o controle de pausa/retomada ficam em `/cleanup/status`.

### Escalabilidade

O HPA escala a aplicação entre 2 e 5 réplicas com base em CPU (70%).

A métrica de memória fica desabilitada (`app.hpa.targetMemory: null`) de propósito: o HPA usa o maior número de réplicas entre todas as métricas, e memória de processo Python raramente é devolvida ao SO. Uma métrica presa acima do alvo impediria o scale-down para sempre.

O PodDisruptionBudget da aplicação permite no máximo 1 pod indisponível por vez durante manutenções. O PDB do Postgres vem desabilitado, porque o StatefulSet roda com uma réplica só e um budget sobre um único pod travaria o `kubectl drain`.

### Acessar a UI do ArgoCD

```bash
kubectl port-forward svc/argocd-server -n argocd 8888:80
```

Acesse `http://localhost:8888`. Usuário: `admin`. Senha:

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d
```

### Evidências de execução

O ambiente fica no ar sob meu controle e as evidências são demonstradas ao vivo na apresentação: `terraform apply` do zero, ArgoCD `Synced/Healthy`, o HPA reagindo a carga, um rollout sem downtime e a aplicação no browser.

---

## Executando localmente (sem Kubernetes)

Requer Python 3.11 e PostgreSQL acessível.

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

export DB_HOST=localhost DB_PORT=5432 DB_NAME=todolist DB_USER=todolist DB_PASSWORD=sua-senha
export SESSION_KEY=chave-local ADMIN_USER=admin ADMIN_PASSWORD=admin CLEANUP_TOKEN=token-local

gunicorn --bind 0.0.0.0:5000 app:app
```

Disponível em `http://localhost:5000`. Funcionalidades que dependem de Kubernetes (`/pods`, `/cleanup/status`) não funcionam fora do cluster.
