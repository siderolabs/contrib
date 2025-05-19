# Siderolabs self-hosted imagefactory example

This code runs [sidero imagefactory](https://github.com/siderolabs/image-factory) in [docker compose](https://docs.docker.com/compose/).

It also deploys a few companion components:
* upstream `ghcr.io` [registry](https://distribution.github.io/distribution/) [mirror](https://distribution.github.io/distribution/recipes/mirror/) to avoid potential upstream rate limitings and speed up builds by caching previously pulled image layers
* a script that applies prepared `talos` [image schematics](https://www.talos.dev/v1.8/learn-more/image-factory/#schematics)
* a [registry](https://distribution.github.io/distribution/) used as storage and cache for the generated images

# how to use

tested with `talos` version `v1.8.1`, via [iPXE boot](https://www.talos.dev/v1.8/talos-guides/install/bare-metal-platforms/pxe/) and directly applying generated images to disk via `hcloud` (use it's [packer](https://developer.hashicorp.com/packer/integrations/hetznercloud/hcloud) integration and point [this](https://github.com/siderolabs/contrib/blob/9cd1e1c9d2469b77d2278eb07e7f61c09bb32d40/examples/terraform/hcloud/packer/hcloud_talosimage.pkr.hcl#L18) URL to your `imagefactory` instance).

## preparation

some preparation is required.

### signing keys
see [official docs](https://github.com/siderolabs/image-factory?tab=readme-ov-file#development).

```shell
mkdir -pv keys
openssl ecparam -name prime256v1 -genkey -noout -out keys/cache-signing-key.key
```

### schematics

Refer to the [official docs](https://www.talos.dev/v1.8/learn-more/image-factory/#schematics) on how to create these.
The [script](./scripts/sync-schematics.sh) will find and apply all files in `schematics/*.yaml`.

Example:
```yaml
# schematics/example.yaml
customization:
  extraKernelArgs:
    - gfxmode=1280x1024
    - console=ttyS0,115200
    - net.ifnames=0
    - talos.platform=metal
  systemExtensions:
    officialExtensions:
      - siderolabs/amd-ucode
      - siderolabs/fuse3
      - siderolabs/intel-ucode
      - siderolabs/iscsi-tools
      - siderolabs/qemu-guest-agent
      - siderolabs/tailscale
      - siderolabs/util-linux-tools
  meta:
    - key: 12
      value: |
        machineLabels:
          env: prod
          type: controlplane
```

### environment variables

copy the [docker compose env file](https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/#env-file) and adjust the example values.

```shell
cp env.example .env
vim .env
```

Adjust all domains and `EXT_IP` to where you want to expose your `imagefactory` instance.
This is relevant for payloads sent to `iPXE` clients and URLs generated in the UI.

## run

after preparation is done, run `docker compose up -d`.

# miscellaneous & troubleshooting

This is a community contribution so expect no official support. 
Some trouble I ran into:

## TLS

The configuration used does *not* deploy TLS, so you should put this behind something like a reverse proxy that does.

## connection timeouts

Image generation can take some time, so clients might have to increase their connection timeout limits. If images are cached, [TTFB](https://en.wikipedia.org/wiki/Time_to_first_byte) is very short, if not `TTFB` can take up to several minutes.

## iPXE and https

If you want to [iPXE](https://ipxe.org)-boot from this via `https`, keep in mind that by default `iPXE` does *not* support `https` and you need to compile your own, enabling [this](https://ipxe.org/buildcfg/download_proto_https) flag. This is a pitfall for reverse proxies that automatically redirect plaintext `http` requests to `https`.

## URLs not working

There is a tiny problem in the `imagefactory` frontend: The URLs generated contain the external domain used and it is duplicated for some reason. This is particularly mean because the URL _visible_ in the UI looks correct, but the `HTML` `href` is not.
Make sure to sanitize the URL before use, the resulting URL works as expected. Not sure yet as to _why_ this happens (misconfiguration or might be a bug).
Querying the `API` seems to return the correct URL.

## registry resource consumption

* When building a large number of images, make sure to provide sufficient storage to the `registry` container and monitor `docker volumes` as it grows in size quite rapidly.
* the image generation process is compute heavy and can take some time, depending on the compute power available.
