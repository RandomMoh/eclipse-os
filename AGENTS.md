# Developer and Agent Guidelines for Eclipse OS

Welcome to the Eclipse OS project. This document provides the architectural conventions and rules for AI agents working in this codebase.

## Project Summary

Eclipse OS is a bootable 64-bit Linux desktop operating system based on Debian 12 (Bookworm). The project contains the OS configuration and the `eclipse-os-builder` toolchain that produces a bootable `.iso` image.

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

2. **Writing Rules**:
   - Do not use AI jargon or promotional words (for example: delve, testament, pivotal, vibrant, tapestry, crucial, showcasing).
   - Do not use em dashes or en dashes. Use periods, commas, or colons instead.
   - Keep documentation direct, factual, and practical.

3. **Bash Script Requirements**:
   - Every script in `scripts/` must begin with `#!/usr/bin/env bash` and `set -euo pipefail`.
   - Reference all paths relative to the project root directory.
   - Print status output during step execution using colored terminal variables.

4. **Python Utility Requirements**:
   - Run Python code in `src/` under Python 3.9+.
   - Use the `rich` library for TUI styling and formatted terminal output.
   - Scripts placed in `/usr/local/bin/` must have execution permissions (`chmod +x`).

5. **Build Pipeline Safety**:
   - Clean up or safely unmount virtual filesystem mounts (`/proc`, `/sys`, `/dev`, `/dev/pts`) inside `build/rootfs` on trap or script exit.
   - Do not write transient build output into tracked git directories. The `.gitignore` file ignores the `build/` directory.
