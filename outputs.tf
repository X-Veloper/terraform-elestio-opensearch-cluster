output "nodes" {
  description = "This is the created nodes full information"
  value       = elestio_opensearch.nodes
  sensitive   = true
}
