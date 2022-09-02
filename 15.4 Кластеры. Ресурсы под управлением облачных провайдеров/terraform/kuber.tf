##### CREATE SERVICEACCOUNT #####
resource "yandex_iam_service_account" "sa" {
  name        = "netology-kuber-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "sa" {
  folder_id = var.yandex_folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = "${yandex_iam_service_account.sa.id}"
}

##### CREATE CLUSTER KUBERNETES #####

resource "yandex_kubernetes_cluster" "netology_regional_cluster" {
  name        = "netology-kuber"

  network_id = "${yandex_vpc_network.vpc_netology.id}"

  master {
    regional {
      region = "ru-central1"

      dynamic "location" {
        for_each = yandex_vpc_subnet.public_subnets
        content {
          zone = yandex_vpc_subnet.private_subnets["${location.key}"].zone
          subnet_id = yandex_vpc_subnet.private_subnets["${location.key}"].id
        }
      }
    }

    version   = "1.21"
    public_ip = true

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        day        = "monday"
        start_time = "15:00"
        duration   = "3h"
      }
    }
  }

  service_account_id      = "${yandex_iam_service_account.sa.id}"
  node_service_account_id = "${yandex_iam_service_account.sa.id}"

  release_channel = "STABLE"

  depends_on = [
    yandex_vpc_subnet.public_subnets,
    yandex_resourcemanager_folder_iam_member.sa,
  ]
}

resource "yandex_kubernetes_node_group" "netology-node-group" {
  cluster_id = yandex_kubernetes_cluster.netology_regional_cluster.id
  
  instance_template {

    platform_id = "standard-v1"
    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    network_interface {
      nat = true
      subnet_ids = [ for subnet in yandex_vpc_subnet.public_subnets : subnet.id ]
    }
    metadata = {
      ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"

    }
  
  }

  allocation_policy {

    dynamic "location" {
      for_each = var.avail_zones
      content {
        zone      = "ru-central1-${location.value}"
      }
    }
  } 

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  depends_on = [
    yandex_kubernetes_cluster.netology_regional_cluster,
  ]
}