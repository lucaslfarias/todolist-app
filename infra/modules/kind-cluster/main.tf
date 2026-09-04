terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.4"
    }
  }
}

# ─────────────────────────────────────────────
# Cluster kind
# ─────────────────────────────────────────────
resource "kind_cluster" "this" {
  name            = var.cluster_name
  node_image      = var.kubernetes_version
  wait_for_ready  = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    # ── Control-plane ──────────────────────────
    node {
      role = "control-plane"

      kubeadm_config_patches = [
        <<-YAML
          kind: InitConfiguration
          nodeRegistration:
            kubeletExtraArgs:
              node-labels: "ingress-ready=true"
        YAML
      ]

      extra_port_mappings {
        container_port = 80
        host_port      = var.control_plane_host_port
        listen_address = "0.0.0.0"
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 443
        host_port      = var.control_plane_host_port_https
        listen_address = "0.0.0.0"
        protocol       = "TCP"
      }
    }

    # ── Workers ────────────────────────────────
    dynamic "node" {
      for_each = range(var.worker_count)
      content {
        role = "worker"
      }
    }
  }
}
