# Basic Terraform Example

This example will create a basic Talos cluster using local machines.

## Prereqs

This guide assumes that you have pre-existing machines that have been booted with a Talos image or ISO without machine configuration, such that these machines are sitting in "maintenance mode" waiting to be provisioned.
From this directory, issue `terraform init` to ensure the proper providers are pulled down.

## Usage

To create a default cluster, this should be as simple as `terraform apply`.
You will need to specify the `cluster_name` and `cluster_endpoint` variables during application.
The `cluster_endpoint` variable should have the form `https://<control-plane-ip-or-vip-or-dns-name>:6443`.
This will create a cluster based on the `node_data` variable, containing the IPs of each Talos node, as well as the install disk and hostname (optional).

If different configurations are required, override them through command line with the `-var` flag or by creating a varsfile and overriding with `-var-file`.
Destroying the cluster should, again, be a simple `terraform destroy`.

Getting the kubeconfig and talosconfig for this cluster can be done with `terraform output -raw kubeconfig > <desired-path-and-filename>` and `terraform output -raw talosconfig > <desired-path-and-filename>`.
