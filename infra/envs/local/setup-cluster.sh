#!/usr/bin/env bash
set -euo pipefail
 
REGISTRY_NAME="kind-registry"
REGISTRY_PORT="5001"
CLUSTER_NAME="devops-challenge"
 
# ── 1. Registry local ────────────────────────────────────────────────
if [ "$(docker inspect -f '{{.State.Running}}' "${REGISTRY_NAME}" 2>/dev/null)" != "true" ]; then
  echo "-> Criando registry local..."
  docker run -d \
    --restart=always \
    --name "${REGISTRY_NAME}" \
    -p "127.0.0.1:${REGISTRY_PORT}:5000" \
    registry:2
else
  echo "-> Registry ja esta rodando."
fi
 
# ── 2. Cluster kind ──────────────────────────────────────────────────
if ! kind get clusters | grep -q "${CLUSTER_NAME}"; then
  echo "-> Criando cluster kind..."
  cat <<EOF | kind create cluster --name "${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
  - |-
    [plugins."io.containerd.grpc.v1.cri".registry]
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${REGISTRY_PORT}"]
          endpoint = ["http://${REGISTRY_NAME}:5000"]
EOF
else
  echo "-> Cluster ja existe."
fi
 
# ── 3. registry - kind ───────────────────────────────
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${REGISTRY_NAME}")" = 'null' ]; then
  echo "-> Conectando registry a rede kind..."
  docker network connect kind "${REGISTRY_NAME}"
fi
 
# ── 4. ConfigMap ───────────────
echo "-> Aplicando ConfigMap do registry..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${REGISTRY_PORT}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
 
echo ""
echo "✅ Cluster '${CLUSTER_NAME}' + registry em localhost:${REGISTRY_PORT} prontos."
