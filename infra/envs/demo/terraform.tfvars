# Ambiente de demonstracao — descartavel.
#
# ATENCAO: as portas abaixo NAO podem colidir com o env local (8080/8443).
# Os dois clusters ficam de pe ao mesmo tempo enquanto o local sobe.

cluster_name       = "demo-cluster"
kubernetes_version = "kindest/node:v1.30.0"
worker_count       = 1

control_plane_host_port       = 9080
control_plane_host_port_https = 9443

app_image_tag = "be07be5"
app_color     = "blue"
