# Azure Terraform Example

This example will create a load-balanced, HA Talos cluster on Azure.
It will use the official Sidero Labs AMI of Talos that is present and should result in a stable, maintainable cluster.

## Prereqs

Ensure your Azure environment is configured correctly (see  for details).
From this directory, issue `terraform init` to ensure the proper providers are pulled down.
A disk image of Talos must be downloaded locally to be provided as a storage blob in Azure.
The following command is an example og how to do this for the latest relase of Talos:

```bash
curl -sL https://github.com/siderolabs/talos/releases/latest/download/azure-amd64.tar.gz | tar -xz
```

## Usage

To create a default cluster, this should be as simple as `terraform apply`.
Occasionally some Azure resources may not be ready in time for Terraform to rely on them for a later resource and may return errors such as the following:

```shell
 Error: failed creating container: failed creating container: containers.Client#Create: Failure responding to request: StatusCode=404 -- Original Error: autorest/azure: Service returned an error. Status=404 Code="ResourceNotFound" Message="The specified resource does not exist.\nRequestId:d7008d74-b01e-007b-39d8-2c38de000000\nTime:2023-01-20T14:05:32.3698226Z"

   with azurerm_storage_container.this,
   on main.tf line 16, in resource "azurerm_storage_container" "this":
   16: resource "azurerm_storage_container" "this" {
```

Simply re-run `terraform apply` to solve these issues.

This will create a cluster called `talos-azure-example` with 3 control plane nodes and a single worker in the West Europe region.
By default, the instances will be `Standard_B2s`, with 2 VPU and 4GB RAM each.
If different specs or regions are required, override them through command line with the `-var` flag or by creating a varsfile and overriding with `-var-file`.
Destroying the cluster should, again, be a simple `terraform destroy`.

Getting the kubeconfig and talosconfig for this cluster can be done with `terraform output -raw kubeconfig > <desired-path-and-filename>` and `terraform output -raw talosconfig > <desired-path-and-filename>`

