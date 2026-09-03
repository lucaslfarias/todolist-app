# Ajuste conforme necessidade local

cluster_name       = "local-cluster"
kubernetes_version = "kindest/node:v1.30.0"
worker_count       = 2

# Portas acessíveis no seu host (máquina física / WSL2 / VM)
# Certifique-se de que não estejam em uso antes do apply
control_plane_host_port       = 8080
control_plane_host_port_https = 8443
