* Tested Talos version: `1.3.0`
* Currently only one control-plane is set up (no HA).
* Number of workers need to be defined in a `tfvars` file. For an example with three workers see `terraform/three_workers.tfvars`
* One additional volume is attached to each worker with size specified in the `worker_extra_volume_size` variable.
* Required patches for [OpenEBS Mayastor](https://mayastor.gitbook.io/introduction/) are applied in `templates/controlplanepatch.yaml.tmpl`

## Prerequisites 

```bash
# hcloud cli
brew install hcloud
# talosctl, check for latest version https://github.com/siderolabs/talos
sudo curl -Lo /usr/local/bin/talosctl https://github.com/siderolabs/talos/releases/download/v1.3.0/talosctl-$(uname -s | tr "[:upper:]" "[:lower:]")-amd64
sudo chmod +x /usr/local/bin/talosctl
# hashicorp packer
brew tap hashicorp/tap
brew install hashicorp/tap/packer
# hashicrop terraform
brew install hashicorp/tap/terraform
```

Export your hcloud token:

```bash
export HCLOUD_TOKEN=<hcloud-token>
```

## Packer

Create the talos os image via packer. The talos os version is defined in the variable `talos_version`  in `hcloud_talosimage.pkr.hcl`.

```bash
cd packer
packer init .
packer build .
# after completion, export the image ID
export TF_VAR_image_id=<image-id-in-packer-output>
```

## HCloud

```bash
cd terraform
terraform init
# example with three worker nodes
terraform plan -var-file=three_workers.tfvars
terraform apply -var-file=three_workers.tfvars
```

## Talosconfig and Kubeconfig

Once terrafrom finished successfully, retrieve `talosconfig` and `kubeconfig` from the output.

Example:

```bash
terraform output -raw talosconfig > ~/hcloud-dev-cluster/talosconfig
terraform output -raw kubeconfig > ~/hcloud-dev-cluster/kubeconfig
export TALOSCONFIG=~/hcloud-dev-cluster/talosconfig
export KUBECONFIG=~/hcloud-dev-cluster/kubeconfig
# check if all nodes are available, target the control plane (default 10.0.0.3 set in variables.tf)
talosctl get members -n 10.0.0.3
# check nodes
kubectl get nodes -o wide
```