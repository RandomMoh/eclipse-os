# Eclipse OS v1.0 ("Syzygy") Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a bootable 64-bit Linux desktop operating system named Eclipse OS v1.0 ("Syzygy") with custom Obsidian/Neon dark GTK aesthetics, GRUB graphics, native Python 3 utilities, and an automated ISO build toolchain.

**Architecture:** Debian 12 (Bookworm) `amd64` core, Linux 6.1 LTS kernel with OverlayFS read-write live boot support, dual UEFI (`x86_64-efi`) and BIOS (`i386-pc`) boot targets using GRUB2, XFCE 4.18 desktop environment, and Python 3 TUI utilities (`rich`).

**Tech Stack:** Debian 12 (Bookworm), XFCE4, GTK3, GRUB2, Python 3 (`rich`), `debootstrap`, `squashfs-tools`, `xorriso`, QEMU/KVM.

## Global Constraints

- Absolute paths must resolve within `/home/mohs/eclipse-os`.
- Use concise commit messages (3-4 words, e.g. `feat: add sysinfo utility`).
- Do not use AI jargon words or em dashes in documentation or script headers.
- Every bash script in `scripts/` must begin with `#!/usr/bin/env bash` and `set -euo pipefail`.
- All Python scripts in `src/` must have valid Python syntax and executable permissions (`chmod +x`).

---

### Task 1: Desktop Assets, GTK3 Theme, and GRUB Bootloader Configuration

**Files:**
- Create: `config/gtk/gtk-3.0/gtk.css`
- Create: `config/gtk/index.theme`
- Create: `config/grub/grub.cfg`
- Create: `config/grub/eclipse-grub-theme/theme.txt`
- Create: `config/xfce/xfce-perchannel-xml/xfce4-panel.xml`
- Create: `config/xfce/xfce-perchannel-xml/xfwm4.xml`
- Create: `config/wallpaper/eclipse-wallpaper.png`

**Interfaces:**
- Consumed by: `scripts/02-configure.sh` (copies theme, wallpaper, and desktop configs into rootfs) and `scripts/03-package-iso.sh` (uses GRUB config and theme for ISO compilation).

- [ ] **Step 1: Create GTK3 dark theme (`Eclipse-Dark`)**

Write `config/gtk/gtk-3.0/gtk.css` defining Obsidian dark `#0B0D14` window backgrounds, `#121520` panel surfaces, `#8B5CF6` primary neon violet highlights, and `#06B6D4` cyan accent colors.

- [ ] **Step 2: Create index.theme file**

Write `config/gtk/index.theme` declaring the theme name `Eclipse-Dark` and GTK-3.0 compatibility.

- [ ] **Step 3: Create GRUB bootloader configuration and theme**

Write `config/grub/grub.cfg` with menu entries for Live Session, Direct Disk Installer, and Safe Graphics (`nomodeset`). Write `config/grub/eclipse-grub-theme/theme.txt` defining custom colors and font sizes.

- [ ] **Step 4: Create XFCE panel and desktop configuration XML files**

Write `config/xfce/xfce-perchannel-xml/xfce4-panel.xml` and `xfwm4.xml` configuring the top bar status panel, auto-hiding launcher dock, window manager theme, and default terminal profile.

- [ ] **Step 5: Generate custom desktop wallpaper asset**

Create a Python script using PIL/ImageDraw or SVG rendering to generate `config/wallpaper/eclipse-wallpaper.png` featuring a dark solar eclipse graphic with neon violet and cyan glow.

- [ ] **Step 6: Commit changes**

```bash
git add config/
git commit -m "feat: add desktop themes"
git push origin main
```

---

### Task 2: Native Python 3 System Utilities

**Files:**
- Create: `src/eclipse-sysinfo`
- Create: `src/eclipse-control`
- Create: `src/eclipse-installer`

**Interfaces:**
- Consumes: Python 3 standard library (`os`, `sys`, `subprocess`, `platform`, `psutil`, `shutil`), `rich` terminal library.
- Produces: System utility executables copied to `/usr/local/bin/` inside the rootfs.

- [ ] **Step 1: Create `eclipse-sysinfo` utility**

Write `src/eclipse-sysinfo` using Python 3 and `rich`. Implement system metrics collection (kernel, uptime, CPU model, RAM usage bar, disk usage bar, active network interfaces) formatted alongside an ASCII logo for Eclipse OS. Make executable (`chmod +x`).

- [ ] **Step 2: Create `eclipse-control` utility**

Write `src/eclipse-control` using Python 3 and argparse. Implement subcommands:
- `status`: Runs diagnostic checks on system services and memory.
- `theme [dark|neon|cyan]`: Modifies GTK accent configurations.
- `install-devtools`: Runs automated installation of Docker, Node.js, Python toolchain, Git, and Neovim.

- [ ] **Step 3: Create `eclipse-installer` utility**

Write `src/eclipse-installer` using Python 3. Implement an interactive live-to-disk installation wizard:
- Block device scanner (`lsblk`).
- Target disk partitioner (`parted`).
- File system formatter (`mkfs.vfat` for EFI, `mkfs.ext4` for root).
- RootFS synchronizer (`rsync`).
- Target GRUB installation and chroot user setup.

- [ ] **Step 4: Verify syntax and permissions of all Python utilities**

Run: `python3 -m py_compile src/eclipse-sysinfo src/eclipse-control src/eclipse-installer`
Expected: Clean compilation without syntax errors.

- [ ] **Step 5: Commit changes**

```bash
git add src/
git commit -m "feat: add native utilities"
git push origin main
```

