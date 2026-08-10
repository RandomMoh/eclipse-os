# Eclipse OS Crimson Theme & Branding Redesign Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform Eclipse OS visual identity from generic Debian defaults into a polished, customizable Obsidian & Crimson Red theme suite with non-AI minimalist branding, Papirus icon system, and Linux Mint style theme switcher.

**Architecture:** Create multi-accent GTK3 themes (`Eclipse-Crimson`, `Eclipse-Dark`, `Eclipse-Cyan`, `Eclipse-Emerald`) in `/usr/share/themes/`, generate high-resolution 1080p Crimson Eclipse wallpaper, update native Python utilities (`eclipse-sysinfo`, `eclipse-control`, `eclipse-installer`) with handcrafted ASCII logo & crimson palette, and integrate `papirus-icon-theme` into XFCE settings.

**Tech Stack:** GTK 3.0 CSS, Python 3 (Pillow / Rich), XFCE4 Xfconf XML, Papirus Icon Theme, bash, mksquashfs, xorriso.

## Global Constraints

- Commit messages MUST be strictly 3-4 plain words without prefixes (`feat:`, `fix:`, `docs:`) or meta text.
- Do NOT use em dashes (`—` / `–`) or AI jargon words (`pivotal`, `testament`, `vibrant`, `landscape`, `tapestry`).
- GTK theme, accent colors, controls, and icon sets MUST be 100% customizable via XFCE Settings -> Appearance (Mint style).
- All files MUST be created inside `/home/mohs/eclipse-os`.

---

### Task 1: Generate Crimson Solar Eclipse Wallpaper & Vector Logos

**Files:**
- Create: `config/wallpaper/eclipse-wallpaper.png`
- Create: `config/logo/eclipse-logo.png`
- Create: `config/grub/eclipse-grub-theme/logo.png`
- Test: `python3 -c "from PIL import Image; img=Image.open('config/wallpaper/eclipse-wallpaper.png'); print(img.size)"`

**Interfaces:**
- Produces: `config/wallpaper/eclipse-wallpaper.png` (1920x1080 wallpaper with dark obsidian background `#0A0809` and glowing crimson eclipse corona `#E11D48` / `#F43F5E`)
- Produces: `config/logo/eclipse-logo.png` & `config/grub/eclipse-grub-theme/logo.png` (256x256 vector logo for GRUB bootup, LightDM, XFCE panel, and desktop applications)

- [ ] **Step 1: Write wallpaper and logo generator Python script**

Create temporary script `scripts/generate_assets.py` using Pillow to render the 1080p Crimson Eclipse wallpaper and 256x256 logo PNGs.

```python
import math
from PIL import Image, ImageDraw, ImageFilter, ImageFont

def generate_wallpaper():
    w, h = 1920, 1080
    img = Image.new("RGB", (w, h), "#0A0809")
    draw = ImageDraw.Draw(img)

    # Base radial glow
    cx, cy = w // 2, h // 2
    max_r = int(math.hypot(w, h))

    for r in range(max_r, 0, -20):
        factor = 1.0 - (r / max_r)
        red = int(10 + 215 * (factor ** 3))
        green = int(8 + 21 * (factor ** 4))
        blue = int(9 + 30 * (factor ** 4))
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(red, green, blue))

    img = img.filter(ImageFilter.GaussianBlur(radius=15))
    draw = ImageDraw.Draw(img)

    # Corona flares
    num_flares = 72
    for i in range(num_flares):
        angle = (i / num_flares) * 2 * math.pi
        length = 180 + (i * 37 % 140)
        x2 = cx + int(length * math.cos(angle))
        y2 = cy + int(length * math.sin(angle))
        draw.line([cx, cy, x2, y2], fill="#E11D48", width=3)

    img = img.filter(ImageFilter.GaussianBlur(radius=8))
    draw = ImageDraw.Draw(img)

    # Outer corona ring
    draw.ellipse([cx - 180, cy - 180, cx + 180, cy + 180], fill="#F43F5E")
    img = img.filter(ImageFilter.GaussianBlur(radius=6))
    draw = ImageDraw.Draw(img)

    # Inner obsidian moon disc
    draw.ellipse([cx - 165, cy - 165, cx + 165, cy + 165], fill="#0A0809")

    # Thin rim arc
    draw.arc([cx - 167, cy - 167, cx + 167, cy + 167], start=30, end=210, fill="#FDA4AF", width=3)

    img.save("config/wallpaper/eclipse-wallpaper.png", "PNG")

def generate_logo():
    s = 256
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = s // 2, s // 2

    draw.ellipse([cx - 110, cy - 110, cx + 110, cy + 110], fill="#E11D48")
    img = img.filter(ImageFilter.GaussianBlur(radius=4))
    draw = ImageDraw.Draw(img)

    draw.ellipse([cx - 100, cy - 100, cx + 100, cy + 100], fill="#F43F5E")
    draw.ellipse([cx - 92, cy - 92, cx + 92, cy + 92], fill="#0F0D0E")
    draw.arc([cx - 93, cy - 93, cx + 93, cy + 93], start=45, end=225, fill="#FDA4AF", width=3)

    img.save("config/logo/eclipse-logo.png", "PNG")

if __name__ == "__main__":
    generate_wallpaper()
    generate_logo()
```

