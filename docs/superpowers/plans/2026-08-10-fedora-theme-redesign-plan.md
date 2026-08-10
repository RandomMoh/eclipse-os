# Eclipse OS Fedora Edition Theme & Panel Redesign Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Completely redesign Eclipse OS visual identity to match Fedora Workstation (GNOME 46 / Adwaita Dark aesthetics). Replace the buggy red palette and panel with Fedora Blue (`#3584E4`), Adwaita Dark surfaces (`#1E1E1E` / `#2D2D2D`), a top GNOME-style status bar, and a floating glass bottom dock.

**Architecture:** Create `Eclipse-Fedora` GTK3 theme suite in `/usr/share/themes/`, generate high-resolution Fedora Blue Eclipse wallpaper, redesign XFCE panel layout for top bar + floating dash dock, update native Python utilities (`eclipse-sysinfo`, `eclipse-control`, `eclipse-installer`) with Fedora Blue palette, and integrate Papirus/Adwaita icon themes.

**Tech Stack:** GTK 3.0 CSS, Python 3 (Pillow / Rich), XFCE4 Xfconf XML (Panel & Xfwm4), Papirus / Adwaita Icon Theme, bash, mksquashfs, xorriso.

## Global Constraints

- Commit messages MUST be strictly 3-4 plain words without prefixes (`feat:`, `fix:`, `docs:`) or meta text.
- Do NOT use em dashes (`—` / `–`) or AI jargon words.
- All themes MUST be 100% customizable via XFCE Settings -> Appearance (Mint / Fedora style).
- All files MUST be created inside `/home/mohs/eclipse-os`.

---

### Task 1: Generate Fedora Blue Wallpaper & Vector Logos

**Files:**
- Create: `config/wallpaper/eclipse-wallpaper.png`
- Create: `config/logo/eclipse-logo.png`
- Create: `config/grub/eclipse-grub-theme/logo.png`
- Test: `python3 -c "from PIL import Image; img=Image.open('config/wallpaper/eclipse-wallpaper.png'); print(img.size)"`

**Interfaces:**
- Produces: `config/wallpaper/eclipse-wallpaper.png` (1920x1080 wallpaper with dark Adwaita charcoal background `#18181B` to `#0F172A` and glowing Fedora Blue `#3584E4` / `#62A0EA` corona)
- Produces: `config/logo/eclipse-logo.png` & `config/grub/eclipse-grub-theme/logo.png` (256x256 vector logo with Fedora Blue aesthetics)

- [ ] **Step 1: Write Python script for Fedora wallpaper and logo generation**

Write `scripts/generate_fedora_assets.py`:
```python
import math
from PIL import Image, ImageDraw, ImageFilter

def generate_wallpaper():
    w, h = 1920, 1080
    img = Image.new("RGB", (w, h), "#121318")
    draw = ImageDraw.Draw(img)

    # Base radial glow with Fedora Blue (#3584E4)
    cx, cy = w // 2, h // 2
    max_r = int(math.hypot(w, h))

    for r in range(max_r, 0, -20):
        factor = 1.0 - (r / max_r)
        red = int(18 + 35 * (factor ** 4))
        green = int(19 + 132 * (factor ** 3))
        blue = int(24 + 228 * (factor ** 2.5))
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(red, green, blue))

    img = img.filter(ImageFilter.GaussianBlur(radius=18))
    draw = ImageDraw.Draw(img)

    # Corona flares
    num_flares = 72
    for i in range(num_flares):
        angle = (i / num_flares) * 2 * math.pi
        length = 180 + (i * 37 % 140)
        x2 = cx + int(length * math.cos(angle))
        y2 = cy + int(length * math.sin(angle))
        draw.line([cx, cy, x2, y2], fill="#3584E4", width=3)

    img = img.filter(ImageFilter.GaussianBlur(radius=8))
    draw = ImageDraw.Draw(img)

    # Outer corona ring
    draw.ellipse([cx - 180, cy - 180, cx + 180, cy + 180], fill="#62A0EA")
    img = img.filter(ImageFilter.GaussianBlur(radius=6))
    draw = ImageDraw.Draw(img)

    # Inner charcoal moon disc
    draw.ellipse([cx - 165, cy - 165, cx + 165, cy + 165], fill="#121318")

    # Thin rim arc
    draw.arc([cx - 167, cy - 167, cx + 167, cy + 167], start=30, end=210, fill="#99C1F1", width=3)

    img.save("config/wallpaper/eclipse-wallpaper.png", "PNG")

def generate_logo():
    s = 256
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = s // 2, s // 2

    draw.ellipse([cx - 110, cy - 110, cx + 110, cy + 110], fill="#3584E4")
    img = img.filter(ImageFilter.GaussianBlur(radius=4))
    draw = ImageDraw.Draw(img)

    draw.ellipse([cx - 100, cy - 100, cx + 100, cy + 100], fill="#62A0EA")
    draw.ellipse([cx - 92, cy - 92, cx + 92, cy + 92], fill="#1E1E1E")
    draw.arc([cx - 93, cy - 93, cx + 93, cy + 93], start=45, end=225, fill="#99C1F1", width=3)

    img.save("config/logo/eclipse-logo.png", "PNG")
    img.save("config/grub/eclipse-grub-theme/logo.png", "PNG")

if __name__ == "__main__":
    generate_wallpaper()
    generate_logo()
```

