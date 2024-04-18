<!-- BEGIN_TF_DOCS -->
# Elestio OpenSearch Cluster Terraform module

## Benefits of an OpenSearch cluster

An OpenSearch cluster is a great option to ensure high availability, it allows for easy scalability to meet changing demands without replacing the entire system.
It can handle more requests without slowing down or crashing, and provides fault tolerance to ensure that the system remains operational.

## Module requirements

- 1 Elestio account https://dash.elest.io/signup
- 1 API key https://dash.elest.io/account/security
- 1 SSH public/private key (see how to create one [here](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/ssh_keys))

## Module usage

This is a minimal example of how to use the module:

```hcl
module "cluster" {
  source = "elestio-examples/opensearch-cluster/elestio"

  project_id      = "xxxxxx"
  opensearch_pass = "xxxxxx"

  configuration_ssh_key = {
    username    = "something"
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
```

Keep your opensearch password safe, you will need it to access the admin panel.

If you want to know more about node configuration, check the opensearch service documentation [here](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/opensearch).

If you want to choose your own provider, datacenter or server type, check the guide [here](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/providers_datacenters_server_types).

If you want to generated a valid SSH Key, check the guide [here](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/ssh_keys).

If you add more nodes, you may attains the resources limit of your account, please visit your account [quota page](https://dash.elest.io/account/add-quota).

## Quick configuration

The following example will create an OpenSearch cluster with 2 nodes.

You may need to adjust the configuration to fit your needs.

Create a `main.tf` file at the root of your project, and fill it with your Elestio credentials:

```hcl
terraform {
  required_providers {
    elestio = {
      source = "elestio/elestio"
    }
  }
}

provider "elestio" {
  email     = "xxxx@xxxx.xxx"
  api_token = "xxxxxxxxxxxxx"
}

resource "elestio_project" "project" {
  name = "opensearch-cluster"
}
```

Now you can use the module to create opensearch nodes:

```hcl
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
```

To get a valid random opensearch password, you can use the url https://api.elest.io/api/auth/passwordgenerator

```bash
$ curl -s https://api.elest.io/api/auth/passwordgenerator
{"status":"OK","password":"7Tz1lCfD-Y8di-AyU2o467"}
```

Finally, let's add some outputs to retrieve useful information:

```hcl
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
```

You can now run `terraform init` and `terraform apply` to create your OpenSearch cluster.
After a few minutes, the cluster will be ready to use.
You can access your outputs with `terraform output`:

```bash
$ terraform output nodes_admins
$ terraform output nodes_database_admins
```

If you want to update some parameters, you can edit the `main.tf` file and run `terraform apply` again.
Terraform will automatically update the cluster to match the new configuration.
Please note that changing some parameters requires to change the .env of existing nodes. This is done automatically by the module.

## Ready-to-deploy example

We created a ready-to-deploy example which creates the same infrastructure as the previous example.
You can find it [here](https://github.com/elestio-examples/terraform-elestio-opensearch-cluster/tree/main/examples/get_started).
Follow the instructions to deploy the example.

## How to use the cluster

Use `terraform output nodes_database_admins` command to output database secrets:

```bash
{
  "opensearch-1" = {
    "command" = ""
    "host" = "opensearch-1-cname.elestio.app"
    "password" = "*****"
    "port" = "19200"
    "user" = "root"
  }
  "opensearch-2" = {
    "command" = ""
    "host" = "opensearch-2-cname.elestio.app"
    "password" = "*****"
    "port" = "19200"
    "user" = "root"
  }
}
```

Here is an example of how to use the Opensearch cluster and all its nodes in the [Javascript client](https://opensearch.org/docs/latest/clients/javascript/index/).

```js
// Javascript example
const { Client } = require('@opensearch-project/opensearch/.');

const client = new Client({
  auth: {
    username: 'root',
    password: '*****',
  },
  nodes: [
    'https://opensearch-1-cname.vm.elestio.app:19200',
    'https://opensearch-2-cname.vm.elestio.app:19200',
  ],
  nodeSelector: 'round-robin',
});

client
  .search({
    index: 'my-index',
    body: {
      query: {
        match: { title: 'OpenSearch' },
      },
    },
  })
  .then((response) => {
    console.log(response.hits.hits);
  })
  .catch((error) => {
    console.log(error);
  });
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_configuration_ssh_key"></a> [configuration\_ssh\_key](#input\_configuration\_ssh\_key) | After the nodes are created, Terraform must connect to apply some custom configuration.<br>This configuration is done using SSH from your local machine.<br>The Public Key will be added to the nodes and the Private Key will be used by your local machine to connect to the nodes.<br><br>Read the guide ["How generate a valid SSH Key for Elestio"](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/ssh_keys). Example:<pre>configuration_ssh_key = {<br>  username = "admin"<br>  public_key = chomp(file("\~/.ssh/id_rsa.pub"))<br>  private_key = file("\~/.ssh/id_rsa")<br>}</pre> | <pre>object({<br>    username    = string<br>    public_key  = string<br>    private_key = string<br>  })</pre> | n/a | yes |
| <a name="input_nodes"></a> [nodes](#input\_nodes) | Each element of this list will create an Elestio OpenSearch Resource in your cluster.<br>Read the following documentation to understand what each attribute does, plus the default values: [Elestio OpenSearch Resource](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/opensearch). | <pre>list(<br>    object({<br>      server_name                                       = string<br>      provider_name                                     = string<br>      datacenter                                        = string<br>      server_type                                       = string<br>      admin_email                                       = optional(string)<br>      alerts_enabled                                    = optional(bool)<br>      app_auto_update_enabled                           = optional(bool)<br>      backups_enabled                                   = optional(bool)<br>      firewall_enabled                                  = optional(bool)<br>      keep_backups_on_delete_enabled                    = optional(bool)<br>      remote_backups_enabled                            = optional(bool)<br>      support_level                                     = optional(string)<br>      system_auto_updates_security_patches_only_enabled = optional(bool)<br>      ssh_public_keys = optional(list(<br>        object({<br>          username = string<br>          key_data = string<br>        })<br>      ), [])<br>    })<br>  )</pre> | `[]` | no |
| <a name="input_opensearch_pass"></a> [opensearch\_pass](#input\_opensearch\_pass) | Require at least 10 characters, one uppercase letter, one lowercase letter and one number.<br>Generate a random valid password: https://api.elest.io/api/auth/passwordgenerator | `string` | n/a | yes |
| <a name="input_opensearch_version"></a> [opensearch\_version](#input\_opensearch\_version) | The cluster nodes must share the same opensearch version.<br>Leave empty or set to `null` to use the Elestio recommended version. | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | n/a | `string` | n/a | yes |
## Modules

No modules.
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_nodes"></a> [nodes](#output\_nodes) | This is the created nodes full information |
## Providers

| Name | Version |
|------|---------|
| <a name="provider_elestio"></a> [elestio](#provider\_elestio) | >= 0.17.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.0 |
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_elestio"></a> [elestio](#requirement\_elestio) | >= 0.17.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.0 |
## Resources

| Name | Type |
|------|------|
| [elestio_opensearch.nodes](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/opensearch) | resource |
| [null_resource.update_nodes_env](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
<!-- END_TF_DOCS -->
