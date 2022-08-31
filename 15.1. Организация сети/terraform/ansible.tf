resource "null_resource" "cluster" {
  provisioner "local-exec" {
    command = "ANSIBLE_FORCE_COLOR=1 ansible-playbook -i ../inventory/hosts.yml ../site.yml"
  }

  depends_on = [
    local_file.inventory
  ]
}
