# Vultr Terraform Example

This example will create a load-balanced, HA Talos cluster on vultr.com.
It will use the marketplace image of Talos that is present in Vultr and should result in a stable, maintainable cluster.

## Prereqs

Export the `VULTR_API_KEY` environment variable with your API key obtained from vultr.com.
From this directory, issue `terraform init` to ensure the proper providers are pulled down.

## Usage

To create a default cluster, this should be as simple as `terraform apply`.
This will create a cluster called `talos-vultr` with 3 control plane nodes and a single worker in the Atlanta region.
Each of these VMs will be 2 CPU / 4GB RAM VMs.
If different specs or regions are required, override them through command line with the `-var` flag or by creating a varsfile and overriding with `-var-file`.
Destroying the cluster should, again, be a simple `terraform destroy`.

Getting the kubeconfig and talosconfig for this cluster can be done with `terraform output -raw kubeconfig > <desired-path-and-filename>` and `terraform output -raw talosconfig > <desired-path-and-filename>`