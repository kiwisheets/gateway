terraform {
  backend "remote" {
    organization = "KiwiSheets"

    workspaces {
      name = "KiwiSheets-Gateway-Dev"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "nomad" {}

provider "consul" {
  datacenter = var.datacenter
}

provider "vault" {}

resource "vault_policy" "gateway" {
  name = "gateway"

  policy = <<EOT
path "secret/gql-server" {
  capabilities = ["read"]
}
path "secret/data/gql-server" {
  capabilities = ["read"]
}
EOT
}

resource "nomad_job" "gateway" {
  jobspec = templatefile("${path.module}/jobs/gateway.hcl", {
    datacenter     = var.datacenter
    image_tag      = var.image_tag
    allowed_origin = var.allowed_origin
    instance_count = var.instance_count
    host           = var.host
  })
  detach = false
}
