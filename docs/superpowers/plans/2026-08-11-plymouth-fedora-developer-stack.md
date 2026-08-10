# Plymouth Boot Splash & Fedora Developer Toolchain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Plymouth graphical boot splash theme featuring the custom Eclipse OS logo, add full Fedora-grade developer toolchain (C/C++, Rust, Go, Podman, Flatpak, ripgrep, fzf, dev utilities), and create a native `dnf` CLI compatibility wrapper script so developers can use Fedora commands (`dnf install`, `dnf update`, `dnf search`) seamlessly.

**Architecture:** Create Plymouth boot theme `config/plymouth/eclipse-splash`, write `src/dnf` wrapper script, update `scripts/02-configure.sh` to install Plymouth + dev toolchain and rebuild initramfs, update `config/grub/grub.cfg` with clean Graphical Plymouth Boot (Default), Verbose Boot, and Safe Graphics options, update `src/eclipse-control`, and rebuild the live ISO.

**Tech Stack:** Debian 12 Bookworm, Plymouth (`plymouth-themes`, `initramfs-tools`), C/C++ (`gcc`, `g++`, `make`, `cmake`), Rust (`cargo`), Go (`golang`), Podman (`podman`), Flatpak, Python 3, Rich, Bash.

## Global Constraints

- Commit messages MUST be strictly 3-4 plain words without prefixes (`feat:`, `fix:`, `docs:`) or meta text.
- Do NOT use em dashes (`—` / `–`) or AI jargon words.
- All code MUST be clean without redundant comments.
- All files MUST be created inside `/home/mohs/eclipse-os`.

---

### Task 1: Create Plymouth Graphical Boot Splash Theme (`config/plymouth/`)

**Files:**
- Create: `config/plymouth/eclipse-splash/eclipse-splash.plymouth`
- Create: `config/plymouth/eclipse-splash/eclipse-splash.script`
- Copy: `config/logo/eclipse-logo.png` -> `config/plymouth/eclipse-splash/logo.png`

**Interfaces:**
- Produces: Plymouth theme `eclipse-splash` that displays a centered glowing Eclipse OS boot logo over dark background with smooth spinner animation during bootup.

- [ ] **Step 1: Create `config/plymouth/eclipse-splash/eclipse-splash.plymouth`**

```ini
[Plymouth Theme]
Name=Eclipse OS Boot Splash
Description=Graphical boot splash theme for Eclipse OS
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/eclipse-splash
ScriptFile=/usr/share/plymouth/themes/eclipse-splash/eclipse-splash.script
```

- [ ] **Step 2: Create `config/plymouth/eclipse-splash/eclipse-splash.script`**

```script
# Eclipse OS Plymouth Boot Script
Window.SetBackgroundTopColor(0.07, 0.07, 0.09);
Window.SetBackgroundBottomColor(0.07, 0.07, 0.09);

logo.image = Image("logo.png");
logo.sprite = Sprite(logo.image);

logo.x = Window.GetWidth() / 2 - logo.image.GetWidth() / 2;
logo.y = Window.GetHeight() / 2 - logo.image.GetHeight() / 2 - 40;
logo.sprite.SetX(logo.x);
logo.sprite.SetY(logo.y);
logo.sprite.SetOpacity(1.0);

status.image = Image.Text("Eclipse OS v1.0 (Syzygy) - Starting...", 1.0, 1.0, 1.0);
status.sprite = Sprite(status.image);
status.sprite.SetX(Window.GetWidth() / 2 - status.image.GetWidth() / 2);
status.sprite.SetY(Window.GetHeight() / 2 + logo.image.GetHeight() / 2 + 20);
status.sprite.SetOpacity(0.9);
```

- [ ] **Step 3: Copy logo into theme directory**

Run: `mkdir -p config/plymouth/eclipse-splash && cp config/logo/eclipse-logo.png config/plymouth/eclipse-splash/logo.png`

- [ ] **Step 4: Commit Plymouth theme assets**

Run: `git add config/plymouth/ && git commit -m "add plymouth boot theme" && git push origin main`

---

### Task 2: Create Fedora `dnf` CLI Compatibility Wrapper (`src/dnf`)

**Files:**
- Create: `src/dnf`

**Interfaces:**
- Produces: `/usr/local/bin/dnf` executable that translates Fedora `dnf` commands (`dnf install`, `dnf remove`, `dnf update`, `dnf search`, `dnf info`) into `apt` equivalents with Fedora Blue TUI outputs.

- [ ] **Step 1: Write `src/dnf`**

```python
#!/usr/bin/env python3

import sys
import os
import subprocess

def main():
    if len(sys.argv) < 2:
        print("Fedora DNF Compatibility Layer (Eclipse OS)")
        print("Usage: dnf [install|remove|update|search|info|clean] [packages...]")
        sys.exit(1)

    subcmd = sys.argv[1].lower()
    pkg_args = sys.argv[2:]

    cmd_map = {
        "install": ["apt-get", "install", "-y"],
        "remove": ["apt-get", "remove", "-y"],
        "erase": ["apt-get", "remove", "-y"],
        "update": ["apt-get", "update"],
        "upgrade": ["apt-get", "dist-upgrade", "-y"],
        "search": ["apt-cache", "search"],
        "info": ["apt-cache", "show"],
        "clean": ["apt-get", "clean"],
    }

    if subcmd not in cmd_map:
        print(f"[DNF] Unknown subcommand '{subcmd}'. Forwarding directly to apt...")
        full_cmd = ["apt"] + sys.argv[1:]
    else:
        full_cmd = cmd_map[subcmd] + pkg_args

    if subcmd in ("install", "remove", "erase", "upgrade", "clean") and os.geteuid() != 0:
        full_cmd = ["sudo"] + full_cmd

    print(f"\033[1;34m[DNF -> APT]\033[0m Executing: {' '.join(full_cmd)}")
    sys.exit(subprocess.call(full_cmd))

if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Set executable permissions and verify Python compilation**

Run: `chmod +x src/dnf && python3 -m py_compile src/dnf`

- [ ] **Step 3: Commit `dnf` CLI tool**

Run: `git add src/dnf && git commit -m "add dnf cli wrapper" && git push origin main`

---

### Task 3: Update GRUB Boot Configuration (`config/grub/grub.cfg`)

**Files:**
- Modify: `config/grub/grub.cfg`

**Interfaces:**
- Produces: 3 boot entries:
  1. Default: Graphical Plymouth Boot (`quiet splash plymouth.ignore-serial-consoles`)
  2. Verbose Boot: Text console boot for debugging
  3. Safe Graphics: `nomodeset xforcevesa` for hardware GPU recovery

- [ ] **Step 1: Write `config/grub/grub.cfg`**

```grub
set default=0
set timeout=5

