output "nodes_admins" {
  value       = { for node in module.cluster.nodes : node.server_name => node.admin }
  sensitive   = true
  description = "Kibana dashboard secrets"
}

output "nodes_database_admins" {
  value       = { for node in module.cluster.nodes : node.server_name => node.database_admin }
  sensitive   = true
  description = "Opensearch database secrets"
}
