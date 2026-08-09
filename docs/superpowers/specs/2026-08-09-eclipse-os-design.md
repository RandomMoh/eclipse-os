# Eclipse OS v1.0 ("Syzygy") System Design Specification

## Overview

Eclipse OS is a standalone, bootable 64-bit Linux desktop operating system built on Debian 12 (Bookworm) `amd64`. It uses an XFCE desktop environment styled with an Obsidian dark theme (`#0B0D14`) accented by Deep Neon Violet (`#8B5CF6`) and Cyber Cyan (`#06B6D4`). The OS provides a live session with OverlayFS read-write support, a dual UEFI/BIOS GRUB bootloader, native Python 3 system utilities, and an automated ISO compilation pipeline.

## System Requirements and Targets

- Target Architecture: `x86_64` (`amd64`)
- Boot Targets: Dual UEFI (`x86_64-efi`) and Legacy BIOS (`i386-pc`)
- Base Distribution: Debian 12 (Bookworm) minimal base
- Desktop Environment: XFCE 4.18 (GTK3) with custom theme, panel dock, and desktop layout
- Default Kernel: Linux 6.1 LTS kernel (`linux-image-amd64`)
- Init System: `systemd` with `live-boot`, `live-config`, and NetworkManager

## Directory Structure

```
/home/mohs/eclipse-os/
├── build/
│   ├── rootfs/
│   ├── iso_staging/
│   └── output/
├── config/
│   ├── grub/
│   │   ├── eclipse-grub-theme/
│   │   └── grub.cfg
│   ├── gtk/
│   │   └── gtk-3.0/gtk.css
│   ├── xfce/
│   │   └── xfce-perchannel-xml/
│   └── wallpaper/
├── src/
│   ├── eclipse-sysinfo
│   ├── eclipse-control
│   └── eclipse-installer
├── scripts/
│   ├── 01-bootstrap.sh
│   ├── 02-configure.sh
│   ├── 03-package-iso.sh
│   └── 04-test-qemu.sh
├── docs/
│   └── superpowers/
│       ├── specs/
│       │   └── 2026-08-09-eclipse-os-design.md
│       └── plans/
├── AGENTS.md
└── README.md
```

## Subsystem Architecture

### 1. Boot Subsystem (GRUB2 Dual Boot Catalog)

The live ISO uses a hybrid boot catalog supporting both modern UEFI and legacy BIOS systems.

- UEFI Boot Path: `EFI/BOOT/BOOTX64.EFI` generated with standalone GRUB modules (`fat`, `iso9660`, `part_gpt`, `part_msdos`, `normal`).
- BIOS Boot Path: `boot/grub/i386-pc/eltorito.img` with `biosdisk` support.
- Boot Menu Options:
  1. Eclipse OS v1.0 Live (Default)
  2. Eclipse OS Direct Installer
  3. Eclipse OS Safe Graphics (`nomodeset`)

### 2. Desktop Environment and Aesthetics

- Dark Theme: Custom GTK3 theme named `Eclipse-Dark` with `#0B0D14` background, `#8B5CF6` primary accents, `#06B6D4` secondary accents, and dark window decorations.
- Panel Layout: Top status bar displaying workspace pager, window titles, CPU/RAM meters, system tray, and clock. Bottom dock panel with auto-hide and centered launchers.
- Desktop Configuration: Automated provisioning of `xfconf` XML files during image generation to set theme, desktop background, panel launchers, and terminal profiles.

### 3. Native Python 3 System Utilities

- `eclipse-sysinfo`: Terminal utility built with Python 3 and `rich`. Displays system specs, kernel version, memory usage, CPU stats, and disk layout in a formatted terminal interface.
- `eclipse-control`: CLI control panel for OS configuration. Supports desktop theme switching, system diagnostic checks, and automated setup of developer tools (Docker, Node.js, Python, Git, VSCode, Neovim).
- `eclipse-installer`: Live-to-disk installation wizard. Scans block devices, partitions disk using `parted`, formats FAT32 EFI and Ext4 root partitions, syncs rootfs via `rsync`, provisions GRUB to disk, and configures user credentials in chroot.

### 4. Build Pipeline (`eclipse-os-builder`)

- `01-bootstrap.sh`: Runs `debootstrap --arch=amd64 bookworm build/rootfs http://deb.debian.org/debian/`.
- `02-configure.sh`: Binds virtual filesystems, enters chroot, installs kernel, systemd, XFCE4, desktop utilities, copies theme files, wallpaper, and installs native Python utilities to `/usr/local/bin`.
- `03-package-iso.sh`: Compresses rootfs into `filesystem.squashfs` with `mksquashfs`, stages ISO filesystem hierarchy in `build/iso_staging`, and runs `xorriso` / `grub-mkrescue` to build `build/output/eclipse-os-v1.0-x86_64.iso`.
- `04-test-qemu.sh`: Launches QEMU (`qemu-system-x86_64`) with KVM acceleration, 4GB RAM, 4 CPU cores, and OVMF UEFI bios to test the output ISO.
