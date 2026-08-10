# Custom Native Eclipse Dock (`eclipse-dock`) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a lightweight, high-performance custom native dock (`src/eclipse-dock`) in Python 3 using PyGObject GTK3. Replace XFCE's laggy Panel 2 autohide with a smooth, hardware-accelerated floating glass pill dock featuring mouse hover zoom animations, active window indicators, and launcher shortcuts.

**Architecture:** Create `src/eclipse-dock` executable GTK3 script, autostart desktop entry `/etc/xdg/autostart/eclipse-dock.desktop`, update XFCE panel config to remove Panel 2 (keeping only Panel 1 top bar), update `scripts/02-configure.sh`, and rebuild live ISO.

**Tech Stack:** Python 3, PyGObject (`gi.repository.Gtk`, `Gdk`, `Pango`, `GLib`), GTK 3.0 CSS, XFCE Autostart, bash, mksquashfs, xorriso.

## Global Constraints

- Commit messages MUST be strictly 3-4 plain words without prefixes (`feat:`, `fix:`, `docs:`) or meta text.
- Do NOT use em dashes (`—` / `–`) or AI jargon words.
- Dock MUST be custom made without third-party Plank/Cairo-dock packages.
- All code MUST be clean without redundant comments.
- All files MUST be created inside `/home/mohs/eclipse-os`.

---

### Task 1: Create Custom Native GTK3 Dock Utility (`src/eclipse-dock`)

**Files:**
- Create: `src/eclipse-dock`
- Test: `python3 -m py_compile src/eclipse-dock`

**Interfaces:**
- Produces: `src/eclipse-dock` (Custom PyGObject GTK3 dock executable with floating glass capsule window `_NET_WM_WINDOW_TYPE_DOCK`, smooth hover zoom animation, active app indicator dots, and launcher execution)

- [ ] **Step 1: Write `src/eclipse-dock`**

