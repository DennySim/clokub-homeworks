output "internal_ip_address_node01_public" {
  value = "${yandex_compute_instance.node01-public.network_interface.0.ip_address}"
}
output "external_ip_address_node01_public" {
  value = "${yandex_compute_instance.node01-public.network_interface.0.nat_ip_address}"
}

output "internal_ip_address_node02_private" {
  value = "${yandex_compute_instance.node02-private.network_interface.0.ip_address}"
}

output "internal_ip_address_nat_instance" {
  value = "${yandex_compute_instance.nat-instance.network_interface.0.ip_address}"
}

output "external_ip_address_nat_instance" {
  value = "${yandex_compute_instance.nat-instance.network_interface.0.nat_ip_address}"
}
output "private_subnet_id" {
  value = "${yandex_vpc_subnet.private.id}"
}