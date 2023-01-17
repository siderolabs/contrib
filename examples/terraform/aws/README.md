# AWS Terraform Example

This example will create a load-balanced, HA Talos cluster on AWS.
It will use the official Sidero Labs AMI of Talos that is present and should result in a stable, maintainable cluster.

## Prereqs

Ensure your AWS environment is configured correctly (see https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables and https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html for details).
From this directory, issue `terraform init` to ensure the proper providers are pulled down.

## Usage

To create a default cluster, this should be as simple as `terraform apply`.
This will create a cluster called `talos-aws-example` with 3 control plane nodes and a single worker in the default AWS region.
By default, the instances will be `c5.large`, with 2 VPU and 4GB RAM each.
If different specs or regions are required, override them through command line with the `-var` flag or by creating a varsfile and overriding with `-var-file`.
Destroying the cluster should, again, be a simple `terraform destroy`.

Getting the kubeconfig and talosconfig for this cluster can be done with `terraform output -raw kubeconfig > <desired-path-and-filename>` and `terraform output -raw talosconfig > <desired-path-and-filename>`
