variable "datacenter" {
  type = string
}

variable "hcloud_token" {
  type        = string
  description = "Hetzner Cloud API Token"
}

variable "image_tag" {
  type        = string
  description = "image version"
}

variable "instance_count" {
  type        = number
  description = "number of server instances to launch"
}

variable "allowed_origin" {
  type        = string
  description = "the allowed origin for CORS"
}

variable "host" {
  type        = string
  description = "API host"
}

variable "apollo_key" {
  type        = string
  description = "Apollo Key"
}

variable "apollo_graph_variant" {
  type        = string
  description = "Apollo Graph Variant"
}
