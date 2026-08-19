# Standalone Graphical Applications & Anti-Slop UI Redesign Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all CLI/Konsole-based system utilities (`eclipse-sysinfo`, `eclipse-installer`, `eclipse-control`) with standalone, high-performance graphical desktop applications (PyQt5 + WebEngine) featuring anti-slop, utilitarian dark UI design (Linear/Geist aesthetic).

**Architecture:** Python backends wrapping native Linux utilities (`lsblk`, `lspci`, `/proc`, `systemctl`, `rsync`, `parted`) with a lightweight local REST API served via `http.server` to standalone PyQt5 WebEngine desktop windows. Each utility gets its own dedicated standalone app launcher, desktop shortcut, and window.

**Tech Stack:** Python 3, PyQt5 (QtWebEngine), HTML5/CSS3 (Tailwind v4 / Geist Sans), JavaScript, Linux System Utilities.

## Global Constraints
- No AI marketing slop (no cheap gradient text, no purple mesh glows, no "Architect your digital environment" landing-page filler).
- Ultra-clean dark UI (`#09090B` obsidian canvas, `#18181B` surface, 1px `#27272A` borders, crisp `#F4F4F5` typography).
- Every utility MUST be a standalone desktop application with its own launch command (`eclipse-sysinfo-gui`, `eclipse-installer-gui`, `eclipse-driver-manager-gui`, `eclipse-os-hub`) and desktop entry.
- Real system data integration via backend API endpoints.

---

### Task 1: Core Backend API Engine (`src/eclipse_backend.py`)

**Files:**
- Create: `src/eclipse_backend.py`

**Interfaces:**
- Consumes: `/proc/meminfo`, `/proc/cpuinfo`, `/proc/uptime`, `lsblk -J`, `lspci`, `dpkg -l`
- Produces: JSON API endpoints `/api/sysinfo`, `/api/disks`, `/api/install`, `/api/drivers`, `/api/drivers/install`

- [ ] **Step 1: Create `src/eclipse_backend.py` containing modular API logic**

Write Python functions:
- `get_sysinfo_data()` -> Returns memory usage, CPU model, core count, uptime, disk usage, network interfaces, hostname, kernel version.
- `get_disks_data()` -> Parses `lsblk -J` or `/sys/block` to return target disks with capacity, vendor, model, and partition table.
- `get_drivers_data()` -> Runs `lspci` / `lshw` checks to detect GPU hardware (NVIDIA, AMD, Intel) and driver status (`nouveau`, `nvidia-driver`, `amdgpu`, `i915`).
- `start_installation(disk, hostname, username, password)` -> Executes partition formatting and rsync deployment in a thread.
- `install_driver(driver_id)` -> Executes `apt-get install` for selected GPU driver.

- [ ] **Step 2: Verify Python compilation**

Run: `python3 -m py_compile src/eclipse_backend.py`
Expected: PASS with exit code 0

- [ ] **Step 3: Commit**

```bash
git add src/eclipse_backend.py
git commit -m "feat: add core backend system API engine"
```

---

### Task 2: Standalone System Information Application (`src/ui/sysinfo.html` & `src/eclipse-sysinfo-gui`)

**Files:**
- Create: `src/ui/sysinfo.html`
- Create: `src/eclipse-sysinfo-gui`

**Interfaces:**
- Consumes: `/api/sysinfo` from `eclipse_backend.py`
- Produces: Live hardware telemetry dashboard UI window

- [ ] **Step 1: Write `src/ui/sysinfo.html`**

Utilitarian design:
- Top bar: OS Version ("Eclipse OS v1.0 Syzygy"), Kernel, Hostname.
- Live progress bars / meters for CPU load, RAM usage, Swap, Disk storage.
- Grid of hardware specs: CPU Architecture, Cores, Threads, GPU model, Active Display Server (Wayland/X11), Network Interfaces & IP addresses.
- Auto-refresh fetch poll every 2 seconds.

- [ ] **Step 2: Write `src/eclipse-sysinfo-gui` application wrapper**

Python PyQt5 WebEngine app window (850x600 resolution) loading `http://127.0.0.1:<port>/sysinfo.html`.

- [ ] **Step 3: Test syntax and permissions**

