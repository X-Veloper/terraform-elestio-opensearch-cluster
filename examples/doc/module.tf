module "cluster" {
  source = "elestio-examples/opensearch-cluster/elestio"

  project_id         = elestio_project.project.id
  opensearch_version = null # null means latest version
  opensearch_pass    = "xxxxxxxxxxxxx"

  configuration_ssh_key = {
    username    = "terraform"
    public_key  = chomp(file("~/.ssh/id_rsa.pub"))
    private_key = file("~/.ssh/id_rsa")
  }

  nodes = [
    {
      server_name   = "opensearch-1"
      provider_name = "scaleway"
      datacenter    = "fr-par-1"
      # OpenSearch requires at least 4GB of RAM
      # Check the list of available server types here: https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/providers_datacenters_server_types
      server_type = "MEDIUM-3C-4G"
    },
    {
      server_name   = "opensearch-2"
      provider_name = "scaleway"
      datacenter    = "fr-par-2"
      server_type   = "MEDIUM-3C-4G"
    },
  ]
}