- [ ] **Step 2: Execute asset generator and verify images**

Run: `python3 scripts/generate_assets.py && rm -f scripts/generate_assets.py`
Expected: `config/wallpaper/eclipse-wallpaper.png` (1920x1080) and `config/logo/eclipse-logo.png` (256x256) created cleanly.

- [ ] **Step 3: Commit assets**

Run: `git add config/wallpaper/eclipse-wallpaper.png config/logo/eclipse-logo.png && git commit -m "add crimson wallpaper assets" && git push origin main`

---

### Task 2: Create Multi-Accent GTK3 Themes & XFCE Papirus Icon System

**Files:**
- Create: `config/gtk/themes/Eclipse-Crimson/gtk-3.0/gtk.css`
- Create: `config/gtk/themes/Eclipse-Dark/gtk-3.0/gtk.css`
- Create: `config/gtk/themes/Eclipse-Cyan/gtk-3.0/gtk.css`
- Create: `config/gtk/themes/Eclipse-Emerald/gtk-3.0/gtk.css`
- Modify: `config/xfce/xfce-perchannel-xml/xsettings.xml`
- Modify: `config/xfce/xfce-perchannel-xml/xfwm4.xml`

**Interfaces:**
- Consumes: GTK 3.0 CSS theme specification
- Produces: 4 full GTK3 themes in `config/gtk/themes/` installable to `/usr/share/themes/`
- Produces: XFCE settings configured to `Eclipse-Crimson` GTK theme, `Papirus-Dark` icons, and `Eclipse-Crimson` window manager borders.

- [ ] **Step 1: Write GTK3 theme definitions for Eclipse-Crimson**

Write `config/gtk/themes/Eclipse-Crimson/gtk-3.0/gtk.css`:
```css
@define-color accent_color #E11D48;
@define-color highlight_color #F43F5E;
@define-color theme_bg_color #0F0D0E;
@define-color theme_fg_color #F1F5F9;
@define-color theme_base_color #1A1114;
@define-color theme_text_color #F8FAFC;
@define-color theme_selected_bg_color #E11D48;
@define-color theme_selected_fg_color #FFFFFF;
@define-color wm_title_active #F43F5E;
@define-color wm_bg_active #1A1114;

window, .top-bar, headerbar {
    background-color: @theme_bg_color;
    color: @theme_fg_color;
}

button {
    background-color: #241418;
    color: #F8FAFC;
    border: 1px solid #3F1D26;
    border-radius: 6px;
    padding: 6px 12px;
}

button:hover {
    background-color: #E11D48;
    color: #FFFFFF;
}

button:active, button:checked {
    background-color: #9F1239;
    color: #FFFFFF;
}

entry, textview {
    background-color: #1A1114;
    color: #F8FAFC;
    border: 1px solid #3F1D26;
    border-radius: 6px;
}

entry:focus {
    border-color: #F43F5E;
}
```

- [ ] **Step 2: Create remaining 3 theme variants (`Eclipse-Dark`, `Eclipse-Cyan`, `Eclipse-Emerald`)**

Write matching `gtk.css` for each variant with respective accent colors (`#8B5CF6`, `#06B6D4`, `#10B981`).

- [ ] **Step 3: Update XFCE settings for Papirus-Dark icons & Crimson theme default**