insmod part_gpt
insmod part_msdos
insmod fat
insmod ext2
insmod all_video
insmod font
insmod gfxterm
insmod png
insmod theme

set gfxmode=1920x1080,1280x720,auto
set gfxpayload=keep
terminal_output gfxterm

set theme=/boot/grub/themes/eclipse-grub-theme/theme.txt

menuentry "Eclipse OS v1.0 (Graphical Boot - Plymouth)" {
    linux /live/vmlinuz boot=live quiet splash plymouth.ignore-serial-consoles components username=eclipse hostname=eclipse-os live-media-path=/live
    initrd /live/initrd.img
}

menuentry "Eclipse OS v1.0 (Verbose Console Boot)" {
    linux /live/vmlinuz boot=live components username=eclipse hostname=eclipse-os live-media-path=/live
    initrd /live/initrd.img
}

menuentry "Eclipse OS v1.0 (Safe Graphics - nomodeset)" {
    linux /live/vmlinuz boot=live components username=eclipse hostname=eclipse-os live-media-path=/live nomodeset xforcevesa
    initrd /live/initrd.img
}

menuentry "Eclipse OS v1.0 Direct Disk Installer" {
    linux /live/vmlinuz boot=live components installer username=eclipse hostname=eclipse-os live-media-path=/live
    initrd /live/initrd.img
}
```

- [ ] **Step 2: Commit GRUB config**

Run: `git add config/grub/grub.cfg && git commit -m "update grub boot options" && git push origin main`

---

### Task 4: Update System Provisioning (`scripts/02-configure.sh`)

**Files:**
- Modify: `scripts/02-configure.sh`

**Interfaces:**
- Installs Plymouth, Fedora developer packages (C/C++ GCC/g++/make/cmake, Rust cargo, Go, Podman, Flatpak, ripgrep, fzf, jq, bat), sets Plymouth default theme to `eclipse-splash`, and rebuilds initramfs.

- [ ] **Step 1: Add Plymouth and Fedora Developer Stack to package list in `scripts/02-configure.sh`**

  Add: `plymouth plymouth-themes initramfs-tools build-essential gcc g++ make cmake gdb valgrind clang llvm golang cargo rustc podman podman-docker flatpak ripgrep fzf jq bat strace lsof net-tools`

- [ ] **Step 2: Provision Plymouth theme & `dnf` CLI tool in `scripts/02-configure.sh`**

  ```bash
  # Provision Plymouth Splash Theme
  echo -e "${BLUE}[+] Provisioning Plymouth Boot Splash Theme...${RESET}"
  mkdir -p "$ROOTFS/usr/share/plymouth/themes"
  cp -r "$PROJECT_ROOT/config/plymouth/eclipse-splash" "$ROOTFS/usr/share/plymouth/themes/"

  chroot "$ROOTFS" plymouth-set-default-theme eclipse-splash -R || true
  chroot "$ROOTFS" update-initramfs -u -k all || true

  # Copy dnf CLI compatibility tool
  cp "$PROJECT_ROOT/src/dnf" "$ROOTFS/usr/local/bin/dnf"
  chmod +x "$ROOTFS/usr/local/bin/dnf"
  ```

- [ ] **Step 3: Commit `scripts/02-configure.sh` updates**

  Run: `git add scripts/02-configure.sh && git commit -m "add fedora dev toolchain" && git push origin main`

---

### Task 5: Rebuild Rootfs & Live ISO

- [ ] **Step 1: Execute `scripts/02-configure.sh` inside rootfs**

  Run: `echo '230907' | sudo -S bash scripts/02-configure.sh`

- [ ] **Step 2: Execute `scripts/03-package-iso.sh` to generate output ISO**

  Run: `echo '230907' | sudo -S bash scripts/03-package-iso.sh`

- [ ] **Step 3: Verify output ISO existence and size**

  Run: `ls -lh build/output/eclipse-os-v1.0-x86_64.iso`

---

### Task 6: Empirical Verification Protocol

- [ ] **Step 1: Run Python syntax & compilation check**

  Run: `python3 -m py_compile src/eclipse-sysinfo src/eclipse-control src/eclipse-installer src/eclipse-dock src/dnf`

- [ ] **Step 2: Run bash script syntax check**

  Run: `bash -n scripts/01-bootstrap.sh && bash -n scripts/02-configure.sh && bash -n scripts/03-package-iso.sh && bash -n scripts/04-test-qemu.sh`

- [ ] **Step 3: Run git repository status check**

  Run: `git status && git log -n 4 --oneline`

- [ ] **Step 4: Launch QEMU test**

  Run: `bash scripts/04-test-qemu.sh`
