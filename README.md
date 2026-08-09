# Eclipse OS v1.0 ("Syzygy")

Eclipse OS is a custom, bootable 64-bit Linux desktop operating system built on Debian 12 (Bookworm) `amd64`. It combines an XFCE desktop environment with a dark aesthetic, custom GRUB bootloader graphics, native Python 3 administration tools, and an automated ISO build toolchain.

## Features

- **Base System**: Debian 12 (Bookworm) `amd64` core with Linux 6.1 LTS kernel, `systemd`, NetworkManager, and OverlayFS read-write live boot.
- **Boot Support**: Dual UEFI (`x86_64-efi`) and Legacy BIOS (`i386-pc`) boot targets using GRUB2.
- **Desktop Environment**: XFCE 4.18 desktop styled with the `Eclipse-Dark` GTK theme (Obsidian `#0B0D14` background with Deep Neon Violet `#8B5CF6` and Cyber Cyan `#06B6D4` accents).
- **Custom Utilities**:
  - `eclipse-sysinfo`: System information and resource monitor written in Python 3 using `rich`.
  - `eclipse-control`: Control panel CLI for desktop tweaks, theme switching, and developer tool installation.
  - `eclipse-installer`: Live-to-disk installation wizard with automatic partitioning and GRUB bootloader setup.
- **Automated Toolchain**: Four modular scripts in `scripts/` to bootstrap, configure, package, and test the operating system inside QEMU.

## Repository Layout

```
├── build/                 # ISO build workspace (rootfs chroot, staging, output)
├── config/                # GRUB themes, GTK theme, XFCE desktop configs, wallpaper
├── src/                   # Python 3 system utilities (sysinfo, control, installer)
├── scripts/               # ISO build pipeline (bootstrap, configure, package, test)
├── docs/                  # System design specs and execution plans
├── AGENTS.md              # Documentation for AI agent contributors
└── README.md
```

## Quick Start

### Prerequisites

You need a 64-bit Linux host (Debian, Ubuntu, Linux Mint, or Arch) with superuser privileges and the following build dependencies installed:

```bash
sudo apt update
sudo apt install -y debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools qemu-system-x86_64 python3 python3-pip
```

### Building the ISO

1. Clone the repository:
   ```bash
   git clone https://github.com/RandomMoh/eclipse-os.git
   cd eclipse-os
   ```

2. Bootstrap the base system:
   ```bash
   sudo bash scripts/01-bootstrap.sh
   ```

3. Configure the desktop environment and system utilities:
   ```bash
   sudo bash scripts/02-configure.sh
   ```

4. Package the bootable ISO image:
   ```bash
   sudo bash scripts/03-package-iso.sh
   ```

   The generated ISO image will be stored at `build/output/eclipse-os-v1.0-x86_64.iso`.

### Running in QEMU

Test the compiled ISO image inside QEMU with KVM acceleration:

```bash
bash scripts/04-test-qemu.sh
```

## License

MIT License. See project files for details.
