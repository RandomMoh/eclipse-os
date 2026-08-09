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

# Determine project root dynamically
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"

# Validate that ROOTFS exists and contains a valid Linux root hierarchy
if [[ ! -d "$ROOTFS" ]] || [[ ! -d "$ROOTFS/boot" ]] || [[ ! -d "$ROOTFS/etc" ]]; then
    echo -e "${RED}Error: Valid rootfs directory not found at ${ROOTFS}${RESET}" >&2
    echo -e "${YELLOW}Please run scripts/01-bootstrap.sh and scripts/02-configure.sh first.${RESET}" >&2
    exit 1
fi

# Setup ISO staging structure
ISO_STAGING="${PROJECT_ROOT}/build/iso_staging"
OUTPUT_DIR="${PROJECT_ROOT}/build/output"

echo -e "${BLUE}[+] Creating ISO staging directory structure...${RESET}"
rm -rf "$ISO_STAGING"
mkdir -p "$ISO_STAGING/live"
mkdir -p "$ISO_STAGING/boot/grub"
mkdir -p "$ISO_STAGING/boot/grub/themes"
mkdir -p "$ISO_STAGING/EFI/BOOT"
mkdir -p "$OUTPUT_DIR"

# Ensure virtual filesystems inside rootfs are unmounted before compression
umount -l "$ROOTFS/dev/pts" "$ROOTFS/dev" "$ROOTFS/proc" "$ROOTFS/sys" 2>/dev/null || true

# Recreate empty required system mountpoint directories for init and live-boot
rm -rf "$ROOTFS/proc/"* "$ROOTFS/sys/"* "$ROOTFS/dev/"* "$ROOTFS/run/"* "$ROOTFS/tmp/"* 2>/dev/null || true
mkdir -p "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/dev" "$ROOTFS/run" "$ROOTFS/tmp"
chmod 1777 "$ROOTFS/tmp"

# Compress rootfs to SquashFS
echo -e "${YELLOW}[*] Compressing rootfs into SquashFS...${RESET}"
rm -f "$ISO_STAGING/live/filesystem.squashfs"
mksquashfs "$ROOTFS" "$ISO_STAGING/live/filesystem.squashfs" \
    -comp xz \
    -b 1M \
    -no-recovery \
    -always-use-fragments \
    -noappend

# Copy Kernel and Initramfs
echo -e "${BLUE}[+] Copying latest kernel and initramfs...${RESET}"
VMLINUZ_FILE=$(ls -1t "$ROOTFS/boot/vmlinuz-"* 2>/dev/null | head -n 1 || true)
INITRD_FILE=$(ls -1t "$ROOTFS/boot/initrd.img-"* 2>/dev/null | head -n 1 || true)

if [[ -z "$VMLINUZ_FILE" || ! -f "$VMLINUZ_FILE" ]]; then
    echo -e "${RED}Error: No vmlinuz kernel found in ${ROOTFS}/boot/${RESET}" >&2
    exit 1
fi

if [[ -z "$INITRD_FILE" || ! -f "$INITRD_FILE" ]]; then
    echo -e "${RED}Error: No initrd.img found in ${ROOTFS}/boot/${RESET}" >&2
    exit 1
fi

cp "$VMLINUZ_FILE" "$ISO_STAGING/live/vmlinuz"
cp "$INITRD_FILE" "$ISO_STAGING/live/initrd.img"

# Copy GRUB Config and Theme
echo -e "${BLUE}[+] Copying GRUB configuration and theme...${RESET}"
if [[ -f "$PROJECT_ROOT/config/grub/grub.cfg" ]]; then
    cp "$PROJECT_ROOT/config/grub/grub.cfg" "$ISO_STAGING/boot/grub/grub.cfg"
else
    echo -e "${RED}Error: GRUB configuration not found at ${PROJECT_ROOT}/config/grub/grub.cfg${RESET}" >&2
    exit 1
fi

if [[ -d "$PROJECT_ROOT/config/grub/eclipse-grub-theme" ]]; then
    cp -r "$PROJECT_ROOT/config/grub/eclipse-grub-theme" "$ISO_STAGING/boot/grub/themes/eclipse-grub-theme"
fi

# Build EFI Bootloader
echo -e "${YELLOW}[*] Building EFI standalone bootloader (BOOTX64.EFI)...${RESET}"
if ! command -v grub-mkstandalone &>/dev/null; then
    echo -e "${RED}Error: grub-mkstandalone is not installed${RESET}" >&2
    exit 1
fi

grub-mkstandalone \
    --format=x86_64-efi \
    --output="$ISO_STAGING/EFI/BOOT/BOOTX64.EFI" \
    --locales="" \
    --fonts="" \
    "boot/grub/grub.cfg=$ISO_STAGING/boot/grub/grub.cfg"

# Build Hybrid Dual UEFI/BIOS ISO
echo -e "${YELLOW}[*] Building Hybrid Dual UEFI/BIOS ISO image...${RESET}"
ISO_OUTPUT="${OUTPUT_DIR}/eclipse-os-v1.0-x86_64.iso"

if command -v grub-mkrescue &>/dev/null; then
    grub-mkrescue -o "$ISO_OUTPUT" "$ISO_STAGING" -- -volid "ECLIPSE_OS"
elif command -v xorriso &>/dev/null; then
    xorriso -as mkisofs \
        -r -V "ECLIPSE_OS" \
        -cache-inodes \
        -J -l \
        -b boot/grub/i386-pc/eltorito.img \
        -c boot.catalog \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -o "$ISO_OUTPUT" \
        "$ISO_STAGING"
else
    echo -e "${RED}Error: Neither grub-mkrescue nor xorriso is installed${RESET}" >&2
    exit 1
fi

# Output summary showing generated ISO size and path
if [[ -f "$ISO_OUTPUT" ]]; then
    ISO_SIZE=$(du -h "$ISO_OUTPUT" | cut -f1)
    echo -e "${GREEN}[+] ISO packaging completed successfully!${RESET}"
    echo -e "${GREEN}[+] Output Path: ${ISO_OUTPUT}${RESET}"
    echo -e "${GREEN}[+] Output Size: ${ISO_SIZE}${RESET}"
else
    echo -e "${RED}Error: ISO creation failed, file not found at ${ISO_OUTPUT}${RESET}" >&2
    exit 1
fi