- [ ] **Step 2: Execute generator and verify assets**

Run: `python3 scripts/generate_fedora_assets.py && rm -f scripts/generate_fedora_assets.py`

- [ ] **Step 3: Commit assets**

Run: `git add config/wallpaper/eclipse-wallpaper.png config/logo/eclipse-logo.png config/grub/eclipse-grub-theme/logo.png && git commit -m "add fedora blue assets" && git push origin main`

---

### Task 2: Create Fedora GTK3 Themes & GNOME Style Panel Architecture

**Files:**
- Create: `config/gtk/themes/Eclipse-Fedora/gtk-3.0/gtk.css`
- Create: `config/gtk/themes/Eclipse-AdwaitaDark/gtk-3.0/gtk.css`
- Create: `config/gtk/themes/Eclipse-CyberCyan/gtk-3.0/gtk.css`
- Create: `config/gtk/themes/Eclipse-Emerald/gtk-3.0/gtk.css`
- Modify: `config/xfce/xfce-perchannel-xml/xfce4-panel.xml`
- Modify: `config/xfce/xfce-perchannel-xml/xsettings.xml`
- Modify: `config/xfce/xfce-perchannel-xml/xfwm4.xml`
- Modify: `config/grub/eclipse-grub-theme/theme.txt`

**Interfaces:**
- Consumes: GTK3 CSS & XFCE Panel configuration
- Produces: Fedora Adwaita GTK3 themes in `/usr/share/themes/`
- Produces: GNOME Workstation style top panel bar and floating dash dock bottom panel

- [ ] **Step 1: Write `Eclipse-Fedora` GTK3 CSS**

Write `config/gtk/themes/Eclipse-Fedora/gtk-3.0/gtk.css`:
```css
@define-color accent_color #3584E4;
@define-color highlight_color #62A0EA;
@define-color theme_bg_color #1E1E1E;
@define-color theme_fg_color #FFFFFF;
@define-color theme_base_color #2D2D2D;
@define-color theme_text_color #FFFFFF;
@define-color theme_selected_bg_color #3584E4;
@define-color theme_selected_fg_color #FFFFFF;
@define-color wm_title_active #3584E4;
@define-color wm_bg_active #2D2D2D;

window, .top-bar, headerbar {
    background-color: #1E1E1E;
    color: #FFFFFF;
}

button {
    background-color: #303030;
    color: #FFFFFF;
    border: 1px solid #454545;
    border-radius: 8px;
    padding: 6px 14px;
}

button:hover {
    background-color: #3584E4;
    color: #FFFFFF;
}

button:active, button:checked {
    background-color: #1C71D8;
    color: #FFFFFF;
}

entry, textview {
    background-color: #252525;
    color: #FFFFFF;
    border: 1px solid #454545;
    border-radius: 8px;
}

entry:focus {
    border-color: #3584E4;
}

/* Floating Dock Styling */
.xfce4-panel {
    background-color: rgba(30, 30, 30, 0.92);
    border-radius: 12px;
}
```

