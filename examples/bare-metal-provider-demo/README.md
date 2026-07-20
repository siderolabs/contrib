# Bare metal infra provider demo

Runs [omni-infra-provider-bare-metal](https://github.com/siderolabs/omni-infra-provider-bare-metal)
against libvirt VMs standing in for physical servers, with
[sushy-tools](https://docs.openstack.org/sushy/latest/) as their BMCs over Redfish
and local pull-through registry caches.

Ten UEFI VMs PXE boot from the provider, register with Omni, and are power-managed
over Redfish. `cluster:up` then provisions a 3 control plane / 7 worker cluster.

Rationale for the non-obvious choices lives in comments in `Taskfile.yml` and
`templates/*.template` — read those before changing anything.

## Requirements

- libvirt + KVM, membership in the `libvirt` group (else set `VIRSH="sudo virsh -c qemu:///system"`)
- `docker` (with compose), `task`, `envsubst`, `qemu-img`
- `omnictl` with a valid `OMNICONFIG`
- OVMF. Defaults are Arch paths; override `OVMF_DIR`/`OVMF_CODE`/`OVMF_VARS` elsewhere
- ~40 GB RAM for the default 10×4 GB VMs

## Usage

```bash
task infra:up                  # network, registries, VMs, sushy emulators, provider
task provider:logs
task machines:bmc-configure    # once machines register with agents running

task cluster:up                # render + validate + sync template, fetch kubeconfig
task cluster:status
task cluster:down

task infra:status
task infra:down
```

`task --list` for the rest: `net:*`, `vms:*`, `sushy:*`, `registries:*`,
`provider:*`, `machines:*`.

`infra:*` owns the local lab, `cluster:*` the Omni cluster on top. **Run
`cluster:down` before `infra:down`** — the latter deletes the machines' links,
which breaks a live cluster rather than deleting it cleanly.

`infra:down` also removes the infra provider and its credentials from Omni, not
just local state.

## Layout

| path | purpose |
| --- | --- |
| `Taskfile.yml` | all vars, tasks, and the reasoning behind them |
| `scripts/vm-env.sh` | derives every per-VM name/address/UUID from an index |
| `templates/*.template` | `envsubst`-rendered into `_out/rendered/` |
| `docker-compose.yaml` | registry caches, bound to the gateway IP |

Addressing, derived from `LIBVIRT_SUBNET_PREFIX` (default `192.168.234`):

| address | role |
| --- | --- |
| `.1` | bridge, gateway, provider, registry caches (ports 5000–5006) |
| `.11`–`.20` | one sushy emulator per VM (bridge IP aliases) |
| `.101`–`.110` | VMs, via DHCP reservation |
| `.150`–`.199` | spare DHCP pool |

## Gotchas

- **One sushy per VM, distinguished by IP.** The provider takes `systems[0]` and
  reads the Redfish port from a global flag, so emulators can share neither an
  instance nor a port.
- **No DHCP proxy.** libvirt's dnsmasq owns port 67 and hands out `snp.efi`
  itself; the provider's iPXE binaries already embed its endpoint.
- **BMC config is user-supplied.** Write `InfraMachineBMCConfigs` (namespace
  `default`), not the controller-owned `BMCConfigs`. Only consumed once a
  machine's agent is accessible, hence the separate `machines:bmc-configure` step.
- **Deallocated machines don't power off immediately.** They stay up to be wiped,
  then wait out `--min-reboot-interval` (15m).
- **A machine reporting an unfamiliar Talos version** is booted into the metal
  agent, not running that Talos. The provider forwards iPXE to the image factory
  to boot the agent, so the version is `--agent-mode-talos-version` (default
  `v1.13.0`).
- **Agent boot needs internet.** The agent's kernel and initramfs come from
  `pxe.factory.talos.dev` on every first boot. The registry caches do not cover
  this: they mirror image pulls, not the factory's PXE endpoints. Point
  `--image-factory-pxe-base-url` at a self-hosted factory if you need the demo to
  run without upstream access.

## Status

Verified live: PXE boot, registration, Redfish power management.
Not yet exercised: `cluster:up`, the registry mirror patch, and the one-shot PXE
boot override.
