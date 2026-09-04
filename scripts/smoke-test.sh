#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="todolist"
SERVICE="todolist"
LOCAL_PORT="8081"
SERVICE_PORT="80"
HEALTH_ENDPOINT="/healthz"
TIMEOUT=60

echo "═══════════════════════════════════════════"
echo "  Smoke Test — Todolist App"
echo "═══════════════════════════════════════════"

# ── 1. Verifica se os pods estão Running ─────────────────────────────
echo ""
echo "→ Verificando pods..."
READY=$(kubectl get deployment ${SERVICE} -n ${NAMESPACE} \
  -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")

if [ "${READY}" = "0" ] || [ -z "${READY}" ]; then
  echo "❌ Nenhum pod Ready no deployment ${SERVICE}"
  exit 1
fi
echo "✅ ${READY} pod(s) Ready"

# ── 2. Inicia port-forward em background ─────────────────────────────
echo ""
echo "→ Iniciando port-forward..."
kubectl port-forward svc/${SERVICE} -n ${NAMESPACE} \
  ${LOCAL_PORT}:${SERVICE_PORT} &>/dev/null &
PF_PID=$!

# Garante que o port-forward é encerrado ao sair
trap "kill ${PF_PID} 2>/dev/null" EXIT

# Aguarda o port-forward estar pronto
sleep 3

# ── 3. Testa o /healthz ──────────────────────────────────────────────
echo ""
echo "→ Testando endpoint ${HEALTH_ENDPOINT}..."

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  --max-time 10 \
  http://localhost:${LOCAL_PORT}${HEALTH_ENDPOINT} || echo "000")

if [ "${HTTP_CODE}" = "200" ]; then
  echo "✅ /healthz retornou 200 OK"
else
  echo "❌ /healthz retornou ${HTTP_CODE} (esperado 200)"
  exit 1
fi

# ── 4. Testa a página principal ──────────────────────────────────────
echo ""
echo "→ Testando página principal..."

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  --max-time 10 \
  http://localhost:${LOCAL_PORT}/ || echo "000")

if [ "${HTTP_CODE}" = "200" ]; then
  echo "✅ / retornou 200 OK"
else
  echo "⚠️  / retornou ${HTTP_CODE}"
fi

# ── 5. Verifica conectividade com o Postgres ─────────────────────────
echo ""
echo "→ Verificando Postgres..."
PG_READY=$(kubectl get statefulset todolist-postgres -n ${NAMESPACE} \
  -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")

if [ "${PG_READY}" = "1" ]; then
  echo "✅ Postgres Ready"
else
  echo "❌ Postgres não está Ready"
  exit 1
fi

# ── Resultado ────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════"
echo "  ✅ Smoke test passou!"
echo "  App:      http://localhost:${LOCAL_PORT}"
echo "  Health:   http://localhost:${LOCAL_PORT}${HEALTH_ENDPOINT}"
echo "═══════════════════════════════════════════"
