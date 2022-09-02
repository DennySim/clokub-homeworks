variable "PMA_HOST" {
  default = "rc1a-zsn8pusxthylgqfm.mdb.yandexcloud.net"
  description = "MySQL HOST"
}

resource "kubernetes_deployment" "example" {
  metadata {
    name = "terraform-example"
    labels = {
      app = "MyApp"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "MyApp"
      }
    }

    template {
      metadata {
        labels = {
          app = "MyApp"
        }
      }

      spec {
        container {
          image = "phpmyadmin"
          name  = "phpmyadmin"
          env {
            name = "PMA_HOST"  
            value = var.PMA_HOST
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "example" {
  metadata {
    name = "example"
  }
  spec {
    selector = {
      app = "MyApp"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }

}