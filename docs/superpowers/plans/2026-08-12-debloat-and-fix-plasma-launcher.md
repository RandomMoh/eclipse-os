# Debloat System & Fix KDE Kickoff Application Launcher Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove bloated packages (`apache2`, `mariadb-server`, `php*`, `composer`, `vlc`, `tmux`, `zsh`), fix the KDE Kickoff Application Launcher on top left by removing invalid appletsrc overrides, and rebuild clean 1080p Live ISO.

**Architecture:** Remove `config/kde/plasma-org.kde.plasma.desktop-appletsrc` so KDE Plasma generates its native interactive panel with working Kickoff launcher. Update `scripts/02-configure.sh` to purge bloatware web/database servers and media players while maintaining clean developer essential tools (Zen Browser, Kate, VS Code, Konsole, Dolphin, Podman, Rust, Go, GCC/C++, dnf CLI). Update `src/eclipse-control` and rebuild ISO.

**Tech Stack:** Debian 12 Bookworm, KDE Plasma 5 (`plasma-workspace`, `konsole`, `dolphin`, `kate`, `kwin-x11`), SDDM, Python 3, Rich, Bash.

## Global Constraints

- Commit messages MUST be strictly 3-4 plain words without prefixes (`feat:`, `fix:`, `docs:`) or meta text.
- Do NOT use em dashes (`—` / `–`) or AI jargon words.
- All code MUST be clean without redundant comments.
- All files MUST be created inside `/home/mohs/eclipse-os`.

---

### Task 1: Fix KDE Plasma Applet Configuration & Purge Bloat Packages (`scripts/02-configure.sh`)

**Files:**
- Remove: `config/kde/plasma-org.kde.plasma.desktop-appletsrc`
- Modify: `scripts/02-configure.sh`

**Interfaces:**
- Removes `plasma-org.kde.plasma.desktop-appletsrc` so KDE Plasma provisions a clean, responsive Kickoff Application Launcher panel.
- Removes `apache2`, `mariadb-server`, `php*`, `composer`, `vlc`, `tmux`, `zsh` from package list and purges them inside rootfs.

- [ ] **Step 1: Delete `config/kde/plasma-org.kde.plasma.desktop-appletsrc`**

  Run: `rm -f config/kde/plasma-org.kde.plasma.desktop-appletsrc`

- [ ] **Step 2: Update package list in `scripts/02-configure.sh`**

  Remove bloat packages: `apache2 php php-cli php-mbstring php-xml php-curl php-mysql php-zip mariadb-server composer vlc tmux zsh`

- [ ] **Step 3: Add explicit purge step inside rootfs in `scripts/02-configure.sh`**

  ```bash
  chroot "$ROOTFS" apt-get purge -y apache2 mariadb-server php* composer vlc tmux zsh 2>/dev/null || true
  chroot "$ROOTFS" apt-get autoremove -y --purge 2>/dev/null || true
  ```

- [ ] **Step 4: Commit cleanup updates**

  Run: `git add config/kde/ scripts/02-configure.sh && git commit -m "debloat os and fix launcher" && git push origin main`

---

### Task 2: Update `src/eclipse-control` Utility

**Files:**
- Modify: `src/eclipse-control`

**Interfaces:**
- Updates `eclipse-control` status check to remove apache2/mariadb/php checks and report clean KDE Plasma developer environment.

- [ ] **Step 1: Modify `src/eclipse-control` status display**

- [ ] **Step 2: Verify Python compilation**

  Run: `python3 -m py_compile src/eclipse-control`

- [ ] **Step 3: Commit `src/eclipse-control`**

  Run: `git add src/eclipse-control && git commit -m "update control tool status" && git push origin main`

---

### Task 3: Execute Rebuild & Package ISO

- [ ] **Step 1: Execute `scripts/02-configure.sh` inside rootfs**

  Run: `echo '230907' | sudo -S bash scripts/02-configure.sh`

- [ ] **Step 2: Execute `scripts/03-package-iso.sh` to generate output ISO**

  Run: `echo '230907' | sudo -S bash scripts/03-package-iso.sh`

- [ ] **Step 3: Verify output ISO existence and size**

  Run: `ls -lh build/output/eclipse-os-v1.0-x86_64.iso`

---

### Task 4: Empirical Verification Protocol

- [ ] **Step 1: Run Python syntax & compilation check**

  Run: `python3 -m py_compile src/eclipse-sysinfo src/eclipse-control src/eclipse-installer src/eclipse-dock src/dnf`

- [ ] **Step 2: Run bash script syntax check**

  Run: `bash -n scripts/01-bootstrap.sh && bash -n scripts/02-configure.sh && bash -n scripts/03-package-iso.sh && bash -n scripts/04-test-qemu.sh`

- [ ] **Step 3: Run git repository status check**

  Run: `git status && git log -n 4 --oneline`

- [ ] **Step 4: Launch QEMU test**

  Run: `bash scripts/04-test-qemu.sh`