Run: `chmod +x src/eclipse-sysinfo-gui && python3 -m py_compile src/eclipse-sysinfo-gui`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add src/ui/sysinfo.html src/eclipse-sysinfo-gui
git commit -m "feat: add standalone system info GUI app"
```

---

### Task 3: Standalone OS Installer Application (`src/ui/installer.html` & `src/eclipse-installer-gui`)

**Files:**
- Create: `src/ui/installer.html`
- Create: `src/eclipse-installer-gui`

**Interfaces:**
- Consumes: `/api/disks`, `/api/install` from `eclipse_backend.py`
- Produces: Live-to-disk installation wizard window

- [ ] **Step 1: Write `src/ui/installer.html`**

Clean step-by-step wizard:
- Step 1: Disk selection (interactive cards showing disk node, model, capacity, partition layout).
- Step 2: System credentials (hostname, admin username, password).
- Step 3: Confirmation modal detailing target formatting (GPT, 512MB EFI, Ext4 Root).
- Step 4: Progress bar with terminal log stream output showing partitioning, rsync, and GRUB installation.
- Step 5: Success screen with reboot prompt.

- [ ] **Step 2: Write `src/eclipse-installer-gui` application wrapper**

Python PyQt5 WebEngine app window (950x650 resolution) loading `http://127.0.0.1:<port>/installer.html`.

- [ ] **Step 3: Test syntax and permissions**

Run: `chmod +x src/eclipse-installer-gui && python3 -m py_compile src/eclipse-installer-gui`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add src/ui/installer.html src/eclipse-installer-gui
git commit -m "feat: add standalone OS installer GUI app"
```

---

### Task 4: Standalone Driver Manager Application (`src/ui/drivers.html` & `src/eclipse-driver-manager-gui`)

**Files:**
- Create: `src/ui/drivers.html`
- Create: `src/eclipse-driver-manager-gui`

**Interfaces:**
- Consumes: `/api/drivers`, `/api/drivers/install` from `eclipse_backend.py`
- Produces: Hardware driver management application window

- [ ] **Step 1: Write `src/ui/drivers.html`**

Hardware driver card grid:
- Detected Hardware banner (e.g. "NVIDIA Corporation GA106 [GeForce RTX 3060]").
- Radio list of drivers:
  - Nouveau Open-Source Driver (Default)
  - NVIDIA Proprietary Driver (`nvidia-driver`)
  - AMDGPU Open-Source Driver
  - Intel Media Driver
- Action button: "Apply Driver Changes" with installation terminal log output.

- [ ] **Step 2: Write `src/eclipse-driver-manager-gui` application wrapper**

Python PyQt5 WebEngine app window (900x600 resolution) loading `http://127.0.0.1:<port>/drivers.html`.

- [ ] **Step 3: Test syntax and permissions**

Run: `chmod +x src/eclipse-driver-manager-gui && python3 -m py_compile src/eclipse-driver-manager-gui`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add src/ui/drivers.html src/eclipse-driver-manager-gui
git commit -m "feat: add standalone driver manager GUI app"
```

---

### Task 5: Unified Eclipse Control Center Hub (`src/ui/hub.html` & `src/eclipse-os-hub`)

**Files:**
- Create: `src/ui/hub.html`
- Modify: `src/eclipse-os-hub.py`

**Interfaces:**
- Consumes: All backend API endpoints
- Produces: Integrated desktop control center with sidebar navigation to SysInfo, Installer, and Drivers

- [ ] **Step 1: Write `src/ui/hub.html`**

Sidebar workspace layout:
- Left sidebar: App logo, links to System Telemetry, Disk Installer, Hardware Drivers, Developer Toolchain.
- Main area: Embedded views for all tools with seamless tab switching.

- [ ] **Step 2: Update `src/eclipse-os-hub.py` to route to `hub.html` and spawn server**

- [ ] **Step 3: Test syntax**

Run: `python3 -m py_compile src/eclipse-os-hub.py`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add src/ui/hub.html src/eclipse-os-hub.py
git commit -m "feat: add unified eclipse control hub"
```

---

### Task 6: Desktop Launcher Entries & Rootfs Provisioning (`scripts/02-configure.sh`)

**Files:**
- Create: `config/desktop/eclipse-sysinfo.desktop`
- Create: `config/desktop/eclipse-installer.desktop`
- Create: `config/desktop/eclipse-driver-manager.desktop`
- Modify: `config/desktop/eclipse-os-hub.desktop`
- Modify: `scripts/02-configure.sh`

- [ ] **Step 1: Create desktop shortcut files in `config/desktop/`**

Define proper `Name`, `Exec`, `Icon`, `Categories`, and `Terminal=false` for all 4 GUI apps.

- [ ] **Step 2: Update `scripts/02-configure.sh` to deploy executables and shortcuts**

Copy `src/eclipse-sysinfo-gui`, `src/eclipse-installer-gui`, `src/eclipse-driver-manager-gui`, `src/eclipse-os-hub`, and `src/ui/*` into `/usr/local/bin/` and `/usr/share/applications/`.

- [ ] **Step 3: Verify script syntax**

Run: `bash -n scripts/02-configure.sh`
Expected: PASS

- [ ] **Step 4: Commit and push**

```bash
git add config/desktop/ scripts/02-configure.sh
git commit -m "feat: provision standalone GUI app shortcuts"
git push origin main
```
