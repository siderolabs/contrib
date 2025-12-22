# Xen Orchestra Terraform examples

* Tested Talos version: `1.11.5`
* Test Xen Orchestra Provider version: `0.37.0`

## Simple example

This example provides a Terraform alternative to using the Xen Orchestra UI for VM creation. It automates the VM provisioning step but requires pre-generated Talos configurations. [Read the doc about Talos in Xen Orchestra](https://docs.siderolabs.com/talos/v1.11/platform-specific-installations/virtualized-platforms/xenorchestra-xcpng) to create the template VM.

**This replaces steps 2 and 3 of the "_Create the Talos cluster_" section in the guide.**

Key features:
* Creates VMs from a Talos template using Terraform
* Uses cloud-init to inject pre-generated Talos configurations (`controlplane.yaml` and `worker.yaml`)
* Default configuration: 1 control plane (no HA) and 1 worker node
* Requires manual cluster bootstrapping after VM creation

### Prerequisites

* Pre-generated Talos configurations (`controlplane.yaml` and `worker.yaml`)
* A Talos VM template created in Xen Orchestra
* Xen Orchestra API token
* Terraform installed

### Limitations

* No automatic bootstrapping - you must manually run `talosctl bootstrap` after VM creation
* Single control plane node by default (no high availability)
* Requires generating Talos configurations externally before applying the plan

## Example using the Talos provider

This example uses the Talos Terraform provider to fully automate the creation and configuration of a Talos cluster on Xen Orchestra. [Read the doc about Talos in Xen Orchestra](https://docs.siderolabs.com/talos/v1.11/platform-specific-installations/virtualized-platforms/xenorchestra-xcpng) to create the template VM.

**This is a complete end-to-end automation that replaces all steps of the "_Create the Talos cluster_" section of the guide.**

Key features:
* Uses the Talos Terraform provider to generate machine configurations dynamically
* Configures Virtual IP (VIP) for control plane high availability
* Automatically bootstraps the Talos cluster
* Generates and outputs both `talosconfig` and `kubeconfig`
* Supports multiple control plane and worker nodes
* No manual Talos configuration required

### Prerequisites

* A Talos VM template created in Xen Orchestra (see [documentation](https://docs.siderolabs.com/talos/v1.11/platform-specific-installations/virtualized-platforms/xenorchestra-xcpng))
* Xen Orchestra API token
* Terraform installed
* A network with DHCP configured in your Xen Orchestra environment

### Usage

1. Copy the example configuration:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your Xen Orchestra and cluster details:
```hcl
xoa_token = "<your_xen_orchestra_api_token>"
xoa_url   = "https://your-xoa-server.example.com"

tpl_talos_id = "<talos_template_id>"
pool_name    = "<pool_name_label>"
sr_name      = "<shared_storage_name_label>"
network_name = "<network_name_label>"
expected_ip_cidr = "10.1.0.0/16"

cluster_name = "demo-talos"
cluster_vip  = "10.1.0.10"  # Virtual IP for the cluster endpoint

# Optional: customize node sizing
num_control_plane = 3
num_workers       = 2
```

3. Initialize and apply:
```bash
terraform init
terraform plan
terraform apply
```

4. Retrieve cluster credentials:
```bash
terraform output -raw talosconfig > ~/.talos/config
terraform output -raw kubeconfig > ~/.kube/config
export TALOSCONFIG=~/.talos/config
export KUBECONFIG=~/.kube/config
```

5. Verify the cluster:
```bash
# Check cluster health
talosctl health

# Check nodes
kubectl get nodes -o wide
```

### Configuration Details

The `cluster_endpoint` variable defaults to `https://<cluster_vip>:6443` if not explicitly set. You can override it if needed:

```hcl
cluster_endpoint = "https://talos.example.com:6443"
```

The example configures a VIP on the control plane nodes' first network interface (`enX0`) using DHCP, ensuring high availability of the Kubernetes API endpoint.