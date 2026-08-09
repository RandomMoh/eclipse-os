#!/usr/bin/env bash
set -euo pipefail

# Color helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Check root privileges
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: Must be run as root${RESET}" >&2
    exit 1
fi

# Ensure debootstrap is installed on host system
if ! command -v debootstrap &> /dev/null; then
    echo -e "${RED}Error: debootstrap is not installed on host system${RESET}" >&2
    exit 1
fi

# Resolve workspace base path dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"

echo -e "${BLUE}[+] Starting Debian 12 (Bookworm) base rootfs bootstrap...${RESET}"
echo -e "${BLUE}[+] Target directory: ${ROOTFS_DIR}${RESET}"

# Create build/rootfs directory if it does not exist
mkdir -p "$ROOTFS_DIR"

# Run debootstrap
echo -e "${YELLOW}[*] Running debootstrap (arch: amd64, variant: minbase)...${RESET}"
debootstrap --arch=amd64 --variant=minbase bookworm "$ROOTFS_DIR" http://deb.debian.org/debian/

# Post-bootstrap cleanup inside rootfs
echo -e "${YELLOW}[*] Cleaning up package cache and downloaded archives...${RESET}"
chroot "$ROOTFS_DIR" apt-get clean
rm -rf "${ROOTFS_DIR}/var/lib/apt/lists/"*
rm -rf "${ROOTFS_DIR}/var/cache/apt/archives/"*.deb

echo -e "${GREEN}[+] Base rootfs bootstrap completed successfully!${RESET}"