- [ ] **Step 2: Create remaining theme variants (`Eclipse-AdwaitaDark`, `Eclipse-CyberCyan`, `Eclipse-Emerald`)**

- [ ] **Step 3: Update XFCE Panel XML for Fedora GNOME Layout**

Update `config/xfce/xfce-perchannel-xml/xfce4-panel.xml`:
- Panel 1 (Top Bar): Height 32px, full width (`length=100`), top of screen (`position="p=6;x=0;y=0"`). Items: Whisker Menu (Applications), Window Buttons (Tasks), Systray, Clock, Power.
- Panel 2 (Bottom Floating Dash Dock): Height 48px, centered (`length=40`, `position="p=10;x=0;y=0"`), autohide enabled. Launchers: Zen Browser, VS Code, Kate, SysInfo, Installer, Terminal.

- [ ] **Step 4: Update XFCE xsettings & xfwm4 for Fedora Theme**

Update `xsettings.xml` to `Eclipse-Fedora` GTK theme and `Papirus-Dark` icon theme.
Update `xfwm4.xml` to `Eclipse-Fedora` window manager theme.
Update `config/grub/eclipse-grub-theme/theme.txt` with Fedora Blue accent (`#3584E4`).

- [ ] **Step 5: Commit theme suite**

Run: `git add config/gtk/themes/ config/xfce/ config/grub/ && git commit -m "add fedora gtk themes" && git push origin main`

---

### Task 3: Redesign Python Utilities with Fedora Minimalist Branding

**Files:**
- Modify: `src/eclipse-sysinfo`
- Modify: `src/eclipse-control`
- Modify: `src/eclipse-installer`

**Interfaces:**
- Consumes: `rich` library formatting
- Produces: Redesigned CLI utilities with Fedora Blue `#3584E4` and Soft Cyan `#62A0EA` styling, clean ASCII banner, and Fedora theme switcher (`fedora`, `adwaita`, `cyan`, `emerald`).

- [ ] **Step 1: Update `src/eclipse-sysinfo` palette**

Update header styling, progress bars, and stats tables to Fedora Blue `#3584E4` and Soft Cyan `#62A0EA`.

- [ ] **Step 2: Update `src/eclipse-control` theme engine**

Set `fedora` (`#3584E4` accent, `Eclipse-Fedora` folder) as the default theme.

- [ ] **Step 3: Update `src/eclipse-installer` palette**

Update installer panel border and title styling to Fedora Blue `#3584E4`.

- [ ] **Step 4: Verify Python syntax**

Run: `python3 -m py_compile src/eclipse-sysinfo src/eclipse-control src/eclipse-installer`

- [ ] **Step 5: Commit utility updates**

Run: `git add src/ && git commit -m "update fedora python utilities" && git push origin main`

---

### Task 4: Update System Provisioning (`scripts/02-configure.sh`) & Package ISO

**Files:**
- Modify: `scripts/02-configure.sh`
- Output: `build/output/eclipse-os-v1.0-x86_64.iso`

- [ ] **Step 1: Modify `scripts/02-configure.sh` for Fedora defaults**

Set default theme to `Eclipse-Fedora` in skeleton `settings.ini` and user configuration.

- [ ] **Step 2: Commit configure script**

Run: `git add scripts/02-configure.sh && git commit -m "update fedora default theme" && git push origin main`

- [ ] **Step 3: Run rootfs provisioning & ISO packaging**

Run: `echo '230907' | sudo -S bash scripts/02-configure.sh`
Run: `echo '230907' | sudo -S bash scripts/03-package-iso.sh`

- [ ] **Step 4: Verify ISO existence and size**

Run: `ls -lh build/output/eclipse-os-v1.0-x86_64.iso`

---

### Task 5: Launch QEMU Test Verification

- [ ] **Step 1: Launch QEMU test**

Run: `bash scripts/04-test-qemu.sh`
Expected: QEMU launches cleanly into Fedora Adwaita Dark desktop with top GNOME status bar, floating dash dock, and Fedora Blue eclipse wallpaper.