```python
#!/usr/bin/env python3

import os
import sys
import subprocess
import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
from gi.repository import Gtk, Gdk, GLib, GdkPixbuf

DOCK_LAUNCHERS = [
    {"name": "Zen Browser", "cmd": "zen-browser", "icon": "zen-browser", "fallback_icon": "web-browser"},
    {"name": "Kate", "cmd": "kate", "icon": "kate", "fallback_icon": "accessories-text-editor"},
    {"name": "VS Code", "cmd": "code", "icon": "vscode", "fallback_icon": "com.visualstudio.code"},
    {"name": "Files", "cmd": "thunar", "icon": "system-file-manager", "fallback_icon": "folder"},
    {"name": "Terminal", "cmd": "xfce4-terminal", "icon": "utilities-terminal", "fallback_icon": "terminal"},
    {"name": "SysInfo", "cmd": "xfce4-terminal --hold -e eclipse-sysinfo", "icon": "utilities-system-monitor", "fallback_icon": "system-search"},
    {"name": "Installer", "cmd": "xfce4-terminal -e 'sudo eclipse-installer'", "icon": "system-software-install", "fallback_icon": "system-run"},
]

CSS_STYLE = """
#eclipse-dock-window {
    background: transparent;
}

#eclipse-dock-container {
    background-color: rgba(26, 27, 38, 0.88);
    border: 1px solid rgba(255, 255, 255, 0.14);
    border-radius: 24px;
    padding: 6px 14px;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
}

.dock-item-btn {
    background: transparent;
    border: none;
    padding: 4px 6px;
    margin: 0 2px;
    border-radius: 14px;
    transition: all 120ms cubic-bezier(0.32, 0.72, 0, 1);
}

.dock-item-btn:hover {
    background-color: rgba(53, 132, 228, 0.22);
}

.dock-indicator {
    background-color: #3584E4;
    border-radius: 2px;
    min-height: 4px;
    min-width: 12px;
    margin-top: 2px;
}
"""

class DockItem(Gtk.EventBox):
    def __init__(self, launcher):
        super().__init__()
        self.launcher = launcher
        self.set_visible_window(False)

        self.box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        self.box.set_halign(Gtk.Align.CENTER)

        self.image = Gtk.Image()
        self.normal_size = 40
        self.hover_size = 52
        self.current_size = self.normal_size

        self.load_icon(self.normal_size)
        self.box.pack_start(self.image, False, False, 0)

        self.indicator = Gtk.Box()
        self.indicator.get_style_context().add_class("dock-indicator")
        self.indicator.set_no_show_all(True)
        self.box.pack_start(self.indicator, False, False, 0)

        self.add(self.box)
        self.set_tooltip_text(launcher["name"])

        self.connect("button-press-event", self.on_click)
        self.connect("enter-notify-event", self.on_enter)
        self.connect("leave-notify-event", self.on_leave)

    def load_icon(self, size):
        icon_theme = Gtk.IconTheme.get_default()
        icon_name = self.launcher["icon"]
        if not icon_theme.has_icon(icon_name):
            icon_name = self.launcher["fallback_icon"]

        try:
            pixbuf = icon_theme.load_icon(icon_name, size, Gtk.IconLookupFlags.FORCE_SIZE)
            self.image.set_from_pixbuf(pixbuf)
        except Exception:
            self.image.set_from_icon_name("application-x-executable", Gtk.IconSize.DOCK)

    def animate_scale(self, target_size):
        self.current_size = target_size
        self.load_icon(target_size)

    def on_enter(self, widget, event):
        self.animate_scale(self.hover_size)
        return False

    def on_leave(self, widget, event):
        self.animate_scale(self.normal_size)
        return False

    def on_click(self, widget, event):
        if event.button == 1:
            try:
                subprocess.Popen(self.launcher["cmd"], shell=True)
            except Exception:
                pass
        return True

class EclipseDock(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_name("eclipse-dock-window")
        self.set_type_hint(Gdk.WindowTypeHint.DOCK)
        self.set_keep_above(True)
        self.set_decorated(False)
        self.set_resizable(False)
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)

        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)

        self.apply_css()

        self.container = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        self.container.set_name("eclipse-dock-container")

        for item_data in DOCK_LAUNCHERS:
            item = DockItem(item_data)
            self.container.pack_start(item, False, False, 0)

        main_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        main_box.pack_start(self.container, False, False, 0)
        self.add(main_box)

        self.connect("realize", self.on_realize)
        self.connect("destroy", Gtk.main_quit)

    def apply_css(self):
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS_STYLE.encode("utf-8"))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def on_realize(self, widget):
        screen = self.get_screen()
        monitor_geom = screen.get_monitor_geometry(screen.get_primary_monitor() or 0)
        
        self.show_all()
        req_w, req_h = self.get_size()
        
        x = monitor_geom.x + (monitor_geom.width - req_w) // 2
        y = monitor_geom.y + monitor_geom.height - req_h - 12
        self.move(x, y)

def main():
    dock = EclipseDock()
    Gtk.main()

if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Add executable permissions and verify Python compilation**

Run: `chmod +x src/eclipse-dock && python3 -m py_compile src/eclipse-dock`
Expected: Exit code 0.

- [ ] **Step 3: Commit custom dock executable**

Run: `git add src/eclipse-dock && git commit -m "add custom native dock" && git push origin main`

---

### Task 2: Configure Autostart & Single Panel Architecture in XFCE

**Files:**
- Create: `config/autostart/eclipse-dock.desktop`
- Modify: `config/xfce/xfce-perchannel-xml/xfce4-panel.xml`

**Interfaces:**
- Consumes: XFCE panel XML configuration
- Produces: Single top panel configuration (Panel 1) and autostart entry for `eclipse-dock`

- [ ] **Step 1: Write `config/autostart/eclipse-dock.desktop`**

```ini
[Desktop Entry]
Type=Application
Name=Eclipse Dock
Comment=Custom native floating glass dock for Eclipse OS
Exec=eclipse-dock
OnlyShowIn=XFCE;GNOME;KDE;
RunHook=0
StartupNotify=false
Terminal=false
```

- [ ] **Step 2: Update `config/xfce/xfce-perchannel-xml/xfce4-panel.xml` to keep only Panel 1**

Remove Panel 2 (bottom panel) from `xfce4-panel.xml`, leaving only Panel 1 at the top of the screen (`position="p=6;x=0;y=0"`, full width).

- [ ] **Step 3: Commit panel & autostart updates**

Run: `git add config/autostart/ config/xfce/ && git commit -m "update panel autostart config" && git push origin main`

---

### Task 3: Update System Provisioning Script (`scripts/02-configure.sh`)

**Files:**
- Modify: `scripts/02-configure.sh`

**Interfaces:**
- Consumes: `src/eclipse-dock` and `config/autostart/eclipse-dock.desktop`
- Produces: Executable `/usr/local/bin/eclipse-dock` and autostart `/etc/xdg/autostart/eclipse-dock.desktop` inside rootfs.

- [ ] **Step 1: Modify `scripts/02-configure.sh` to copy `eclipse-dock` and autostart configuration**

Copy `src/eclipse-dock` to `$ROOTFS/usr/local/bin/eclipse-dock` with `chmod +x`.
Copy `config/autostart/eclipse-dock.desktop` to `$ROOTFS/etc/xdg/autostart/eclipse-dock.desktop`.

- [ ] **Step 2: Commit configure script**

Run: `git add scripts/02-configure.sh && git commit -m "add dock to configure" && git push origin main`

---

### Task 4: Rebuild Rootfs & Live ISO

- [ ] **Step 1: Execute system configuration inside rootfs**

Run: `echo '230907' | sudo -S bash scripts/02-configure.sh`

- [ ] **Step 2: Package final ISO image**

Run: `echo '230907' | sudo -S bash scripts/03-package-iso.sh`

- [ ] **Step 3: Verify output ISO file**

Run: `ls -lh build/output/eclipse-os-v1.0-x86_64.iso`

---

### Task 5: Empirical Verification via QEMU

- [ ] **Step 1: Launch QEMU test**

Run: `bash scripts/04-test-qemu.sh`
Expected: QEMU boots into desktop with top status bar and bottom floating glass `eclipse-dock` with smooth icon hover zoom physics and clean launcher clicks.
