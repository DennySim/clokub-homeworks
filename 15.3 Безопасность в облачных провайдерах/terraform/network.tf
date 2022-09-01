### VPC ###
resource "yandex_vpc_network" "vpc_netology" {
  name = "vpc-netology"
}

### PUBLIC SUBNET ###
resource "yandex_vpc_subnet" "public" {
  name           = "public"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.vpc_netology.id}"
  v4_cidr_blocks = ["192.168.10.0/24"]
    depends_on = [
    yandex_vpc_network.vpc_netology,
  ]
}