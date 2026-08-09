# Developer & Agent Guidelines for Eclipse OS

Welcome to the Eclipse OS project. This document provides clear context, architectural conventions, and guidelines for AI agents working in this codebase.

## Project Summary

Eclipse OS is a custom, bootable 64-bit Linux desktop operating system built on Debian 12 (Bookworm) `amd64`. The project contains both the OS configuration (desktop layout, theme, GTK styling, GRUB boot graphics, native Python utilities) and an automated build toolchain (`eclipse-os-builder`) that builds a bootable `.iso` image.

## Key Directory Structure

```
/home/mohs/eclipse-os/
├── build/                 # Scratch build directories (rootfs chroot, iso staging)
├── config/                # Configuration files and visual assets
│   ├── grub/              # GRUB theme (background, fonts, theme.txt) and grub.cfg
│   ├── gtk/               # Custom GTK3 theme (Eclipse-Dark: Obsidian + Neon Violet/Cyan)
│   ├── xfce/              # Pre-configured XFCE XML settings (panel, desktop, wm)
│   └── wallpaper/         # High-resolution desktop background
├── src/                   # Native Python 3 utilities
│   ├── eclipse-sysinfo    # Terminal resource & spec display
│   ├── eclipse-control    # Desktop & developer toolchain controller
│   └── eclipse-installer  # Live-to-disk Python installation wizard
├── scripts/               # ISO build pipeline
│   ├── 01-bootstrap.sh    # Base debootstrap rootfs generation
│   ├── 02-configure.sh    # Chroot configuration & desktop setup
│   ├── 03-package-iso.sh  # SquashFS compression & xorriso ISO creation
│   └── 04-test-qemu.sh    # QEMU boot test runner
└── docs/                  # System design specs and implementation plans
```

## Guidelines for AI Agents

1. **Commit Message Format**: Use concise, 3-4 word commit messages with conventional prefix tags. Examples:
   - `feat: add bootstrap script`
   - `docs: update system spec`
   - `fix: correct grub path`
   - `style: update gtk theme`

2. **Writing & Tone Rules**:
   - Do not use bloated AI jargon or promotional words (e.g. "delve", "testament", "pivotal", "vibrant", "tapestry", "crucial", "showcasing").
   - Do not use em dashes (`—`) or en dashes (`–`). Use periods, commas, or colons instead.
   - Keep documentation direct, factual, and practical.

3. **Bash Script Requirements**:
   - Every script in `scripts/` must begin with `#!/usr/bin/env bash` and `set -euo pipefail`.
   - Ensure paths are referenced relative to the project root directory.
   - Provide clean status output during step execution using colored terminal echoes.

4. **Python Utility Requirements**:
   - Python code in `src/` must run under Python 3.9+.
   - Use the `rich` library for TUI styling and formatted terminal output.
   - Scripts placed in `/usr/local/bin/` must have execution permissions (`chmod +x`).

5. **Build Pipeline Safety**:
   - Virtual filesystem mounts (`/proc`, `/sys`, `/dev`, `/dev/pts`) inside `build/rootfs` must be cleaned up or unmounted safely on trap or script exit.
   - Never write transient build output into tracked git directories. `build/` is ignored by `.gitignore`.