---

### Task 3: Base Bootstrap Script (`scripts/01-bootstrap.sh`)

**Files:**
- Create: `scripts/01-bootstrap.sh`

**Interfaces:**
- Consumes: `debootstrap` host tool, Debian 12 package mirrors.
- Produces: Base root filesystem in `build/rootfs`.

- [ ] **Step 1: Write `scripts/01-bootstrap.sh`**

Implement automated debootstrap logic with root privilege check, directory validation, package mirror fallback, and clean logging:
```bash
#!/usr/bin/env bash
set -euo pipefail
# Validates environment and executes debootstrap --arch=amd64 bookworm build/rootfs
```

- [ ] **Step 2: Make executable and verify script syntax**

Run: `bash -n scripts/01-bootstrap.sh`
Expected: Syntax check passes with code 0.

- [ ] **Step 3: Commit changes**

```bash
git add scripts/01-bootstrap.sh
git commit -m "feat: add bootstrap script"
git push origin main
```

---

### Task 4: System Configuration & Chroot Provisioning Script (`scripts/02-configure.sh`)

**Files:**
- Create: `scripts/02-configure.sh`

**Interfaces:**
- Consumes: `build/rootfs` generated by `01-bootstrap.sh`, configuration files in `config/`, utilities in `src/`.
- Produces: Configured rootfs with kernel, XFCE desktop environment, GTK dark theme, and Eclipse utilities installed in `/usr/local/bin`.

- [ ] **Step 1: Write `scripts/02-configure.sh`**

Implement chroot configuration logic:
- Bind virtual filesystems (`/proc`, `/sys`, `/dev`, `/dev/pts`) with automatic `trap` cleanup on exit.
- Set system hostname `eclipse-os` and configure `/etc/hosts` and `/etc/apt/sources.list`.
- Install `linux-image-amd64`, `live-boot`, `live-config`, `systemd-sysv`, `network-manager`, `xfce4`, `lightdm`, `sudo`, `python3`, `python3-pip`, `python3-rich`.
- Copy GTK theme to `/usr/share/themes/Eclipse-Dark`, desktop configs to `/etc/skel/.config/`, wallpaper to `/usr/share/backgrounds/eclipse/`.
- Install `src/eclipse-*` utilities to `/usr/local/bin/` with `chmod +x`.
- Configure default live user (`eclipse`) with sudo access and automatic graphical login.

- [ ] **Step 2: Make executable and verify script syntax**

Run: `bash -n scripts/02-configure.sh`
Expected: Syntax check passes with code 0.

- [ ] **Step 3: Commit changes**

```bash
git add scripts/02-configure.sh
git commit -m "feat: add configure script"
git push origin main
```

---

### Task 5: SquashFS & ISO Packaging Pipeline (`scripts/03-package-iso.sh`)

**Files:**
- Create: `scripts/03-package-iso.sh`

**Interfaces:**
- Consumes: Configured `build/rootfs`, GRUB configuration in `config/grub/`.
- Produces: `build/iso_staging/live/filesystem.squashfs` and compiled ISO image `build/output/eclipse-os-v1.0-x86_64.iso`.

- [ ] **Step 1: Write `scripts/03-package-iso.sh`**

Implement ISO compilation workflow:
- Create SquashFS filesystem from `build/rootfs` using `mksquashfs build/rootfs build/iso_staging/live/filesystem.squashfs -comp xz`.
- Copy Linux kernel (`vmlinuz`) and initramfs (`initrd.img`) into `build/iso_staging/live/`.
- Copy GRUB bootloader configuration and theme to `build/iso_staging/boot/grub/`.
- Generate standalone EFI bootloader binary `BOOTX64.EFI` using `grub-mkstandalone`.
- Execute `xorriso` or `grub-mkrescue` to produce `build/output/eclipse-os-v1.0-x86_64.iso`.

- [ ] **Step 2: Make executable and verify script syntax**

Run: `bash -n scripts/03-package-iso.sh`
Expected: Syntax check passes with code 0.

- [ ] **Step 3: Commit changes**

```bash
git add scripts/03-package-iso.sh
git commit -m "feat: add package script"
git push origin main
```

---

### Task 6: QEMU Test Script & Automated End-to-End Verification (`scripts/04-test-qemu.sh`)

**Files:**
- Create: `scripts/04-test-qemu.sh`

**Interfaces:**
- Consumes: Compiled ISO `build/output/eclipse-os-v1.0-x86_64.iso`.
- Produces: QEMU virtual machine test launch with KVM hardware acceleration.

- [ ] **Step 1: Write `scripts/04-test-qemu.sh`**

Implement QEMU test launcher:
```bash
#!/usr/bin/env bash
set -euo pipefail

ISO_PATH="build/output/eclipse-os-v1.0-x86_64.iso"
if [[ ! -f "$ISO_PATH" ]]; then
    echo "Error: ISO file $ISO_PATH not found. Run scripts/03-package-iso.sh first."
    exit 1
fi

echo "Launching Eclipse OS v1.0 ISO in QEMU..."
qemu-system-x86_64 \
    -enable-kvm \
    -m 4096 \
    -smp 4 \
    -vga virtio \
    -display gtk \
    -cdrom "$ISO_PATH" \
    -boot d
```

- [ ] **Step 2: Make executable and verify script syntax**

Run: `bash -n scripts/04-test-qemu.sh`
Expected: Syntax check passes with code 0.

- [ ] **Step 3: Commit changes**

```bash
git add scripts/04-test-qemu.sh
git commit -m "feat: add test script"
git push origin main
```
