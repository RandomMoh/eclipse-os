# Full KDE Plasma Desktop Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fully migrate Eclipse OS from XFCE to KDE Plasma Desktop with custom Crimson Obsidian theme, Breeze Dark styling, KWin window effects, top status panel, bottom floating launcher dock, and SDDM autologin.

**Architecture:** Update `scripts/02-configure.sh` to swap XFCE packages for `kde-plasma-desktop`, `plasma-workspace`, `konsole`, `dolphin`, `kate`, `kwin-x11`, `sddm`. Create KDE Plasma configuration templates in `config/kde/` (`kdeglobals`, `plasmarc`, `plasma-org.kde.plasma.desktop-appletsrc`, `kwinrc`), configure SDDM for `eclipse` autologin, update `src/eclipse-control`, and rebuild `build/output/eclipse-os-v1.0-x86_64.iso`.

**Tech Stack:** Debian 12 Bookworm, KDE Plasma 5/6, Qt5/Qt6, KWin, SDDM, Python 3, Rich, Bash.

## Global Constraints

- Commit messages MUST be strictly 3-4 plain words without prefixes (`feat:`, `fix:`, `docs:`) or meta text.
- Do NOT use em dashes (`—` / `–`) or AI jargon words.
- All code MUST be clean without redundant comments.
- All files MUST be created inside `/home/mohs/eclipse-os`.

---

### Task 1: Create KDE Plasma Visual Configuration System (`config/kde/`)

**Files:**
- Create: `config/kde/kdeglobals`
- Create: `config/kde/plasmarc`
- Create: `config/kde/plasma-org.kde.plasma.desktop-appletsrc`
- Create: `config/kde/kwinrc`

**Interfaces:**
- Produces: System-wide default KDE Plasma theme settings with Crimson Obsidian `#E11D48` accent, Breeze Dark colors, top status bar panel, and bottom launcher dock.

- [ ] **Step 1: Write `config/kde/kdeglobals`**

```ini
[Colors:Button]
BackgroundNormal=26,27,38
ForegroundNormal=248,250,252

[Colors:Selection]
BackgroundNormal=225,29,72
ForegroundNormal=255,255,255

[Colors:Window]
BackgroundNormal=15,13,14
ForegroundNormal=248,250,252

[General]
ColorScheme=BreezeDark
accentColor=225,29,72

[KDE]
SingleClick=false
WidgetStyle=Breeze
```

- [ ] **Step 2: Write `config/kde/plasmarc`**

```ini
[Theme]
name=breeze-dark
```

- [ ] **Step 3: Write `config/kde/plasma-org.kde.plasma.desktop-appletsrc`**

```ini
[Containments][1]
activityId=
formfactor=0
immutability=1
lastScreen=0
location=3
plugin=org.kde.panel

[Containments][1][Applets][2]
plugin=org.kde.plasma.kickoff

[Containments][1][Applets][3]
plugin=org.kde.plasma.globalmenu

[Containments][1][Applets][4]
plugin=org.kde.plasma.systemtray

[Containments][1][Applets][5]
plugin=org.kde.plasma.digitalclock

[Containments][6]
activityId=
formfactor=0
immutability=1
lastScreen=0
location=4
plugin=org.kde.panel

[Containments][6][Applets][7]
plugin=org.kde.plasma.icontasks
```

- [ ] **Step 4: Write `config/kde/kwinrc`**

```ini
[Plugins]
blurEnabled=true
translucencyEnabled=true

[Windows]
BorderColor=225,29,72
TitleAlignment=Center
```

- [ ] **Step 5: Commit KDE Plasma theme assets**

Run: `git add config/kde/ && git commit -m "add kde plasma theme" && git push origin main`

---

### Task 2: Update Package Arsenal & Provisioning in `scripts/02-configure.sh`

**Files:**
- Modify: `scripts/02-configure.sh`

