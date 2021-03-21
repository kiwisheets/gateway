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

resource "vault_generic_secret" "apollo" {
  path = "secret/apollo"

  data_json = jsonencode({
    key = var.apollo_key
  })
}

resource "vault_policy" "gateway" {
  name = "gateway"

  policy = <<EOT
path "secret/jwt-public" {
  capabilities = ["read"]
}
path "secret/data/jwt-public" {
  capabilities = ["read"]
}
path "secret/apollo" {
  capabilities = ["read"]
}
path "secret/data/apollo" {
  capabilities = ["read"]
}
EOT
}

resource "consul_intention" "gql_server" {
  source_name      = "gateway"
  destination_name = "gql-server"
  action           = "allow"
}

resource "consul_intention" "invoicing" {
  source_name      = "gateway"
  destination_name = "invoicing"
  action           = "allow"
}

resource "nomad_job" "gateway" {
  jobspec = templatefile("${path.module}/jobs/gateway.hcl", {
    datacenter            = var.datacenter
    image_tag             = var.image_tag
    allowed_origin        = var.allowed_origin
    allowed_origin_regexp = var.allowed_origin_regexp
    instance_count        = var.instance_count
    host                  = var.host
    apollo_graph_variant  = var.apollo_graph_variant
  })
  detach = false
}
