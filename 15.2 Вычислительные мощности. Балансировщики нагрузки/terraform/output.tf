
output "vm_ids" {
  value = [ for vm in yandex_compute_instance_group.vm-group.instances : vm.instance_id ]
}

output "network_load_balancer" {
  value = [ for vm in yandex_lb_network_load_balancer.netology_nlb.listener : tolist(vm.external_address_spec)[0].address ][0]
}

output "application_load_balancer" {
  value = yandex_alb_load_balancer.alb-balancer.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}