**Interfaces:**
- Swaps XFCE packages for `kde-plasma-desktop`, `plasma-workspace`, `plasma-desktop`, `konsole`, `dolphin`, `kate`, `kwin-x11`, `sddm`, provisions `config/kde/` files into `/etc/skel/.config/`, and configures SDDM autologin.

- [ ] **Step 1: Update package list in `scripts/02-configure.sh`**

  Remove: `xfce4 xfce4-goodies lightdm xfce4-terminal`
  Add: `kde-plasma-desktop plasma-workspace plasma-desktop konsole dolphin kate kwin-x11 sddm breeze breeze-gtk-theme plasma-widgets-addons`

- [ ] **Step 2: Add SDDM autologin & KDE skel provisioning in `scripts/02-configure.sh`**

  ```bash
  # Provision KDE Plasma Configuration
  echo -e "${BLUE}[+] Provisioning KDE Plasma desktop theme & skeleton config...${RESET}"
  mkdir -p "$ROOTFS/etc/skel/.config"
  cp -f "$PROJECT_ROOT/config/kde/kdeglobals" "$ROOTFS/etc/skel/.config/kdeglobals"
  cp -f "$PROJECT_ROOT/config/kde/plasmarc" "$ROOTFS/etc/skel/.config/plasmarc"
  cp -f "$PROJECT_ROOT/config/kde/plasma-org.kde.plasma.desktop-appletsrc" "$ROOTFS/etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc"
  cp -f "$PROJECT_ROOT/config/kde/kwinrc" "$ROOTFS/etc/skel/.config/kwinrc"

  # Configure SDDM Autologin for live user eclipse
  mkdir -p "$ROOTFS/etc/sddm.conf.d"
  cat <<'EOF' > "$ROOTFS/etc/sddm.conf.d/autologin.conf"
  [Autologin]
  User=eclipse
  Session=plasma.desktop
  EOF
  ```

- [ ] **Step 3: Commit `scripts/02-configure.sh` updates**

  Run: `git add scripts/02-configure.sh && git commit -m "migrate to kde plasma" && git push origin main`

---

### Task 3: Update `src/eclipse-control` Management Tool

**Files:**
- Modify: `src/eclipse-control`

**Interfaces:**
- Updates `src/eclipse-control` status check to report KDE Plasma desktop environment and KWin window manager.

- [ ] **Step 1: Modify `src/eclipse-control`**

  Update `cmd_status()` and theme application subcommands to modify `~/.config/kdeglobals` accent color.

- [ ] **Step 2: Verify Python compilation**

  Run: `python3 -m py_compile src/eclipse-control`

- [ ] **Step 3: Commit `src/eclipse-control`**

  Run: `git add src/eclipse-control && git commit -m "update control for kde" && git push origin main`

---

### Task 4: Execute Rebuild & Package ISO

- [ ] **Step 1: Execute `scripts/02-configure.sh` inside rootfs**

  Run: `echo '230907' | sudo -S bash scripts/02-configure.sh`

- [ ] **Step 2: Execute `scripts/03-package-iso.sh` to generate output ISO**

  Run: `echo '230907' | sudo -S bash scripts/03-package-iso.sh`

- [ ] **Step 3: Verify output ISO existence and size**

  Run: `ls -lh build/output/eclipse-os-v1.0-x86_64.iso`

---

### Task 5: Empirical Verification Protocol

- [ ] **Step 1: Run Python syntax & compilation check**

  Run: `python3 -m py_compile src/eclipse-sysinfo src/eclipse-control src/eclipse-installer src/eclipse-dock src/dnf`

- [ ] **Step 2: Run bash script syntax check**

  Run: `bash -n scripts/01-bootstrap.sh && bash -n scripts/02-configure.sh && bash -n scripts/03-package-iso.sh && bash -n scripts/04-test-qemu.sh`

- [ ] **Step 3: Run git repository status check**

  Run: `git status && git log -n 4 --oneline`

- [ ] **Step 4: Launch QEMU test**

  Run: `bash scripts/04-test-qemu.sh`
