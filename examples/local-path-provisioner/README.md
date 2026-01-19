# Local Path Provisioner with Talos Linux

This example demonstrates how to deploy Local Path Provisioner on Talos Linux v1.12 using `extraManifests`.

## Overview

This example configures a local storage provisioner for Kubernetes clusters running on Talos Linux. It uses the [Rancher Local Path Provisioner](https://github.com/rancher/local-path-provisioner) to dynamically provision persistent volumes using local storage.

## Components

### 1. User Volume Configuration (`uservolume.patch.yaml`)

Defines a user volume that reserves space on the system disk for local storage:

- **Name**: `local-path`
- **Disk Selection**: Uses the system disk
- **Size**: 1GB minimum and maximum

### 2. Kustomize Configuration (`kustomize/kustomization.yaml`)

Deploys and configures the Local Path Provisioner with the following customizations:

- **Base Resource**: Local Path Provisioner v0.0.34 from the official repository
- **Storage Path**: Configures `/var/local-path` as the storage location
- **Default Storage Class**: Sets the `local-path` StorageClass as the default
- **Security**: Configures the namespace with privileged pod security enforcement

### 3. Rendered Manifest (`kustomize/local-path-provisioner.yaml`)

Pre-rendered manifest file generated from the kustomization. This is required because `extraManifests` does not support kustomization files directly.

## Usage with Talos Linux v1.12

### Generating Talos Configuration

Generate a Talos configuration that includes the Local Path Provisioner setup:

```bash
talosctl gen config my-cluster https://192.168.1.100:6443 \
  --config-patch @uservolume.patch.yaml \
  --config-patch '[{"op": "add", "path": "/cluster/extraManifests", "value": ["https://raw.githubusercontent.com/siderolabs/contrib/main/examples/local-path-provisioner/kustomize/local-path-provisioner.yaml"]}]'
```

Replace `my-cluster` with your cluster name and `https://192.168.1.100:6443` with your control plane endpoint.

### Manual Configuration

Alternatively, you can manually add the configuration to your existing machine configuration:

Add the user volume patch:

```yaml
machine:
  patches:
    - '@uservolume.patch.yaml'
```

Add the extra manifest:

```yaml
cluster:
  extraManifests:
    - https://raw.githubusercontent.com/siderolabs/contrib/main/examples/local-path-provisioner/kustomize/local-path-provisioner.yaml
```

## How It Works

1. The `uservolume.patch.yaml` creates a 1GB user volume on the system disk at `/var/local-path`
2. The Local Path Provisioner is deployed via `extraManifests` during cluster bootstrap
3. The provisioner uses the pre-configured user volume to create persistent volumes dynamically
4. The `local-path` StorageClass is set as the default, allowing automatic volume provisioning for PVCs

## Requirements

- Talos Linux v1.12 or later
- Sufficient disk space on the system disk for the user volume

## Regenerating the Manifest

If you modify the kustomization configuration, regenerate the manifest file:

```bash
kustomize build kustomize > kustomize/local-path-provisioner.yaml
```