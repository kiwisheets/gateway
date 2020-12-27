job "gateway" {
  datacenters = ["${datacenter}"]

  group "gateway" {
    count = ${instance_count}

    task "gateway" {
      driver = "docker"

      config {
        image = "kiwisheets/gateway:${image_tag}"

        volumes = [
          "secrets/jwt-public-key.secret:/run/secrets/jwt-public-key.secret",
          "secrets/apollo-key.secret:/run/secrets/apollo-key.secret"
        ]
      }

      env {
        ALLOWED_ORIGIN = "${allowed_origin}"
        PORT = 4000
        ENVIRONMENT = "production"
        JWT_EC_PUBLIC_KEY_FILE = "/run/secrets/jwt-public-key.secret"
        APOLLO_KEY_FILE="/run/secrets/apollo-key.secret"
        APOLLO_GRAPH_VARIANT="prod"
      }

      template {
        data = <<EOF
{{with secret "secret/data/jwt-public"}}{{.Data.data.key}}{{end}}
        EOF
        destination = "secrets/jwt-public-key.secret"
        change_mode = "restart"
      }

      template {
        data = <<EOF
{{with secret "secret/data/apollo"}}{{.Data.data.key}}{{end}}
        EOF
        destination = "secrets/apollo-key.secret"
        change_mode = "restart"
      }

      vault {
        policies = ["gateway"]
      }

      resources {
        cpu    = 64
        memory = 128
      }
    }

    network {
      mode = "bridge"
      port "health" {}
      dns {
        servers = [
          "1.1.1.1",
          "1.0.0.1"
        ]
      }
    }

    service {
      name = "gateway"
      port = 4000

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "gql-server"
              local_bind_port  = 5000
            }
            upstreams {
              destination_name = "invoicing"
              local_bind_port  = 5001
            }
            expose {
              path {
                path           = "/health"
                protocol        = "http"
                local_path_port = 4000
                listener_port   = "health"
              }
            }
          }
        }

        sidecar_task {
          resources {
            cpu    = 20
            memory = 32
          }
        }
      }

      check {
        type     = "http"
        path     = "/health"
        port     = "health"
        interval = "2s"
        timeout  = "2s"
      }
    }
  }
}
