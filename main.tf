resource "elestio_opensearch" "nodes" {
  for_each      = { for key, value in var.nodes : key => value }
  project_id    = var.project_id
  server_name   = "${var.server_name}-${each.key}"
  provider_name = each.value.provider_name
  datacenter    = each.value.datacenter
  server_type   = each.value.server_type
  version       = var.opensearch_version
  support_level = var.support_level
  admin_email   = var.admin_email
  ssh_keys = [
    {
      key_name   = var.ssh_key.key_name
      public_key = var.ssh_key.public_key
    },
  ]
  keep_backups_on_delete_enabled = true
}

resource "null_resource" "cluster_configuration" {
  triggers = {
    require_replace = join(",", [for n in elestio_opensearch.nodes : n.id])
  }

  provisioner "local-exec" {
    command = templatefile("${path.module}/scripts/setup_cluster.sh.tftpl", {
      nodes = [for n in elestio_opensearch.nodes : {
        global_ip = n.global_ip
        ipv4      = n.ipv4
        cname     = n.cname
      }]
      password        = elestio_opensearch.nodes[0].admin.password
      ssh_private_key = var.ssh_key.private_key
    })
  }
}
