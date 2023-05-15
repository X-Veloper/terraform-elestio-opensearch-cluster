output "cluster_nodes" {
  value       = elestio_opensearch.nodes
  description = "All the information of the nodes in the cluster"
  sensitive   = true
}

output "cluster_admin" {
  value = [for node in elestio_opensearch.nodes : {
    url      = node.admin.url
    user     = node.admin.user
    password = elestio_opensearch.nodes[0].admin.password
  }]
  description = "The secrets to connect to Kibana (UI dashboard) on each nodes"
  sensitive   = true
}

output "cluster_database_admin" {
  value = {
    nodes = [for node in elestio_opensearch.nodes : format("https://%s:%s", node.database_admin.host, node.database_admin.port)]
    auth = {
      username = elestio_opensearch.nodes[0].database_admin.user
      password = elestio_opensearch.nodes[0].database_admin.password
    }
  }
  description = "The database secrets of the cluster"
  sensitive   = true
}
