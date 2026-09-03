terraform {
  required_version = ">= 1.6"

  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.4"
    }
  }
}

# O provider kind não precisa de credenciais —
# ele fala diretamente com o Docker daemon local.
provider "kind" {}
