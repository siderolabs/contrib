# Self-hosted Omni on Talos

This example shows how to [self-host Omni](https://docs.siderolabs.com/omni/infrastructure-and-extensions/self-hosted/overview) on a Talos machine (single node) as a mostly self-contained "seed" system for your Talos infrastructure. It is designed to run with only few dependencies on external services and tools:

- No additional Linux distro: runs on Talos itself (managed with `talosctl`)
- No ingress controller required: uses `hostPort`s only
- No external identity provider required: uses a local [Dex IdP](https://dexidp.io/) with just a list of static users (especially useful if you want your regular IdP hosted on Omni-managed infrastructure, in turn)
  - Dex can still [connect upstream IdPs](https://dexidp.io/docs/connectors/) but provide static users as fallback
- Deployed as simple inline manifests from the Talos spec

## Prerequsites

- A machine with [Talos installed via `talosctl`](https://docs.siderolabs.com/talos/latest/getting-started/getting-started) or ready for Talos installation
- Two dedicated IPs (`${OMNI_IP}` and `${OMNI_AUTH_IP}`) and DNS records (`${OMNI_DOMAIN}` and `auth.${OMNI_DOMAIN}`) for Omni and the auth endpoint
- TLS server certificates for `${OMNI_DOMAIN}` and `auth.${OMNI_DOMAIN}`
- Access to Talos image factory (example uses public instance; can also be [self-hosted](https://github.com/siderolabs/image-factory))
- Access to container registries (example uses public registries; can also be a [self-hosted proxy](https://docs.siderolabs.com/talos/latest/configure-your-talos-cluster/images-container-runtime/pull-through-cache), or the [baked-in image cache](https://docs.siderolabs.com/talos/latest/configure-your-talos-cluster/images-container-runtime/image-cache))

## Networking

In this example we use two dedicated IPs for Omni and Dex, so that both can be exposed on port 443. This avoids the additional complexity and failure point of a reverse proxy service.

You might as well host everything at the node IP and just expose Dex on a non-standard port, or claim even more dedicated IPs for Omni's SideroLink API and/or Kubernetes proxy endpoints.

## Usage

Adjust the patch files to your environment and apply the configuration patches to the target machine or install Talos with these patches included right away.

### Network configuration

There are two additional IPs (for Omni and Dex) added to the machine's interface. Make sure you select the right interface (via either `interface` or `deviceSelector`) and change the number of CIDR mask bits according to your subnet.

### Storage layout

In the given example, a 10GB dedicated `omni-data` partition is added to the system disk. This can only be applied during initial machine setup, unless you reserved system disk space beforehand. You may need to adjust the disk selector of the `omni-data` UserVolume, if the system install disk is not given by a disk-id symlink (`/dev/disk/by-*`).

Of course you can also create this partition on a different disk, or just keep Omni application data on the EPHEMERAL partition.

### Omni and Dex's Kubernetes manifests

The application resources are defined as `inlineManifests` in the machine configuration. Note that Talos does not apply changes to those without a reboot. However, you can reapply those using `yq` and `kubectl`.

```sh
yq -r '.cluster.inlineManifests[].contents | "---\n\(.)"' omni-app-manifests.yaml | kubectl apply --filename=/dev/stdin
```

### User management

The usage of Dex allows us to maintain a list of users directly within the Dex configuration file (secret `dex-config` in `.cluster.inlineManifests`). To add a user to Omni, just add an entry to this list, in the following form:

```yaml
staticPasswords:
  - username: user42
    email: user42@example.org
    # htpasswd -BnC 15 ${USERNAME} | cut --delimiter=: --fields=1 --complement
    hash: "$2y$15$5wZY..."
    # uuidgen
    userID: 01234567-89ab-cdef-0123456789abcdef
```

Additionally, make sure that the following conditions are met:

- The Dex pod does not restart automatically after this change, so trigger a manual restart after the manifest has been applied
- Due to Omni's limited OIDC support (at the time of writing), users must also be manually added with their email address by an existing Omni administrator in the UI
- At first install, one of these users must be added as initial user to the Omni command-line arguments (see `OMNI_INITIAL_USER_EMAIL` below)

Alternatively, you can [connect an upstream IdP to Dex](https://dexidp.io/docs/connectors/) and use the local users as fallback, or skip the deployment of Dex and connect Omni directly to an external SAML/OIDC provider.

### Variables

Below is a list of all variables in the patch files. Replace these with values appropriate to your setup and infrastructure.

| Variable name | Description |
|-|-|
|`MACHINE_NET_IP`| Primary IP address of the machine, also Kubernetes node IP |
|`MACHINE_EPHEMERAL_PARTITION_SIZE`| Size of the EPHEMERAL partition on system disk; leave enough space for the `omni-data` partition |
|`MACHINE_INSTALL_DISK`| Probably the same value that you set in `.machine.install.disk`; used in the `omni-data` partition's disk selector |
|`OMNI_IP`| IP address where Omni is exposed |
|`OMNI_AUTH_IP`| IP address where Dex is exposed |
|`OMNI_DOMAIN`| Domain name that points to `OMNI_IP` |
|`OMNI_INITIAL_USER_EMAIL`| Email address of the user that logs in first |
|`OMNI_AUTH_CLIENT_SECRET`| OAuth client secret for authentication (set an arbitrary string) |
|`OMNI_AUTH_CRT`| PEM server certificate for Dex (domain is `auth.${OMNI_DOMAIN}`) in base64 encoding |
|`OMNI_AUTH_KEY`| PEM server certificate private key for Dex in base64 encoding |
|`OMNI_CRT`| PEM server certificate for Omni in base64 encoding |
|`OMNI_KEY`| PEM server certificate private key for Omni in base64 encoding |
|`OMNI_ASC`| [Omni encryption key](https://docs.siderolabs.com/omni/infrastructure-and-extensions/self-hosted/deploy-omni-on-prem#create-etcd-encryption-key) in base64 encoding |
|`OMNI_NAME`| Human-readable name for this Omni instance |
|`OMNI_ACCOUNT_ID`| Account ID (create with `uuidgen` command) |
|`OMNI_IMAGE_TAG`| Tag of the Omni container image to be used |
|`DEX_IMAGE_TAG`| Tag of the Dex container image to be used |
