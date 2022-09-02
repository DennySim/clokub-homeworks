##### CREATE MYSQL CLUSTER #####

resource "yandex_mdb_mysql_cluster" "mysql-cluster" {
  name        = "mysql-cluster"
  environment = "PRESTABLE"
  network_id  = yandex_vpc_network.vpc_netology.id
  version     = "8.0"
  deletion_protection = true
  
  resources {
    resource_preset_id = "b1.medium"  # Intel Broadwell с производительностью 50% CPU
    disk_type_id       = "network-ssd"
    disk_size          = 20
  }

  maintenance_window {    # произвольное время технического обслуживания
    type = "ANYTIME"
  }

  backup_window_start { # начала резервного копирования
    hours = 23
    minutes = 59
  }
  dynamic "host" {
    for_each = var.avail_zones
    content {
      assign_public_ip = true
      zone      = "ru-central1-${host.value}"
      subnet_id = yandex_vpc_subnet.private_subnets["${host.key}"].id
    }
  }

  depends_on = [ yandex_vpc_subnet.private_subnets ]
}

##### CREATE DATABASE netology_db #####

resource "yandex_mdb_mysql_database" "netology_db" {
  cluster_id = yandex_mdb_mysql_cluster.mysql-cluster.id
  name       = "netology_db"
  depends_on = [
    yandex_mdb_mysql_cluster.mysql-cluster,
  ]
}

##### CREATE USER=netology_db, PASSWORD=netology_db #####

resource "yandex_mdb_mysql_user" "netology_db" {
    cluster_id = yandex_mdb_mysql_cluster.mysql-cluster.id
    name       = "netology_db"
    password   = "netology_db"

    permission {
      database_name = yandex_mdb_mysql_database.netology_db.name
      roles         = ["ALL"]
    }

  depends_on = [
    yandex_mdb_mysql_cluster.mysql-cluster,
  ]
}