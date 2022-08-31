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

### PRIVATE SUBNET ###
resource "yandex_vpc_subnet" "private" {
  name           = "private"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.vpc_netology.id}"
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.nat_rt.id
  depends_on = [
    yandex_vpc_network.vpc_netology, yandex_vpc_route_table.nat_rt,
  ]
}

### ROUTE TABLE FOR PRIVATE SUBNET ###
resource "yandex_vpc_route_table" "nat_rt" {
  name = "nat_rt"
  network_id = "${yandex_vpc_network.vpc_netology.id}"
  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "192.168.10.254"
  }
  depends_on = [
    yandex_vpc_network.vpc_netology
  ]
}

