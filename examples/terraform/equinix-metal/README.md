# Equnix Metal Terraform Example

This example will create an HA Talos cluster on Equinix Metal.
It will use the built-in Talos offering that is present in Equnix Metal and should result in a stable, maintainable cluster.

## Prereqs

Export the `TF_VAR_em_api_token` environment variable with your API key obtained from Equinix Metal.
This environment variable will set the token for the Equinix Metal provider to function properly, as well as pass this token to Talos itself so that it can manage the VIP that is created for the cluster.
You can also enter this API token during the apply below.
From this directory, issue `terraform init` to ensure the proper providers are pulled down.

## Usage

To create a default cluster, this should be as simple as `terraform apply`.
This will create a cluster called `talos-em` with 3 control plane nodes and a single worker in the Washington DC region.
It will also create an elastic IP that is used 
Each of these machines will their smallest offering, the `c3.small.x86`.
If different specs or regions are required, override them through command line with the `-var` flag or by creating a varsfile and overriding with `-var-file`.
Destroying the cluster should, again, be a simple `terraform destroy`.

Getting the kubeconfig and talosconfig for this cluster can be done with `terraform output -raw kubeconfig > <desired-path-and-filename>` and `terraform output -raw talosconfig > <desired-path-and-filename>`.