Update `config/xfce/xfce-perchannel-xml/xsettings.xml`:
Set `Net/ThemeName` to `Eclipse-Crimson` and `Net/IconThemeName` to `Papirus-Dark`.

Update `config/xfce/xfce-perchannel-xml/xfwm4.xml`:
Set `theme` to `Eclipse-Crimson`.

- [ ] **Step 4: Commit theme suite**

Run: `git add config/gtk/ config/xfce/ && git commit -m "add crimson gtk themes" && git push origin main`

---

### Task 3: Redesign Python Utilities with Non-AI Minimalist ASCII Branding

**Files:**
- Modify: `src/eclipse-sysinfo`
- Modify: `src/eclipse-control`
- Modify: `src/eclipse-installer`

**Interfaces:**
- Consumes: `rich` library formatting
- Produces: Redesigned CLI utilities with Crimson `#E11D48` & Ruby `#F43F5E` palette, handcrafted non-AI ASCII logo, and multi-theme switcher (`crimson`, `dark`, `cyan`, `emerald`).

- [ ] **Step 1: Update ASCII logo and palette in `src/eclipse-sysinfo`**

Replace ASCII logo with handcrafted minimalist Syzygy banner and update colors to Crimson Red `#E11D48` and Ruby `#F43F5E`.

- [ ] **Step 2: Update `src/eclipse-control` theme engine**

Add `crimson`, `emerald`, `dark`, `cyan` choices to `eclipse-control theme <name>` subcommand. Update `cmd_status` to display Papirus icon theme status and active GTK theme.

- [ ] **Step 3: Update `src/eclipse-installer` styling**

Update TUI header panel and borders to Crimson Red `#E11D48`.

- [ ] **Step 4: Verify Python syntax**

Run: `python3 -m py_compile src/eclipse-sysinfo src/eclipse-control src/eclipse-installer`
Expected: Exit code 0 with clean compilation.

- [ ] **Step 5: Commit utility updates**

Run: `git add src/ && git commit -m "update crimson python utilities" && git push origin main`

---

### Task 4: Update System Provisioning Script (`scripts/02-configure.sh`)

**Files:**
- Modify: `scripts/02-configure.sh`

**Interfaces:**
- Consumes: GTK themes from `config/gtk/themes/`
- Produces: Installed themes in `$ROOTFS/usr/share/themes/`, `papirus-icon-theme` package, updated wallpaper in `/usr/share/backgrounds/eclipse/`, and default user settings.

- [ ] **Step 1: Add `papirus-icon-theme` to APT package installation list**

Add `papirus-icon-theme` to `apt-get install` inside chroot.

- [ ] **Step 2: Provision all GTK themes to `/usr/share/themes/`**

Copy `config/gtk/themes/*` to `$ROOTFS/usr/share/themes/`. Set default GTK theme to `Eclipse-Crimson` in `/etc/skel/.config/gtk-3.0/gtk.css`.

- [ ] **Step 3: Verify script syntax**

Run: `bash -n scripts/02-configure.sh`
Expected: Exit code 0.

- [ ] **Step 4: Commit configure script**

Run: `git add scripts/02-configure.sh && git commit -m "add papirus icon provisioning" && git push origin main`

---

### Task 5: Build ISO & Empirical Verification

**Files:**
- Output: `build/output/eclipse-os-v1.0-x86_64.iso`

- [ ] **Step 1: Execute system configuration inside rootfs**

Run: `echo '230907' | sudo -S bash scripts/02-configure.sh`
Expected: Exit code 0, clean provisioning of themes, wallpaper, and Papirus icons.

- [ ] **Step 2: Package final ISO image**

Run: `echo '230907' | sudo -S bash scripts/03-package-iso.sh`
Expected: Exit code 0, ISO generated at `build/output/eclipse-os-v1.0-x86_64.iso` (~1.7-1.8 GB).

- [ ] **Step 3: Verify ISO existence and size**

Run: `ls -lh build/output/eclipse-os-v1.0-x86_64.iso`
Expected: ISO file present and non-zero size.

- [ ] **Step 4: Launch QEMU test**

Run: `bash scripts/04-test-qemu.sh`
Expected: QEMU launches cleanly into XFCE desktop with Obsidian Crimson theme, Papirus icons, and solar eclipse wallpaper.
