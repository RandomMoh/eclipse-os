# Pure KDE Plasma Desktop Clean Migration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Completely purge all residual XFCE configuration files, remove LightDM configuration overrides, lock Dolphin (`org.kde.dolphin.desktop`) as system default file manager, update system `x-session-manager` alternatives to `startplasma-x11`, and configure SDDM as the sole display manager.

**Architecture:** Update `scripts/02-configure.sh` to remove `/etc/lightdm`, remove `/etc/xdg/xfce4`, remove all XFCE autostart entries, write default `mimeapps.list` locking Dolphin as file manager, set system alternatives `x-session-manager` -> `/usr/bin/startplasma-x11`, and rebuild the live ISO.

**Tech Stack:** Debian 12 Bookworm, KDE Plasma 5 (`plasma-workspace`, `kwin-x11`), Dolphin (`dolphin`), SDDM (`sddm`), Bash, Python 3.

## Global Constraints

- Commit messages MUST be strictly 3-4 plain words without prefixes (`feat:`, `fix:`, `docs:`) or meta text.
- Do NOT use em dashes (`—` / `–`) or AI jargon words.
- All code MUST be clean without redundant comments.
- All files MUST be created inside `/home/mohs/eclipse-os`.

---

### Task 1: Purge Residual XFCE Configs & Set Dolphin MIME Association (`scripts/02-configure.sh`)

**Files:**
- Modify: `scripts/02-configure.sh`

**Interfaces:**
- Removes `/etc/lightdm`, `/etc/xdg/xfce4`, `/etc/skel/.config/xfce4`, `/home/eclipse/.config/xfce4`.
- Writes `/etc/skel/.config/mimeapps.list` and `/home/eclipse/.config/mimeapps.list` locking `inode/directory=org.kde.dolphin.desktop` and `text/html=zen-browser.desktop`.
- Updates `update-alternatives` for `x-session-manager` to `/usr/bin/startplasma-x11`.

- [ ] **Step 1: Remove XFCE directory references in `scripts/02-configure.sh`**

  Replace all XFCE directory provisioning with clean KDE Plasma directory provisioning.

- [ ] **Step 2: Add Dolphin MIME association in `scripts/02-configure.sh`**

  ```bash
  mkdir -p "$ROOTFS/etc/skel/.config"
  cat <<'EOF' > "$ROOTFS/etc/skel/.config/mimeapps.list"
  [Default Applications]
  inode/directory=org.kde.dolphin.desktop
  text/html=zen-browser.desktop
  x-scheme-handler/http=zen-browser.desktop
  x-scheme-handler/https=zen-browser.desktop
  EOF
  ```

- [ ] **Step 3: Update `x-session-manager` alternatives in `scripts/02-configure.sh`**

  ```bash
  chroot "$ROOTFS" update-alternatives --set x-session-manager /usr/bin/startplasma-x11 2>/dev/null || true
  rm -rf "$ROOTFS/etc/lightdm" 2>/dev/null || true
  rm -f "$ROOTFS/lib/live/config/0100-lightdm" "$ROOTFS/usr/lib/live/config/0100-lightdm" 2>/dev/null || true
  ```

- [ ] **Step 4: Commit `scripts/02-configure.sh` updates**

  Run: `git add scripts/02-configure.sh && git commit -m "purge xfce residual configs" && git push origin main`

---

### Task 2: Rebuild Rootfs & Package Clean KDE ISO

- [ ] **Step 1: Execute `scripts/02-configure.sh` inside rootfs**

  Run: `echo '230907' | sudo -S bash scripts/02-configure.sh`

- [ ] **Step 2: Execute `scripts/03-package-iso.sh` to generate output ISO**

  Run: `echo '230907' | sudo -S bash scripts/03-package-iso.sh`

- [ ] **Step 3: Verify output ISO existence and size**

  Run: `ls -lh build/output/eclipse-os-v1.0-x86_64.iso`

---

### Task 3: Empirical Verification Protocol

- [ ] **Step 1: Run Python syntax & compilation check**

  Run: `python3 -m py_compile src/eclipse-sysinfo src/eclipse-control src/eclipse-installer src/eclipse-dock src/dnf`

- [ ] **Step 2: Run bash script syntax check**

  Run: `bash -n scripts/01-bootstrap.sh && bash -n scripts/02-configure.sh && bash -n scripts/03-package-iso.sh && bash -n scripts/04-test-qemu.sh`

- [ ] **Step 3: Run git repository status check**

  Run: `git status && git log -n 4 --oneline`

- [ ] **Step 4: Launch QEMU test**

  Run: `bash scripts/04-test-qemu.sh`
