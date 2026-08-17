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

# Validate that ROOTFS exists and contains a valid Linux root hierarchy with KDE Plasma installed
if [[ ! -d "$ROOTFS" ]] || [[ ! -d "$ROOTFS/boot" ]] || [[ ! -d "$ROOTFS/etc" ]]; then
    echo -e "${RED}Error: Valid rootfs directory not found at ${ROOTFS}${RESET}" >&2
    echo -e "${YELLOW}Please run scripts/01-bootstrap.sh and scripts/02-configure.sh first.${RESET}" >&2
    exit 1
fi

if [[ ! -f "$ROOTFS/usr/bin/plasmashell" ]] || [[ ! -f "$ROOTFS/usr/bin/sddm" ]]; then
    echo -e "${RED}Error: KDE Plasma Desktop Environment is NOT installed in ${ROOTFS}!${RESET}" >&2
    echo -e "${RED}The 02-configure.sh package installation step failed or was aborted prematurely.${RESET}" >&2
    echo -e "${YELLOW}Please inspect the output of scripts/02-configure.sh and resolve any package errors.${RESET}" >&2
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

# Compressing the rootfs with mounted virtual filesystems (like /proc and /dev) will cause mksquashfs to package dynamic kernel structures and hang the build. They must be unmounted first.
umount -l "$ROOTFS/dev/pts" 2>/dev/null || true
umount -l "$ROOTFS/dev" 2>/dev/null || true
umount -l "$ROOTFS/proc" 2>/dev/null || true
umount -l "$ROOTFS/sys" 2>/dev/null || true

# live-boot expects /proc, /sys, /dev, and /run to exist as empty directories in the squashfs so it can mount them during the boot sequence.
rm -rf "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/run/"* "$ROOTFS/tmp/"* 2>/dev/null || true
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

# The EFI bootloader is a standalone binary with our grub.cfg baked in.
# grub-mkstandalone wraps the config inside a memdisk so the EFI firmware
# can find it without needing a separate filesystem partition.
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

# Pack the EFI binary into a FAT12/16 image that xorriso can use as
# an El Torito EFI boot catalog entry. Without this image, UEFI
# firmware has no way to locate the bootloader on the ISO.
echo -e "${YELLOW}[*] Creating EFI boot image (efi.img)...${RESET}"
EFI_IMG="$ISO_STAGING/boot/grub/efi.img"
dd if=/dev/zero of="$EFI_IMG" bs=1M count=4
mkfs.vfat "$EFI_IMG"
mmd -i "$EFI_IMG" ::EFI
mmd -i "$EFI_IMG" ::EFI/BOOT
mcopy -i "$EFI_IMG" "$ISO_STAGING/EFI/BOOT/BOOTX64.EFI" ::EFI/BOOT/BOOTX64.EFI

# For BIOS boot, grub needs an i386-pc core image with the correct
# module prefix pointing to /boot/grub/i386-pc on the ISO filesystem.
# This avoids the "invalid magic number" error caused by grub-mkrescue
# embedding modules with a mismatched prefix path.
echo -e "${YELLOW}[*] Building BIOS boot image (core.img + eltorito.img)...${RESET}"
BIOS_MODS_DIR="/usr/lib/grub/i386-pc"
if [[ ! -d "$BIOS_MODS_DIR" ]]; then
    echo -e "${YELLOW}[!] i386-pc GRUB modules not found, BIOS boot will be skipped (EFI-only ISO)${RESET}"
    BIOS_BOOT=false
else
    BIOS_BOOT=true
    mkdir -p "$ISO_STAGING/boot/grub/i386-pc"
    cp "$BIOS_MODS_DIR"/*.mod "$ISO_STAGING/boot/grub/i386-pc/"
    cp "$BIOS_MODS_DIR"/*.lst "$ISO_STAGING/boot/grub/i386-pc/" 2>/dev/null || true

    grub-mkimage \
        -O i386-pc \
        -o "$ISO_STAGING/boot/grub/i386-pc/core.img" \
        -p /boot/grub \
        --config="$ISO_STAGING/boot/grub/grub.cfg" \
        biosdisk iso9660 linux normal search configfile part_gpt part_msdos fat ext2 all_video gfxterm font

    cat "$BIOS_MODS_DIR/cdboot.img" "$ISO_STAGING/boot/grub/i386-pc/core.img" \
        > "$ISO_STAGING/boot/grub/i386-pc/eltorito.img"
fi

echo -e "${YELLOW}[*] Building Hybrid UEFI/BIOS ISO image...${RESET}"
ISO_OUTPUT="${OUTPUT_DIR}/eclipse-os-v1.0-x86_64.iso"

if $BIOS_BOOT; then
    xorriso -as mkisofs \
        -r -V "ECLIPSE_OS" \
        -J -joliet-long \
        -b boot/grub/i386-pc/eltorito.img \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        --grub2-boot-info \
        --grub2-mbr "$BIOS_MODS_DIR/boot_hybrid.img" \
        -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        -o "$ISO_OUTPUT" \
        "$ISO_STAGING"
else
    xorriso -as mkisofs \
        -r -V "ECLIPSE_OS" \
        -J -joliet-long \
        -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        -o "$ISO_OUTPUT" \
        "$ISO_STAGING"
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
