# Xen Orchestra Terraform examples

* Tested Talos version: `1.11.5`
* Test Xen Orchestra Provider version: `0.37.0`

## Simple example

This example provides a Terraform alternative to using the Xen Orchestra UI for VM creation. It automates the VM provisioning step but requires pre-generated Talos configurations. [Read the doc about Talos in Xen Orchestra](https://docs.siderolabs.com/talos/latest/platform-specific-installations/virtualized-platforms/xenorchestra-xcpng) to create the template VM.

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
* **Two installation modes**: pre-installed template or ISO-based installation

### Prerequisites

* **For template-based deployment**: A Talos VM template with Talos pre-installed (see [documentation](https://docs.siderolabs.com/talos/v1.11/platform-specific-installations/virtualized-platforms/xenorchestra-xcpng))
* **For ISO-based installation**: A Talos ISO uploaded to Xen Orchestra and a minimal VM template (`Generic Linux UEFI`)
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

talos_version = "v1.11.5"  # Talos version to install (used with ISO-based installation)

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

#### Installation Modes

This example supports two installation modes:

**1. Template-based deployment**

Uses a pre-installed Talos VM template. This is the default mode when `iso_name` is not specified.

```hcl
# In terraform.tfvars - no iso_name variable needed
tpl_talos_id = "<talos_template_id>"
```

**2. ISO-based installation**

Mounts a Talos ISO and installs Talos to disk during provisioning. Useful for:
- Installing specific Talos versions
- Custom installation images
- Environments without pre-built templates

```hcl
# In terraform.tfvars
tpl_talos_id = "<minimal_vm_template_id>"  # Any UEFI template (recommended: `Generic Linux UEFI`)
iso_name      = "talos-nocloud-amd64.iso"  # ISO name in Xen Orchestra
talos_version = "v1.11.5"                   # Talos version to install
```

When `iso_name` is provided:
- The ISO is mounted on all VMs via CDROM
- Installation configuration is added to Talos machine configs
- VMs will install Talos to `/dev/xvda` on first boot
- Installer image uses the specified `talos_version` with factory image `factory.talos.dev/nocloud-installer/53b20d86399013eadfd44ee49804c1fef069bfdee3b43f3f3f5a2f57c03338ac`

#### Cluster Endpoint

The `cluster_endpoint` variable defaults to `https://<cluster_vip>:6443` if not explicitly set. You can override it if needed:

```hcl
cluster_endpoint = "https://talos.example.com:6443"
```

The example configures a VIP on the control plane nodes' first network interface (`enX0`) using DHCP, ensuring high availability of the Kubernetes API endpoint.