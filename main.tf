resource "elestio_opensearch" "nodes" {
  for_each = { for i, value in var.nodes : value.server_name => merge(value, { index = i }) }

  project_id       = var.project_id
  version          = var.opensearch_version
  default_password = var.opensearch_pass
  server_name      = each.value.server_name
  provider_name    = each.value.provider_name
  datacenter       = each.value.datacenter
  server_type      = each.value.server_type
  // Merge the module configuration_ssh_key with the optional ssh_public_keys attribute
  ssh_public_keys = concat(each.value.ssh_public_keys, [{
    username = var.configuration_ssh_key.username
    key_data = var.configuration_ssh_key.public_key
  }])

  // Optional attributes
  admin_email                                       = each.value.admin_email
  alerts_enabled                                    = each.value.alerts_enabled
  app_auto_updates_enabled                          = each.value.app_auto_update_enabled
  backups_enabled                                   = each.value.backups_enabled
  firewall_enabled                                  = each.value.firewall_enabled
  keep_backups_on_delete_enabled                    = each.value.keep_backups_on_delete_enabled
  remote_backups_enabled                            = each.value.remote_backups_enabled
  support_level                                     = each.value.support_level
  system_auto_updates_security_patches_only_enabled = each.value.system_auto_updates_security_patches_only_enabled

  connection {
    type        = "ssh"
    host        = self.ipv4
    private_key = var.configuration_ssh_key.private_key
  }

  provisioner "file" {
    destination = "/opt/app/setup-node.sh"
    content = templatefile("${path.module}/scripts/setup-node.sh.tftpl", {
      manager_server_name = var.nodes[0].server_name
      server_name         = self.server_name
      global_ip           = self.global_ip
      cname               = self.cname
      index               = each.value.index
    })
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt/app",
      "sh setup-node.sh"
    ]
  }
}

resource "null_resource" "update_nodes_env" {
  for_each = { for node in elestio_opensearch.nodes : node.server_name => node }

  triggers = {
    cluster_nodes_global_ips = join(",", [for n in elestio_opensearch.nodes : n.global_ip])
  }

  connection {
    type        = "ssh"
    host        = each.value.ipv4
    private_key = var.configuration_ssh_key.private_key
  }

  provisioner "file" {
    destination = "/opt/app/update-node.sh"
    content = templatefile("${path.module}/scripts/update-node.sh.tftpl", {
      global_ips = [for n in elestio_opensearch.nodes : n.global_ip]
    })
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt/app",
      "sh update-node.sh"
    ]
  }
}
