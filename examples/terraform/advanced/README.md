# Advacned Terraform Example

This example will create a local Talos cluster using libvirt.

This example shows how to manage the whole Talos machine secrets using custom CA.
It's recommended to pre-generate the keys required and pass it as variables to Terraform, since terraform stores the state in plain text.

## Prereqs

This guide assumes that libvirt is installed and running.
From this directory, issue `terraform init` to ensure the proper providers are pulled down.

## Usage

To create a default cluster, this should be as simple as `terraform apply`.
You will need to specify the `cluster_name` and `iso_path` variables during application.

If different configurations are required, override them through command line with the `-var` flag or by creating a varsfile and overriding with `-var-file`.
Destroying the cluster should, again, be a simple `terraform destroy`.

Getting the kubeconfig and talosconfig for this cluster can be done with `terraform output -raw kubeconfig > <desired-path-and-filename>` and `terraform output -raw talosconfig > <desired-path-and-filename>`.
