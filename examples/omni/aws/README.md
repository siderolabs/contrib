# Omni on AWS — EKS-like Cluster

An opinionated example that stands up a Talos Kubernetes cluster on AWS using Omni with the
same set of controllers you would get from an EKS "managed addons" cluster.
Nodes are provisioned by the community
[omni-infra-provider-aws](https://github.com/rothgar/omni-infra-provider-aws);
addons are delivered by Omni's Kubernetes Manifest Sync so the cluster stays
declarative end-to-end.

## What you get

| Component | Source | Purpose |
|-----------|--------|---------|
| `vpc-cni` | `aws-vpc-cni` Helm chart | Pod networking via ENIs (replaces flannel) |
| `ccm` | `kubernetes/cloud-provider-aws` release YAML | AWS cloud controller manager |
| `ebs-csi` | `aws-ebs-csi-driver` Helm chart | EBS block-storage CSI driver |
| `snapshot-controller` | `external-snapshotter` release YAML | VolumeSnapshot CRDs + controller |
| `storageclass-gp3` | hand-written | Default `gp3` StorageClass (encrypted, WFFC) |
| `lb-controller` | `aws-load-balancer-controller` Helm chart | Manages ALB/NLB for Services + Ingress |
| `external-dns` | `external-dns` Helm chart | Route53 records from Services / Ingress |
| `cluster-autoscaler` | `cluster-autoscaler` Helm chart | Scales worker MachineSets on demand |
| `metrics-server` | `metrics-server` Helm chart | `kubectl top` and HPA metrics |

Everything under `manifests/` is a rendered artifact — nothing dynamic. To
refresh a chart, re-run `helm template` (or re-download the release YAML) and
commit the result. The manifests are synced with `mode: full`, so Omni will
reconcile any drift back to what's in the file.

## Layout

```
aws/
├── cluster.yaml              # Omni cluster template (CP + workers + manifests)
├── aws-controlplane.yaml     # MachineClass for control-plane nodes
├── aws-worker.yaml           # MachineClass for worker nodes
├── machineconfig.yaml        # SideroLink join config baked into the AMI
├── patches/
│   ├── cluster.yaml          # Cluster-wide Talos patch (disable flannel, ECR creds, external CCM)
│   ├── controlplane.yaml     # CP-only Talos patch
│   └── worker.yaml           # Worker-only Talos patch
└── manifests/                # Rendered YAML synced by Omni
```

## Prerequisites

- An [Omni account](https://siderolabs.com/omni-signup) with API access.
- `omnictl` [installed and configured](https://docs.siderolabs.com/omni/getting-started/install-and-configure-omnictl).
- An AWS account you can create IAM roles, VPCs, subnets, and EC2 instances in.
- `aws` CLI, `envsubst` (from `gettext`), and `jq` — used to render the templated files below.

## AWS setup

### 1. Networking

You need one VPC with at least two subnets across different AZs (three is
better) and a security group that permits:

- Egress to the internet (so nodes can reach the Omni API and pull images).
- Intra-cluster traffic on the VPC CIDR (VPC-CNI ENIs and kubelet talk directly).
- Inbound 6443 from wherever you plan to reach the Kubernetes API.

Note the VPC/subnet/SG IDs — they go into the MachineClasses.

### 2. Node IAM roles

Create two IAM roles with EC2 as the trusted principal, then wrap each in an
instance profile. The provider README has the full policy documents under
["Create the Node IAM Roles"](https://github.com/rothgar/omni-infra-provider-aws#create-the-node-iam-roles).

- **`TalosControlPlane`** — broad permissions. The CP nodes run every
  AWS-integrating controller in this example (VPC-CNI, CCM, EBS-CSI,
  LB Controller, external-dns, cluster-autoscaler), so they need EC2, ELB,
  Route53, and IAM read/tag permissions in addition to ECR pull.
- **`TalosWorkerNode`** — minimum needed for user workloads: ECR pull and
  EBS attach/detach for the CSI node plugin.

Save both instance-profile ARNs.

### 3. Route53 hosted zone (optional)

Only needed if you want `external-dns` to publish records. The example includes
external-dns but does not configure a specific zone — edit
`manifests/external-dns.yaml` to point at your zone before syncing, or remove
the entry from `cluster.yaml`.

## Install the AWS infrastructure provider

Follow the [omni-infra-provider-aws
README](https://github.com/rothgar/omni-infra-provider-aws) to deploy the
provider.

1. Create an IAM user/role for the provider itself with permissions to launch
   and terminate EC2 instances in your target region.
2. Register the provider with Omni using the credentials from step 1. The
   provider ID you choose (e.g. `aws-us-east-2`) is what you'll reference from
   the MachineClasses.
3. Build a Talos AMI that has the SideroLink join token baked in — see
   `machineconfig.yaml` in this directory for the shape of the config. The
   provider README covers using `omni-image-factory` or building the AMI
   yourself.

Once the provider is running, `omnictl get infraproviders` should list it.

## Render templates

`aws-controlplane.yaml`, `aws-worker.yaml`, and `machineconfig.yaml` are
committed as templates — they reference `${VAR}` placeholders instead of
account- or tenant-specific IDs. Populate the environment, then pipe each file
through `envsubst` before feeding it to `omnictl`. Nothing in this directory
needs to be edited by hand.

### Required variables

| Variable | What it is | Suggested source |
|----------|------------|------------------|
| `AWS_ACCOUNT_ID` | Your 12-digit AWS account ID (used in the IAM ARN) | `aws sts get-caller-identity --query Account --output text` |
| `AWS_REGION` | Target AWS region — matches the region baked into your provider ID and addon manifests | `aws configure get region` or hard-code, e.g. `us-east-2` |
| `AWS_VPC_ID` | The VPC that will host the cluster | Look up in the AWS console or `aws ec2 describe-vpcs` |
| `AWS_SECURITY_GROUP_ID` | SG attached to every node (see AWS setup step 1) | `aws ec2 describe-security-groups --filters Name=group-name,Values=omni-cluster --query 'SecurityGroups[0].GroupId' --output text` |
| `AWS_SUBNET_ID_1..3` | Three subnets across different AZs | `aws ec2 describe-subnets --filters Name=vpc-id,Values=$AWS_VPC_ID --query 'Subnets[].SubnetId' --output text` |
| `OMNI_INFRA_PROVIDER_ID` | ID you registered the AWS provider under | `omnictl get infraproviders` |
| `OMNI_SIDEROLINK_URL` | SideroLink API URL + join token — baked into the AMI | `omnictl jointoken omni-endpoint <jointoken-id>` |
| `VPC_CNI_ECR_ACCOUNT` | AWS-owned ECR account hosting the VPC-CNI images for your region | Usually `602401143452`; China + GovCloud regions differ — see the [EKS add-on image map](https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html) |

Example wiring (drop into a `.envrc`, `direnv` file, or run in a shell):

```bash
export AWS_REGION=us-east-2
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Pick or create the VPC and SG that match the AWS setup section above.
export AWS_VPC_ID=vpc-0123456789abcdef0
export AWS_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
  --filters Name=vpc-id,Values=$AWS_VPC_ID Name=group-name,Values=omni-cluster \
  --query 'SecurityGroups[0].GroupId' --output text)

# Three subnets from the VPC (across AZs).
read -r AWS_SUBNET_ID_1 AWS_SUBNET_ID_2 AWS_SUBNET_ID_3 < <(aws ec2 describe-subnets \
  --filters Name=vpc-id,Values=$AWS_VPC_ID \
  --query 'Subnets[0:3].SubnetId' --output text)
export AWS_SUBNET_ID_1 AWS_SUBNET_ID_2 AWS_SUBNET_ID_3

# Provider ID chosen when the AWS infra provider was registered.
export OMNI_INFRA_PROVIDER_ID=aws-$AWS_REGION

# AWS-owned ECR account for VPC-CNI images (region-dependent).
export VPC_CNI_ECR_ACCOUNT=602401143452

# Create (or reuse) a join token, then grab the full SideroLink URL for it.
# `omnictl jointoken create <name>` if you need a new one.
export OMNI_SIDEROLINK_URL=$(omnictl jointoken omni-endpoint $(
  omnictl jointoken list -o json | jq -r '.[] | select(.default) | .id'))
```

### Other addon knobs

`manifests/external-dns.yaml` still expects manual edits: set your Route53
hosted zone (and, if you're using ASG discovery tags for the autoscaler,
double-check `manifests/cluster-autoscaler.yaml`'s `autoDiscovery.tags`).

Everything else — the VPC-CNI ECR image URIs, LB controller `--aws-region`,
autoscaler `AWS_REGION` env, MachineClass fields, SideroLink URL — is
templated and covered by the render step below.

## Deploy

Render every YAML into a `rendered/` mirror, then run `omnictl` from there so
the relative `manifests/` and `patches/` paths in `cluster.yaml` still
resolve:

```bash
mkdir -p rendered/manifests rendered/patches
for f in *.yaml manifests/*.yaml patches/*.yaml; do
  envsubst < "$f" > "rendered/$f"
done

# Anything unset passes through untouched — bail if any ${VAR} survived.
! grep -rn '\${' rendered/ || { echo "unrendered vars in rendered/"; exit 1; }

cd rendered
omnictl apply -f aws-controlplane.yaml
omnictl apply -f aws-worker.yaml
omnictl cluster template sync -f cluster.yaml
```

`rendered/machineconfig.yaml` gets baked into the Talos AMI (or handed to the
provider as user-data). Keep the whole `rendered/` directory out of git —
`machineconfig.yaml` contains the join token.

Omni will:

1. Ask the AWS provider to launch 1 CP + 3 worker EC2 instances.
2. Bootstrap Talos and Kubernetes on them.
3. Sync every file in `manifests/` into the API server once it's up. Files
   marked `mode: full` are reconciled continuously; switch a specific manifest
   to `mode: one-time` if you plan to hand-edit it in-cluster.

Grab a kubeconfig with:

```bash
omnictl kubeconfig -c aws
```

## Regenerating the manifests

The `manifests/` files are all rendered from upstream releases. Rough recipes:

```bash
# vpc-cni
helm repo add eks https://aws.github.io/eks-charts
helm template aws-vpc-cni eks/aws-vpc-cni \
  -n kube-system > manifests/vpc-cni.yaml

# aws cloud controller manager
curl -sL https://raw.githubusercontent.com/kubernetes/cloud-provider-aws/master/examples/existing-cluster/base/aws-cloud-controller-manager-daemonset.yaml \
  > manifests/ccm.yaml

# ebs-csi
helm template aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
  -n kube-system > manifests/ebs-csi.yaml

# aws load balancer controller
helm template aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system --set clusterName=aws > manifests/lb-controller.yaml

# external-dns
helm template external-dns external-dns/external-dns \
  -n kube-system > manifests/external-dns.yaml

# cluster-autoscaler
helm template cluster-autoscaler autoscaler/cluster-autoscaler \
  -n kube-system --set autoDiscovery.clusterName=aws > manifests/cluster-autoscaler.yaml

# metrics-server
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm template metrics-server metrics-server/metrics-server \
  -n kube-system > manifests/metrics-server.yaml

# external-snapshotter (CRDs + controller)
curl -sL https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.0.1/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml \
  > manifests/snapshot-controller.yaml
```

After regenerating, re-run `omnictl cluster template sync -f cluster.yaml` to
push the updates.

## Notes

- **Topology**: `cluster.yaml` defaults to 3 control-plane nodes for HA and
  3 workers. That needs 6 machines to be provisionable by the AWS infra
  provider — drop `ControlPlane.size` to 1 for a dev/smoke-test cluster, but
  a 1-node CP has no HA and etcd cannot survive a node loss.
- **Instance sizing**: `t3.medium` on both roles is enough to boot and pass
  a smoke test. It is *not* enough for anything more — CP nodes here host
  every AWS-integrating controller (VPC-CNI, CCM, EBS-CSI, LB Controller,
  external-dns, cluster-autoscaler, metrics-server, snapshot-controller)
  alongside etcd and kube-apiserver. Bump to at least `m5.large` (or a c-family
  equivalent) for CPs before running real workloads.
- **metrics-server TLS**: the rendered chart passes `--kubelet-insecure-tls`
  and the APIService uses `insecureSkipTLSVerify: true`. That's fine for a
  quickstart but silently accepts any kubelet cert. For production, configure
  the kubelet with a serving certificate signed by the cluster CA (search
  "kubelet serving certificate rotation" for the k8s upstream flow) and drop
  both flags.
- **CNI**: flannel is disabled in `patches/cluster.yaml`; VPC-CNI takes over
  once its DaemonSet lands.
- **Cloud provider**: kube-apiserver no longer accepts `--cloud-provider` on
  1.31+, and kubelet dropped it in 1.29+. Only controller-manager is told to
  defer to the external CCM.
- **Install disk**: intentionally not pinned in the node patches — the AWS
  provider picks the correct block device based on instance family (xvda on
  Xen, nvme0n1 on Nitro).
- **ECR pull**: `patches/cluster.yaml` wires the kubelet credential provider
  for `*.dkr.ecr.*.amazonaws.com`, so IAM-authorized pulls work without
  imagePullSecrets.
