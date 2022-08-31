##### GET SERVICEACCOUNT ID #####
locals {
  key = sensitive(jsondecode(file("${path.module}/key.json")))
}


##### CREATE BUCKET #####

resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
  folder_id = var.yandex_folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${local.key.service_account_id}"
}

resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = "${local.key.service_account_id}"
  description        = "static access key for object storage"
}

resource "yandex_storage_bucket" "netology" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = "netology.bucket"
  acl    = "public-read"
}

##### PUT PICTURE INTO BUCKET #####
resource "yandex_storage_object" "devops_pic" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = "netology.bucket"
  key    = "devops"
  source = "../images/devops.png"
  depends_on = [
    yandex_storage_bucket.netology
  ]
}


##### CREATE VM INSTANCE GROUP #####

resource "yandex_compute_instance_group" "vm-group" {
  name                = "test-ig"
  folder_id           = var.yandex_folder_id
  service_account_id  = "${local.key.service_account_id}"
  # deletion_protection = true
  instance_template {
    platform_id = "standard-v1"
    resources {
      memory = 2
      cores  = 2
    }
    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = "fd827b91d99psvq5fjit"
        size     = 4
      }
    }
    network_interface {
      network_id = "${yandex_vpc_network.vpc_netology.id}"
      subnet_ids = ["${yandex_vpc_subnet.public.id}"]
    }
    metadata = {
      ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
      user-data = "${file("../meta.yml")}"
    }
    network_settings {
      type = "STANDARD"
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = ["ru-central1-a"]
  }

  deploy_policy {
    max_unavailable = 1
    max_creating    = 3
    max_expansion   = 3
    max_deleting    = 1
  }

  health_check {
      http_options {
        port = 80
        path = "/"
      }
    }
}


##### CREATE NLB #####

resource "yandex_lb_target_group" "netology_tg" {
  name      = "netology-tg"
  region_id = "ru-central1"

  dynamic "target" {
    for_each = yandex_compute_instance_group.vm-group.instances
    content {
      subnet_id = "${yandex_vpc_subnet.public.id}"
      address   = "${target.value["network_interface"]["0"]["ip_address"]}"
    }
  }
}


resource "yandex_lb_network_load_balancer" "netology_nlb" {
  name = "netology-nlb"

  listener {
    name = "netology-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = "${yandex_lb_target_group.netology_tg.id}"

    healthcheck {
      name = "http"
      http_options {
        port = 80
       path = "/"
      }
    }
  }
}

##### CREATE ALB #####

resource "yandex_alb_target_group" "netology_alb" {

  dynamic "target" {
    for_each = yandex_compute_instance_group.vm-group.instances
    content {
      subnet_id = "${yandex_vpc_subnet.public.id}"
      ip_address   = "${target.value["network_interface"]["0"]["ip_address"]}"
    }
  }
}

resource "yandex_alb_backend_group" "netology-bg" {
  name      = "netology-backend-group"

  http_backend {
    name = "netology-http-backend"
    weight = 1
    port = 80
    target_group_ids = ["${yandex_alb_target_group.netology_alb.id}"]
    #tls {
    #  sni = "backend-domain.internal"
    #}
    load_balancing_config {
      panic_threshold = 50
    }    
    healthcheck {
      timeout = "1s"
      interval = "1s"
      http_healthcheck {
        path  = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "netology-router" {
  name      = "netology-http-router"
}

resource "yandex_alb_virtual_host" "netology-virtual-host" {
  name      = "netology-virtual-host"
  http_router_id = yandex_alb_http_router.netology-router.id
  route {
    name = "netology-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.netology-bg.id
        timeout = "3s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "alb-balancer" {
  name        = "netology-alb"

  network_id  = yandex_vpc_network.vpc_netology.id

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public.id 
    }
  }

  listener {
    name = "netology-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }    
    http {
      handler {
        http_router_id = yandex_alb_http_router.netology-router.id
      }
    }
  }    
}