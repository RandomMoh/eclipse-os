#!/usr/bin/env bash
set -euo pipefail

# Color helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Determine project root dynamically
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO_PATH="$PROJECT_ROOT/build/output/eclipse-os-v1.0-x86_64.iso"

# Check if ISO file exists
if [[ ! -f "$ISO_PATH" ]]; then
    echo -e "${RED}Error: ISO file not found at ${ISO_PATH}${RESET}" >&2
    echo -e "${YELLOW}Please run 01-bootstrap.sh, 02-configure.sh, and 03-package-iso.sh first.${RESET}" >&2
    exit 1
fi

# Check if qemu-system-x86_64 is installed
if ! command -v qemu-system-x86_64 &>/dev/null; then
    echo -e "${RED}Error: qemu-system-x86_64 is not installed.${RESET}" >&2
    exit 1
fi

# Determine KVM availability
if [[ -e /dev/kvm && -r /dev/kvm && -w /dev/kvm ]]; then
    KVM_ARG="-enable-kvm"
    echo -e "${GREEN}[+] KVM acceleration enabled.${RESET}"
else
    KVM_ARG=""
    echo -e "${YELLOW}[!] KVM acceleration not available, running in software emulation mode.${RESET}"
fi

# Launch QEMU
echo -e "${BLUE}[+] Launching Eclipse OS inside QEMU...${RESET}"
qemu-system-x86_64 $KVM_ARG -m 4096 -smp 4 -vga virtio -display gtk -cdrom "$ISO_PATH" -boot d
