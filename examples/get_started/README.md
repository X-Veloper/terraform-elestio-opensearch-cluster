# Get started : OpenSearch Cluster with Terraform and Elestio

In this example, you will learn how to use this module to deploy your own OpenSearch cluster with Elestio.

Some knowledge of [terraform](https://developer.hashicorp.com/terraform/intro) is recommended, but if not, the following instructions are sufficient.

## Prepare the dependencies

- [Sign up for Elestio if you haven't already](https://dash.elest.io/signup)

- [Get your API token in the security settings page of your account](https://dash.elest.io/account/security)

- [Download and install Terraform](https://www.terraform.io/downloads)

  You need a Terraform CLI version equal or higher than v0.14.0.
  To ensure you're using the acceptable version of Terraform you may run the following command: `terraform -v`

## Instructions

1. Rename `secrets.tfvars.example` to `secrets.tfvars` and fill in the values.

   This file contains the sensitive values to be passed as variables to Terraform.</br>
   You should **never commit this file** with git.

2. Run terraform with the following commands:

   ```bash
   terraform init
   terraform plan -var-file="secrets.tfvars" # to preview changes
   terraform apply -var-file="secrets.tfvars"
   terraform show
   ```

3. You can use the `terraform output` command to print the output block of your main.tf file:

   ```bash
   terraform output cluster_admin # Kibana secrets
   terraform output cluster_database_admin # OpeanSearch Database secrets
   ```

## Testing

Use `terraform output cluster_database_admin` command to output database secrets:

```bash
# cluster_database_admin
{
  "auth" = {
    "password" = "*****"
    "user" = "root"
  }
  "nodes" = [
    "https://opensearch-0-u525.vm.elestio.app:19200",
    "https://opensearch-1-u525.vm.elestio.app:19200",
  ]
}
```

1.  Create the first index on the **first node**:

    ```bash
    curl -XPUT -u 'root:*****' 'https://opensearch-0-u525.vm.elestio.app:19200/my-first-index'
    ```

2.  Add some data to your newly created index:

    ```bash
    curl -XPUT -u 'root:*****' 'https://opensearch-0-u525.vm.elestio.app:19200/my-first-index/_doc/1' -H 'Content-Type: application/json' -d '{"Description": "To be or not to be, that is the question."}'
    ```

3.  Retrieve the data on the **second node** to see that it was replicated properly:

    ```bash
    curl -XGET -u 'root:*****' 'https://opensearch-1-u525.vm.elestio.app:19200/my-first-index/_doc/1'
    ```

4.  After verifying that the cluster is working, delete the document and the index:

    ```bash
    curl -XDELETE -u 'root:*****' 'https://opensearch-1-u525.vm.elestio.app:19200/my-first-index/_doc/1'
    ```

    ```bash
    curl -XDELETE -u 'root:*****' 'https://opensearch-0-u525.vm.elestio.app:19200/my-first-index/'
    ```

You can try turning off the first node on the [Elestio dashboard](https://dash.elest.io/).
The second node remains functional.
When you restart it, it automatically updates with the new data.

## How to use OpenSearch cluster

Use `terraform output cluster_database_admin` command to output database secrets:

```bash
# cluster_database_admin
{
"auth" = {
  "password" = "*****"
  "user" = "root"
}
"nodes" = [
  "https://opensearch-0-u525.vm.elestio.app:19200",
  "https://opensearch-1-u525.vm.elestio.app:19200",
]
}
```

```js
////////////// JS sample //////////////
const { Client } = require("@opensearch-project/opensearch/.");

const client = new Client({
  auth: {
    username: "root",
    password: "*****",
  },
  nodes: [
    "https://opensearch-0-u525.vm.elestio.app:19200",
    "https://opensearch-1-u525.vm.elestio.app:19200",
  ],
  nodeSelector: "round-robin",
});

client
  .search({
    index: "my-index",
    body: {
      query: {
        match: { title: "OpenSearch" },
      },
    },
  })
  .then((response) => {
    console.log(response.hits.hits);
  })
  .catch((error) => {
    console.log(error);
  });
////////////// ////////////// ////////////// //////////////
```
