terraform {
  required_providers {
    elestio = {
      source = "elestio/elestio"
    }
  }
}

provider "elestio" {
  email     = var.elestio_email
  api_token = var.elestio_api_token
}

resource "elestio_project" "project" {
  name = "opensearch-cluster"
}

module "cluster" {
  source = "elestio-examples/opensearch-cluster/elestio"

  project_id         = elestio_project.project.id
  opensearch_version = null # null means latest version
  opensearch_pass    = var.opensearch_pass

  configuration_ssh_key = {
    username    = "admin"
    public_key  = chomp(file("~/.ssh/id_rsa.pub"))
    private_key = file("~/.ssh/id_rsa")
  }

  nodes = [
    {
      server_name   = "opensearch-1"
      provider_name = "scaleway"
      datacenter    = "fr-par-1"
      server_type   = "MEDIUM-3C-4G"
    },
    {
      server_name   = "opensearch-2"
      provider_name = "scaleway"
      datacenter    = "fr-par-2"
      server_type   = "MEDIUM-3C-4G"
    },
    {
      server_name   = "opensearch-3"
      provider_name = "scaleway"
      datacenter    = "fr-par-2"
      server_type   = "MEDIUM-3C-4G"
    },
  ]
}

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
