# Xen Orchestra Terraform examples

* Tested Talos version: `1.11.5`
* Test Xen Orchestra Provider version: `0.37.0`

## Simple example

This example is an alternative to the Xen Orchestra UI to create a cluster from a Talos VM Template. [Read the doc about Talos in Xen Orchestra](https://docs.siderolabs.com/talos/v1.11/platform-specific-installations/virtualized-platforms/xenorchestra-xcpng) to create the template VM. 

**This replace only the steps 2 and 3 of the "_Create the Talos cluster_" section of the guide.**


* Currently only one control-plane is set up (no HA) and one worker.
* It requires a generated Talos config to work.
    * The plan with load `controlplane.yaml` and `worker.yaml` into the cloud-init of the Xen Orchestra VMs.
* You need to boostrap the cluster after

## Example using the Talos provider

TODO