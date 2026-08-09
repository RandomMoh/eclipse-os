# Eclipse OS Developer Toolchain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provision Kate editor, LAMP stack (Apache, PHP, MariaDB), Composer, Laravel, Node.js, npm, Python 3, Zen Browser, Flutter SDK, Flame Engine, VS Code, and power utilities into Eclipse OS v1.0 ("Syzygy").

**Architecture:** Debian 12 (Bookworm) chroot package provisioning via `scripts/02-configure.sh`, custom binary installation scripts for Zen Browser and Flutter in `/opt/`, system-wide environment variables in `/etc/profile.d/`, and updated `eclipse-control` CLI management.

**Tech Stack:** Kate, Apache2, PHP 8.2, MariaDB, Composer, Laravel, Node.js, npm, Python 3, Flutter, Zen Browser, VS Code, GTK3, Debian 12.

## Global Constraints

- Do NOT install Docker.
- Commit messages must be strictly 3-4 words (e.g. `feat: add dev tools`).
- Do not use AI jargon words or em dashes in scripts or documentation.
- All scripts in `scripts/` must pass `bash -n`.
- All Python scripts in `src/` must pass `python3 -m py_compile`.

---

### Task 1: Add Kate, LAMP Stack, VS Code, and Power Utilities to `scripts/02-configure.sh`

**Files:**
- Modify: `scripts/02-configure.sh`

**Interfaces:**
- Consumes: Debian 12 Bookworm repositories, Microsoft VS Code APT keyring.
- Produces: Installed packages (`kate`, `apache2`, `php-cli`, `php-mysql`, `mariadb-server`, `composer`, `nodejs`, `npm`, `neovim`, `vlc`, `code`).

- [ ] **Step 1: Update APT package installation list in `scripts/02-configure.sh`**

Add `kate`, `apache2`, `php`, `php-cli`, `php-mbstring`, `php-xml`, `php-curl`, `php-mysql`, `php-zip`, `mariadb-server`, `composer`, `nodejs`, `npm`, `neovim`, `vlc`, `tmux`, `zsh`, `htop`, `fastfetch`, `curl`, `wget`, `git` to the `apt-get install` block in `scripts/02-configure.sh`. Remove any reference to `docker`.

- [ ] **Step 2: Add VS Code APT repository setup block**

Add code to `scripts/02-configure.sh` that imports the Microsoft GPG key and adds `deb [arch=amd64] https://packages.microsoft.com/repos/code stable main` to `/etc/apt/sources.list.d/vscode.list` before installing `code`.

- [ ] **Step 3: Verify script syntax**

Run: `bash -n scripts/02-configure.sh`
Expected: Code 0.

- [ ] **Step 4: Commit changes**

```bash
git add scripts/02-configure.sh
git commit -m "feat: add lamp packages"
git push origin main
```

---

### Task 2: Add Zen Browser Installation & Desktop Shortcut to `scripts/02-configure.sh`

**Files:**
- Modify: `scripts/02-configure.sh`

**Interfaces:**
- Consumes: Zen Browser Linux release package (`https://github.com/zen-browser/desktop/releases`).
- Produces: `/opt/zen/` binary directory, `/usr/local/bin/zen-browser` symlink, and `/usr/share/applications/zen-browser.desktop`.

- [ ] **Step 1: Add Zen Browser download and extraction block**

Write shell logic in `scripts/02-configure.sh` to download the Zen Browser Linux package, extract it to `$ROOTFS/opt/zen`, and create a symlink `$ROOTFS/usr/local/bin/zen-browser` -> `/opt/zen/zen-bin` or `/opt/zen/zen`.

- [ ] **Step 2: Create desktop launcher for Zen Browser**

Write `$ROOTFS/usr/share/applications/zen-browser.desktop` defining `Name=Zen Browser`, `Exec=zen-browser %u`, `Icon=/opt/zen/browser/chrome/icons/default/default128.png`, `Categories=Network;WebBrowser;`. Set Zen Browser as the default web browser in `/etc/skel/.config/mimeapps.list`.

