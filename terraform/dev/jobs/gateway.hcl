job "gateway" {
  datacenters = ["${datacenter}"]

  group "gateway" {
    count = ${instance_count}

    task "gateway" {
      driver = "docker"

      config {
        image = "kiwisheets/gateway:${image_tag}"

        volumes = [
          "secrets/jwt-public-key.secret:/run/secrets/jwt-public-key.secret"
        ]
      }

      env {
        ALLOWED_ORIGIN = "${allowed_origin}"
        PORT = 4000
        ENVIRONMENT = "production"
        JWT_EC_PUBLIC_KEY_FILE = "/run/secrets/jwt-public-key.secret"
        USER_SERVICE_ADDR = "http://$${NOMAD_UPSTREAM_ADDR_gql-server}/graphql"
      }

      template {
        data = <<EOF
{{with secret "secret/data/jwt-public"}}{{.Data.data.key}}{{end}}
        EOF
        destination = "secrets/jwt-public-key.secret"
        change_mode = "restart"
      }

      vault {
        policies = ["gateway"]
      }

      resources {
        cpu    = 128
        memory = 256
      }
    }

    network {
      mode = "bridge"
      port "http" {
        to = "4000"
      }
    }

    service {
      name = "gateway"
      port = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.gateway.rule=Host(`${host}`) && PathPrefix(`/graphql`)",
      ]

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "gql-server"
              local_bind_port = 5000
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
        interval = "2s"
        timeout  = "2s"
      }
    }
  }
}
