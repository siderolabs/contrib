# shellcheck shell=sh
# Derives all per-VM values from a single index, so that every task agrees on
# names, addresses and UUIDs without keeping a state file around.
#
# usage: . scripts/vm-env.sh <index>
#
# Expects the Taskfile vars to already be exported into the environment.

set -eu

VM_INDEX="$1"

VM_NAME="${VM_NAME_PREFIX}-$(printf '%02d' "${VM_INDEX}")"

# Domain UUID == SMBIOS UUID == Omni machine id == sushy Redfish System id.
VM_UUID="$(printf '4d7a0000-0000-4000-8000-%012d' "${VM_INDEX}")"

# 52:54:00 is the QEMU OUI.
VM_MAC="$(printf '52:54:00:bd:00:%02x' "${VM_INDEX}")"

# .1 gateway + provider, .11+ sushy emulators, .101+ VMs, .150-.199 DHCP pool.
VM_IP="${LIBVIRT_SUBNET_PREFIX}.$((100 + VM_INDEX))"
SUSHY_IP="${LIBVIRT_SUBNET_PREFIX}.$((10 + VM_INDEX))"

SUSHY_CONTAINER="${SUSHY_CONTAINER_PREFIX}-$(printf '%02d' "${VM_INDEX}")"
SUSHY_CONF="${RENDER_DIR}/sushy-${VM_NAME}.conf"

VM_DISK_PATH="${LIBVIRT_IMAGES_DIR}/${VM_NAME}.qcow2"
VM_NVRAM_PATH="${LIBVIRT_NVRAM_DIR}/${VM_NAME}_VARS.fd"
VM_SERIAL_LOG="${VM_SERIAL_LOG_DIR}/${VM_NAME}-serial.log"

export VM_INDEX VM_NAME VM_UUID VM_MAC VM_IP
export SUSHY_IP SUSHY_CONTAINER SUSHY_CONF
export VM_DISK_PATH VM_NVRAM_PATH VM_SERIAL_LOG