- [ ] **Step 3: Verify script syntax**

Run: `bash -n scripts/02-configure.sh`
Expected: Code 0.

- [ ] **Step 4: Commit changes**

```bash
git add scripts/02-configure.sh
git commit -m "feat: add zen browser"
git push origin main
```

---

### Task 3: Add Flutter SDK & Flame Engine Setup to `scripts/02-configure.sh`

**Files:**
- Modify: `scripts/02-configure.sh`
- Create: `config/flutter.sh`

**Interfaces:**
- Consumes: Flutter Linux stable SDK (`https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz`).
- Produces: `/opt/flutter` directory, `/etc/profile.d/flutter.sh` system PATH entry, and pre-activated Flame Engine dependencies.

- [ ] **Step 1: Create `/etc/profile.d/flutter.sh` configuration**

Write `config/flutter.sh` exporting `PATH="$PATH:/opt/flutter/bin"` and `FLUTTER_ROOT="/opt/flutter"`.

- [ ] **Step 2: Add Flutter SDK download and extraction block to `02-configure.sh`**

Write shell logic in `scripts/02-configure.sh` to download Flutter stable SDK into `$ROOTFS/opt/flutter`, copy `config/flutter.sh` to `$ROOTFS/etc/profile.d/flutter.sh`, and set ownership `chown -R root:root $ROOTFS/opt/flutter`.

- [ ] **Step 3: Verify script syntax**

Run: `bash -n scripts/02-configure.sh`
Expected: Code 0.

- [ ] **Step 4: Commit changes**

```bash
git add scripts/02-configure.sh config/flutter.sh
git commit -m "feat: add flutter sdk"
git push origin main
```

---

### Task 4: Add Global Laravel CLI Setup to `scripts/02-configure.sh`

**Files:**
- Modify: `scripts/02-configure.sh`

**Interfaces:**
- Consumes: `composer` package manager inside chroot.
- Produces: Global Composer binary `laravel` in `/usr/local/bin/laravel`.

- [ ] **Step 1: Add Laravel installer block**

Add chroot execution in `scripts/02-configure.sh` running `composer global require laravel/installer` and creating a system symlink `/usr/local/bin/laravel` -> `/root/.config/composer/vendor/bin/laravel` (and in `/etc/skel/.config/composer/vendor/bin/laravel`).

- [ ] **Step 2: Verify script syntax**

Run: `bash -n scripts/02-configure.sh`
Expected: Code 0.

- [ ] **Step 3: Commit changes**

```bash
git add scripts/02-configure.sh
git commit -m "feat: add laravel installer"
git push origin main
```

---

### Task 5: Update `src/eclipse-control` Management Tool

**Files:**
- Modify: `src/eclipse-control`

**Interfaces:**
- Consumes: Python 3, `rich`, system commands (`apache2ctl`, `mariadb`, `composer`, `flutter`, `zen-browser`).
- Produces: Updated `eclipse-control` CLI for developer stack status and setup.

- [ ] **Step 1: Update `status` command in `src/eclipse-control`**

Add checks for Apache2 (`apache2ctl status`), MariaDB (`systemctl is-active mariadb`), PHP version (`php -v`), Node/npm version, Flutter version (`flutter --version`), and Zen Browser installation status.

- [ ] **Step 2: Update `install-devtools` command in `src/eclipse-control`**

Replace Docker setup logic with Laravel CLI, Flutter pub cache, and Zen Browser verification checks.

- [ ] **Step 3: Verify Python syntax**

Run: `python3 -m py_compile src/eclipse-control`
Expected: Code 0.

- [ ] **Step 4: Commit changes**

```bash
git add src/eclipse-control
git commit -m "feat: update control utility"
git push origin main
```
