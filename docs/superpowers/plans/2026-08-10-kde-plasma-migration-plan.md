# KDE Plasma Migration Implementation Plan for Eclipse OS v1.0

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate Eclipse OS desktop environment from XFCE4 to KDE Plasma (`kde-plasma-desktop` + `sddm` + `dolphin` + `konsole`). Replace legacy XFCE panels and GTK selection bugs with native KDE Plasma floating panels, Qt accent color engine, and modern hardware-accelerated desktop compositing.

**Architecture:** Modify `scripts/02-configure.sh` to install KDE Plasma stack, configure SDDM autologin, stage KDE Plasma configuration templates in `/etc/skel/.config/` and `/etc/xdg/`, update Python system utilities (`src/eclipse-control`, `src/eclipse-sysinfo`, `src/eclipse-installer`), rebuild rootfs and live ISO, and verify in QEMU.

**Tech Stack:** Debian 12 Bookworm, KDE Plasma 5/6 (`kde-plasma-desktop`, `plasma-workspace`), SDDM, Dolphin, Konsole, Python 3, Rich, Qt5/Qt6 color schemes.

## Global Constraints

- Commit messages MUST be strictly 3-4 plain words without prefixes (`feat:`, `fix:`, `docs:`) or meta text.
- Do NOT use em dashes (`—` / `–`) or AI jargon words.
- All code MUST be clean without redundant comments.
- All files MUST be created inside `/home/mohs/eclipse-os`.

---

### Task 1: Update Package Selection in `scripts/02-configure.sh`

**Files:**
- Modify: `scripts/02-configure.sh`

**Interfaces:**
- Replaces XFCE4 desktop packages with KDE Plasma desktop, SDDM display manager, Dolphin file manager, and Konsole terminal emulator inside rootfs.

- [ ] **Step 1: Replace XFCE packages with KDE Plasma stack in `scripts/02-configure.sh`**

  Remove: `xfce4 xfce4-goodies lightdm xfce4-terminal`
  Add: `kde-plasma-desktop plasma-workspace sddm dolphin konsole spectacle ark gwenview`

- [ ] **Step 2: Configure SDDM Autologin for `eclipse` user in `scripts/02-configure.sh`**

  Create `/etc/sddm.conf.d/autologin.conf`:
  ```ini
  [Autologin]
  User=eclipse
  Session=plasma
  Relogin=false

  [Theme]
  Current=breeze
  ```

- [ ] **Step 3: Commit package updates**

  Run: `git add scripts/02-configure.sh && git commit -m "add kde plasma packages" && git push origin main`

---

### Task 2: Configure KDE Plasma Desktop & Panel Layout Templates

**Files:**
- Create: `config/kde/kdeglobals`
- Create: `config/kde/plasmarc`
- Create: `config/kde/plasma-org.kde.plasma.desktop-appletsrc`
- Modify: `scripts/02-configure.sh`

**Interfaces:**
- Produces: Default Fedora Blue KDE Plasma theme, top status bar panel, and bottom floating launcher dock panel.

- [ ] **Step 1: Write `config/kde/kdeglobals` specifying Fedora Blue accent & Breeze Dark palette**

```ini
[Colors:Selection]
Background=53,132,228
Foreground=255,255,255

[Colors:View]
Background=30,30,30
Foreground=248,250,252

[Colors:Window]
Background=26,27,38
Foreground=248,250,252

[General]
ColorScheme=BreezeDark
AccentColor=53,132,228

[KDE]
SingleClick=false
```

- [ ] **Step 2: Write `config/kde/plasmarc` enabling floating panel docks**

```ini
[Theme]
name=breeze-dark
```

- [ ] **Step 3: Write `config/kde/plasma-org.kde.plasma.desktop-appletsrc` configuring top status bar and bottom floating dock**

  Configure panel 1 (top, height 32) and panel 2 (bottom, height 48, floating, icons-only task manager / launcher dock).

- [ ] **Step 4: Update `scripts/02-configure.sh` to stage KDE Plasma configs into `/etc/skel/.config/` and `/etc/xdg/`**

- [ ] **Step 5: Commit KDE Plasma layout configuration**

  Run: `git add config/kde/ scripts/02-configure.sh && git commit -m "add kde plasma configs" && git push origin main`

---

### Task 3: Update System Launchers & Python Utilities

**Files:**
- Modify: `src/eclipse-sysinfo`
- Modify: `src/eclipse-control`
- Modify: `src/eclipse-installer`
- Modify: `scripts/02-configure.sh`

**Interfaces:**
- Updates terminal execution flags from `xfce4-terminal` to `konsole --hold -e` and updates `eclipse-control` to manage KDE `kdeglobals` accent colors.

- [ ] **Step 1: Update `.desktop` application launchers to use `konsole`**

  In `scripts/02-configure.sh`, update `eclipse-sysinfo.desktop` and `eclipse-installer.desktop` to use `konsole --hold -e eclipse-sysinfo` and `konsole -e "sudo eclipse-installer"`.

- [ ] **Step 2: Update `src/eclipse-control` to modify `~/.config/kdeglobals` accent colors**

  Update `cmd_theme` in `src/eclipse-control` to update `AccentColor` RGB values in `~/.config/kdeglobals` for `fedora` (`53,132,228`), `crimson` (`225,29,72`), `cyan` (`6,182,212`), and `emerald` (`16,185,129`).

- [ ] **Step 3: Commit utility updates**

  Run: `git add src/ scripts/02-configure.sh && git commit -m "update utilities for kde" && git push origin main`

---

### Task 4: Execute System Rebuild & Live ISO Packaging

- [ ] **Step 1: Execute `scripts/02-configure.sh` inside rootfs**

  Run: `echo '230907' | sudo -S bash scripts/02-configure.sh`

- [ ] **Step 2: Execute `scripts/03-package-iso.sh` to compress SquashFS & generate ISO**

  Run: `echo '230907' | sudo -S bash scripts/03-package-iso.sh`

- [ ] **Step 3: Verify output ISO size & existence**

  Run: `ls -lh build/output/eclipse-os-v1.0-x86_64.iso`

---

### Task 5: Empirical Verification via QEMU

- [ ] **Step 1: Launch QEMU test**

  Run: `bash scripts/04-test-qemu.sh`
  Expected: Clean boot into SDDM autologin -> KDE Plasma desktop with Fedora Blue accent, floating bottom dock, top status panel, Dolphin file manager, and Konsole terminal emulator.
