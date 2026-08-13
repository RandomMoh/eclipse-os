#!/usr/bin/env bash
set -euo pipefail

# Color helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Check root privileges
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: Must be run as root${RESET}" >&2
    exit 1
fi

# Determine project root dynamically
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"

# Ensure target rootfs exists
if [[ ! -d "$ROOTFS" ]]; then
    echo -e "${RED}Error: Target rootfs directory does not exist: ${ROOTFS}${RESET}" >&2
    echo -e "${YELLOW}Please run scripts/01-bootstrap.sh first.${RESET}" >&2
    exit 1
fi

# Cleanup function to unmount virtual filesystems
cleanup() {
    echo -e "${YELLOW}[*] Unmounting virtual filesystems...${RESET}"
    umount "$ROOTFS/dev/pts" 2>/dev/null || true
    umount "$ROOTFS/dev" 2>/dev/null || true
    umount "$ROOTFS/proc" 2>/dev/null || true
    umount "$ROOTFS/sys" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

echo -e "${BLUE}[+] Mounting virtual filesystems into rootfs...${RESET}"
mkdir -p "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/dev" "$ROOTFS/dev/pts"
mount --bind /proc "$ROOTFS/proc"
mount --bind /sys "$ROOTFS/sys"
mount -t devtmpfs devtmpfs "$ROOTFS/dev" 2>/dev/null || mount --bind /dev "$ROOTFS/dev"
mount -t devpts devpts "$ROOTFS/dev/pts" 2>/dev/null || mount --bind /dev/pts "$ROOTFS/dev/pts"

echo -e "${BLUE}[+] Writing hostname, hosts, and APT sources.list...${RESET}"
echo "eclipse-os" > "$ROOTFS/etc/hostname"

cat <<'EOF' > "$ROOTFS/etc/hosts"
127.0.0.1   localhost
127.0.1.1   eclipse-os

::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

cat <<'EOF' > "$ROOTFS/etc/apt/sources.list"
deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian/ bookworm-backports main contrib non-free non-free-firmware
EOF

echo -e "${YELLOW}[*] Updating APT package lists inside chroot...${RESET}"
chroot "$ROOTFS" env DEBIAN_FRONTEND=noninteractive apt-get update

# Add Microsoft VS Code repository
chroot "$ROOTFS" bash -c "
  apt-get install -y --no-install-recommends curl gpg ca-certificates apt-transport-https
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --yes --dearmor -o /etc/apt/keyrings/packages.microsoft.gpg
  echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main' > /etc/apt/sources.list.d/vscode.list
  apt-get update
"

echo -e "${YELLOW}[*] Installing backports kernel for modern hardware support...${RESET}"
chroot "$ROOTFS" env DEBIAN_FRONTEND=noninteractive apt-get install -y -t bookworm-backports --no-install-recommends \
    linux-image-amd64 \
    firmware-amd-graphics \
    firmware-linux \
    firmware-misc-nonfree \
    firmware-iwlwifi \
    firmware-realtek \
    firmware-atheros

echo -e "${YELLOW}[*] Installing required packages inside chroot...${RESET}"
chroot "$ROOTFS" env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    live-boot \
    live-config \
    systemd-sysv \
    network-manager \
    xorg \
    xserver-xorg \
    xserver-xorg-video-all \
    xserver-xorg-input-all \
    gpgv \
    bluez \
    bluez-tools \
    bluetooth \
    dbus-x11 \
    x11-xserver-utils \
    desktop-base \
    plymouth \
    plymouth-themes \
    initramfs-tools \
    kde-plasma-desktop \
    plasma-workspace \
    plasma-workspace-wayland \
    plasma-desktop \
    konsole \
    dolphin \
    kate \
    kwin-x11 \
    kwin-wayland \
    sddm \
    breeze \
    breeze-gtk-theme \
    plasma-widgets-addons \
    qml-module-qt-labs-platform \
    qml-module-org-kde-kquickcontrols \
    qml-module-org-kde-kquickcontrolsaddons \
    qml-module-org-kde-kirigami2 \
    qml-module-org-kde-kitemmodels \
    qml-module-qtquick-controls \
    qml-module-qtquick-controls2 \
    qml-module-qtquick-layouts \
    kio-extras \
    papirus-icon-theme \
    sudo \
    python3 \
    python3-pip \
    python3-rich \
    python3-pyqt5 \
    python3-pyqt5.qtwebengine \
    rsync \
    parted \
    dosfstools \
    e2fsprogs \
    grub-efi-amd64-bin \
    grub-pc-bin \
    kate \
    make \
    golang \
    cargo \
    rustc \
    podman \
    podman-docker \
    flatpak \
    ripgrep \
    fzf \
    jq \
    bat \
    lsof \
    kscreen \
    systemsettings \
    kde-config-screenlocker \
    kde-config-sddm \
    plasma-nm \
    apache2 \
    php \
    php-cli \
    php-mbstring \
    php-xml \
    php-curl \
    php-mysql \
    php-zip \
    mariadb-server \
    composer \
    nodejs \
    npm \
    neovim \
    vlc \
    tmux \
    zsh \
    htop \
    neofetch \
    curl \
    wget \
    git \
    gpg \
    apt-transport-https \
    code

echo -e "${BLUE}[+] Installing Zen Browser into /opt/zen...${RESET}"
mkdir -p "$ROOTFS/opt/zen"
curl -fsSL -o "$ROOTFS/tmp/zen.linux-x86_64.tar.xz" "https://github.com/zen-browser/desktop/releases/latest/download/zen.linux-x86_64.tar.xz" || \
curl -fsSL -o "$ROOTFS/tmp/zen.linux-x86_64.tar.xz" "https://github.com/zen-browser/desktop/releases/download/1.0.1-a.3/zen.linux-x86_64.tar.xz" || true

if [[ -f "$ROOTFS/tmp/zen.linux-x86_64.tar.xz" ]]; then
    tar -xf "$ROOTFS/tmp/zen.linux-x86_64.tar.xz" -C "$ROOTFS/opt/zen" --strip-components=1 2>/dev/null || tar -xf "$ROOTFS/tmp/zen.linux-x86_64.tar.xz" -C "$ROOTFS/opt/" 2>/dev/null || true
    rm -f "$ROOTFS/tmp/zen.linux-x86_64.tar.xz"
fi

mkdir -p "$ROOTFS/usr/local/bin"
if [[ -f "$ROOTFS/opt/zen/zen" ]]; then
    ln -sf /opt/zen/zen "$ROOTFS/usr/local/bin/zen-browser"
    chmod +x "$ROOTFS/opt/zen/zen" 2>/dev/null || true
elif [[ -f "$ROOTFS/opt/zen/zen-bin" ]]; then
    ln -sf /opt/zen/zen-bin "$ROOTFS/usr/local/bin/zen-browser"
    chmod +x "$ROOTFS/opt/zen/zen-bin" 2>/dev/null || true
fi

mkdir -p "$ROOTFS/usr/share/applications"
cat <<'EOF' > "$ROOTFS/usr/share/applications/zen-browser.desktop"
[Desktop Entry]
Version=1.0
Name=Zen Browser
Comment=Experience tranquility while browsing the web
Exec=/usr/local/bin/zen-browser %u
Terminal=false
Type=Application
Icon=/opt/zen/browser/chrome/icons/default/default128.png
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
EOF

mkdir -p "$ROOTFS/etc/skel/.config"
cat <<'EOF' > "$ROOTFS/etc/skel/.config/mimeapps.list"
[Default Applications]
text/html=zen-browser.desktop
x-scheme-handler/http=zen-browser.desktop
x-scheme-handler/https=zen-browser.desktop
EOF

echo -e "${BLUE}[+] Installing Flutter SDK into /opt/flutter...${RESET}"
mkdir -p "$ROOTFS/opt"
if [[ ! -d "$ROOTFS/opt/flutter" || ! -f "$ROOTFS/opt/flutter/bin/flutter" ]]; then
    curl -fsSL -o "$ROOTFS/tmp/flutter_linux.tar.xz" "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz" || true
    if [[ -f "$ROOTFS/tmp/flutter_linux.tar.xz" ]]; then
        tar -xf "$ROOTFS/tmp/flutter_linux.tar.xz" -C "$ROOTFS/opt/" 2>/dev/null || true
        rm -f "$ROOTFS/tmp/flutter_linux.tar.xz"
    fi
fi

mkdir -p "$ROOTFS/etc/profile.d"
cp "$PROJECT_ROOT/config/flutter.sh" "$ROOTFS/etc/profile.d/flutter.sh"
chmod +x "$ROOTFS/etc/profile.d/flutter.sh"

echo -e "${BLUE}[+] Installing Laravel CLI via Composer...${RESET}"
chroot "$ROOTFS" env COMPOSER_ALLOW_SUPERUSER=1 composer global require laravel/installer
mkdir -p "$ROOTFS/usr/local/bin"
chroot "$ROOTFS" ln -sf /root/.config/composer/vendor/bin/laravel /usr/local/bin/laravel 2>/dev/null || true

# Composer's vendor bin path isn't globally available by default, so we inject it into the system profile.
mkdir -p "$ROOTFS/etc/profile.d"
cat <<'EOF' > "$ROOTFS/etc/profile.d/composer.sh"
#!/usr/bin/env bash
export PATH="$PATH:$HOME/.config/composer/vendor/bin"
EOF
chmod +x "$ROOTFS/etc/profile.d/composer.sh"

echo -e "${BLUE}[+] Provisioning desktop assets and configuration...${RESET}"
# GTK Themes
mkdir -p "$ROOTFS/usr/share/themes"
cp -r "$PROJECT_ROOT/config/gtk/themes/"* "$ROOTFS/usr/share/themes/"

# Logos and Icon System Provisioning
mkdir -p "$ROOTFS/usr/share/pixmaps" \
         "$ROOTFS/usr/share/icons/hicolor/256x256/apps" \
         "$ROOTFS/usr/share/icons/hicolor/scalable/apps" \
         "$ROOTFS/usr/share/icons/Papirus-Dark/48x48/places"
cp "$PROJECT_ROOT/config/logo/eclipse-logo.png" "$ROOTFS/usr/share/pixmaps/eclipse-logo.png"
cp "$PROJECT_ROOT/config/logo/eclipse-logo.png" "$ROOTFS/usr/share/pixmaps/eclipse.png"
cp "$PROJECT_ROOT/config/logo/eclipse-logo.png" "$ROOTFS/usr/share/pixmaps/kicker-logo.png"
cp "$PROJECT_ROOT/config/logo/eclipse-logo.png" "$ROOTFS/usr/share/icons/hicolor/256x256/apps/eclipse-logo.png"
cp "$PROJECT_ROOT/config/logo/eclipse-logo.png" "$ROOTFS/usr/share/icons/hicolor/256x256/apps/start-here.png"

# Write OS Branding to /etc/os-release
cat <<'EOF' > "$ROOTFS/etc/os-release"
NAME="Eclipse OS"
VERSION="1.0 (Syzygy)"
ID=eclipse
ID_LIKE=debian
PRETTY_NAME="Eclipse OS 1.0 (Syzygy)"
VERSION_ID="1.0"
HOME_URL="https://github.com/RandomMoh/eclipse-os"
LOGO="eclipse-logo"
EOF

# Wallpaper
mkdir -p "$ROOTFS/usr/share/backgrounds/eclipse"
cp "$PROJECT_ROOT/config/wallpaper/eclipse-wallpaper.png" "$ROOTFS/usr/share/backgrounds/eclipse/eclipse-wallpaper.png"

# System-wide desktop-base wallpaper overrides
mkdir -p "$ROOTFS/usr/share/images/desktop-base"
ln -sf /usr/share/backgrounds/eclipse/eclipse-wallpaper.png "$ROOTFS/usr/share/images/desktop-base/desktop-background" 2>/dev/null || true
ln -sf /usr/share/backgrounds/eclipse/eclipse-wallpaper.png "$ROOTFS/usr/share/images/desktop-base/default" 2>/dev/null || true

# KDE Plasma aggressively defaults to the Breeze Next wallpaper. Overwriting the symlink target is the only reliable way to enforce the custom wallpaper on the first boot.
mkdir -p "$ROOTFS/usr/share/wallpapers/Next/contents/images"
cp "$PROJECT_ROOT/config/wallpaper/eclipse-wallpaper.png" "$ROOTFS/usr/share/wallpapers/Next/contents/images/1920x1080.png"
cp "$PROJECT_ROOT/config/wallpaper/eclipse-wallpaper.png" "$ROOTFS/usr/share/wallpapers/Next/contents/images/1920x1080.jpg"

# live-config injects unwanted configuration for desktop-base and lightdm. Disabling these overrides ensures the KDE environment boots cleanly without interference.
rm -rf "$ROOTFS/etc/lightdm" "$ROOTFS/etc/xdg/xfce4" 2>/dev/null || true
rm -f "$ROOTFS/lib/live/config/0000-desktop-base" "$ROOTFS/lib/live/config/0100-lightdm" "$ROOTFS/lib/live/config/1160-xfce4-desktop" "$ROOTFS/lib/live/config/1170-xfce4-panel" 2>/dev/null || true
rm -f "$ROOTFS/usr/lib/live/config/0000-desktop-base" "$ROOTFS/usr/lib/live/config/0100-lightdm" "$ROOTFS/usr/lib/live/config/1160-xfce4-desktop" "$ROOTFS/usr/lib/live/config/1170-xfce4-panel" 2>/dev/null || true

# Set Dolphin as default file manager & Zen Browser as default web browser in skel
mkdir -p "$ROOTFS/etc/skel/.config"
cat <<'EOF' > "$ROOTFS/etc/skel/.config/mimeapps.list"
[Default Applications]
inode/directory=org.kde.dolphin.desktop
text/html=zen-browser.desktop
x-scheme-handler/http=zen-browser.desktop
x-scheme-handler/https=zen-browser.desktop
EOF

echo -e "${BLUE}[+] Provisioning Plymouth Boot Splash Theme...${RESET}"
mkdir -p "$ROOTFS/usr/share/plymouth/themes"
cp -r "$PROJECT_ROOT/config/plymouth/eclipse-splash" "$ROOTFS/usr/share/plymouth/themes/"

# The plymouth daemon requires specific framebuffer settings in initramfs to render the boot splash correctly before the GPU drivers fully load.
mkdir -p "$ROOTFS/etc/plymouth" "$ROOTFS/etc/initramfs-tools/conf.d"
cat <<'EOF' > "$ROOTFS/etc/plymouth/plymouthd.conf"
[Daemon]
Theme=eclipse-splash
ShowDelay=0
DeviceTimeout=8
EOF

cat <<'EOF' > "$ROOTFS/etc/initramfs-tools/conf.d/plymouth"
FRAMEBUFFER=y
EOF

cat <<'EOF' > "$ROOTFS/etc/initramfs-tools/conf.d/live.conf"
BOOT=live
EOF

echo -e "${BLUE}[+] Synchronizing modern hardware firmware binaries (GPU & Wi-Fi) into rootfs...${RESET}"
for fw_dir in amdgpu i915 intel nvidia mediatek rtw89; do
    mkdir -p "$ROOTFS/lib/firmware/$fw_dir"
    for f in /lib/firmware/$fw_dir/*.zst; do
        if [ -f "$f" ]; then
            base="$(basename "$f" .zst)"
            zstd -d -c < "$f" > "$ROOTFS/lib/firmware/$fw_dir/$base" 2>/dev/null || true
        fi
    done
    for f in /lib/firmware/$fw_dir/*; do
        if [ -f "$f" ] && [[ "$f" != *.zst ]]; then
            cp "$f" "$ROOTFS/lib/firmware/$fw_dir/" 2>/dev/null || true
        fi
    done
done

# Sync top-level Intel iwlwifi and Realtek binaries
for f in /lib/firmware/iwlwifi-*.zst /lib/firmware/rtlwifi/*.zst; do
    if [ -f "$f" ]; then
        dir="$(dirname "$f")"
        base="$(basename "$f" .zst)"
        mkdir -p "$ROOTFS$dir"
        zstd -d -c < "$f" > "$ROOTFS$dir/$base" 2>/dev/null || true
    fi
done

chroot "$ROOTFS" plymouth-set-default-theme eclipse-splash -R 2>/dev/null || true
chroot "$ROOTFS" update-initramfs -u -k all 2>/dev/null || true

echo -e "${BLUE}[+] Provisioning native Python utilities, dnf CLI, and custom dock...${RESET}"
mkdir -p "$ROOTFS/usr/local/bin"
cp "$PROJECT_ROOT/src/eclipse-sysinfo" "$ROOTFS/usr/local/bin/"
cp "$PROJECT_ROOT/src/eclipse-control" "$ROOTFS/usr/local/bin/"
cp "$PROJECT_ROOT/src/eclipse-installer" "$ROOTFS/usr/local/bin/"
cp "$PROJECT_ROOT/src/eclipse-dock" "$ROOTFS/usr/local/bin/"
cp "$PROJECT_ROOT/src/dnf" "$ROOTFS/usr/local/bin/"

cp "$PROJECT_ROOT/src/eclipse-os-hub.py" "$ROOTFS/usr/local/bin/eclipse-os-hub"
chmod +x "$ROOTFS/usr/local/bin/eclipse-os-hub"
cp -r "$PROJECT_ROOT/src/ui" "$ROOTFS/usr/local/bin/"
cp -r "$PROJECT_ROOT/src/assets" "$ROOTFS/usr/local/bin/"

mkdir -p "$ROOTFS/usr/share/applications/"
cp "$PROJECT_ROOT/config/desktop/eclipse-os-hub.desktop" "$ROOTFS/usr/share/applications/"
cp "$PROJECT_ROOT/config/desktop/eclipse-os-hub.desktop" "$ROOTFS/etc/skel/Desktop/"
chmod +x "$ROOTFS/usr/local/bin/eclipse-sysinfo" "$ROOTFS/usr/local/bin/eclipse-control" "$ROOTFS/usr/local/bin/eclipse-installer" "$ROOTFS/usr/local/bin/eclipse-dock" "$ROOTFS/usr/local/bin/dnf"

mkdir -p "$ROOTFS/etc/xdg/autostart" "$ROOTFS/etc/skel/.config/autostart"
cp "$PROJECT_ROOT/config/autostart/eclipse-dock.desktop" "$ROOTFS/etc/xdg/autostart/"
cp "$PROJECT_ROOT/config/autostart/eclipse-dock.desktop" "$ROOTFS/etc/skel/.config/autostart/"
# Provision KDE Plasma default settings for skeleton and eclipse user
mkdir -p "$ROOTFS/etc/skel/.config" "$ROOTFS/etc/xdg"
cp -f "$PROJECT_ROOT/config/kde/kdeglobals" "$ROOTFS/etc/skel/.config/kdeglobals"
cp -f "$PROJECT_ROOT/config/kde/kdeglobals" "$ROOTFS/etc/xdg/kdeglobals"
cp -f "$PROJECT_ROOT/config/kde/plasmarc" "$ROOTFS/etc/skel/.config/plasmarc"
cp -f "$PROJECT_ROOT/config/kde/kwinrc" "$ROOTFS/etc/skel/.config/kwinrc"

# Create desktop launchers for Eclipse Utilities
mkdir -p "$ROOTFS/usr/share/applications"
cat <<'EOF' > "$ROOTFS/usr/share/applications/eclipse-sysinfo.desktop"
[Desktop Entry]
Version=1.0
Name=Eclipse SysInfo
Comment=Display system metrics and Eclipse OS specs
Exec=konsole --hold -e eclipse-sysinfo
Icon=utilities-system-monitor
Terminal=false
Type=Application
Categories=System;Utility;
EOF

cat <<'EOF' > "$ROOTFS/usr/share/applications/eclipse-installer.desktop"
[Desktop Entry]
Version=1.0
Name=Eclipse OS Installer
Comment=Install Eclipse OS to target disk
Exec=konsole -e "sudo eclipse-installer"
Icon=system-software-install
Terminal=false
Type=Application
Categories=System;Installer;
EOF

# Copy shortcuts to Desktop directory for skeleton and live user
mkdir -p "$ROOTFS/etc/skel/Desktop"
for launcher in zen-browser.desktop kate.desktop code.desktop eclipse-sysinfo.desktop eclipse-installer.desktop; do
    if [[ -f "$ROOTFS/usr/share/applications/$launcher" ]]; then
        cp "$ROOTFS/usr/share/applications/$launcher" "$ROOTFS/etc/skel/Desktop/"
        chmod +x "$ROOTFS/etc/skel/Desktop/$launcher"
    fi
done

# Create live user without a hardcoded password so user can login with empty password
echo -e "${BLUE}[+] Creating eclipse user...${RESET}"
chroot "$ROOTFS" bash -c 'if ! id -u eclipse >/dev/null 2>&1; then useradd -m -c "Eclipse OS Live User" -G sudo,video,audio,plugdev,netdev -s /bin/bash eclipse; fi'
chroot "$ROOTFS" bash -c 'passwd -d eclipse'

# Copy KDE desktop configuration and Desktop shortcuts to live user home directory
if [[ -d "$ROOTFS/home/eclipse" ]]; then
    mkdir -p "$ROOTFS/home/eclipse/.config" "$ROOTFS/home/eclipse/Desktop"
    cp -f "$PROJECT_ROOT/config/kde/kdeglobals" "$ROOTFS/home/eclipse/.config/kdeglobals"
    cp -f "$PROJECT_ROOT/config/kde/plasmarc" "$ROOTFS/home/eclipse/.config/plasmarc"
    cp -f "$PROJECT_ROOT/config/kde/kwinrc" "$ROOTFS/home/eclipse/.config/kwinrc"
    cp -r "$ROOTFS/etc/skel/Desktop/"* "$ROOTFS/home/eclipse/Desktop/" 2>/dev/null || true
    chmod +x "$ROOTFS/home/eclipse/Desktop/"*.desktop 2>/dev/null || true
    chroot "$ROOTFS" chown -R eclipse:eclipse /home/eclipse
fi

# KDE PIM daemons consume background resources even when unused. Removing them, along with games and help documentation, keeps the RAM footprint under 1GB.
echo -e "${YELLOW}[*] Bypassing aggressive KDE purge to prevent metapackage removal...${RESET}"

# Write sudoers file for eclipse user
mkdir -p "$ROOTFS/etc/sudoers.d"
echo "eclipse ALL=(ALL) NOPASSWD: ALL" > "$ROOTFS/etc/sudoers.d/eclipse"
chmod 0440 "$ROOTFS/etc/sudoers.d/eclipse"

# Purge leftover session desktop files
rm -f "$ROOTFS/usr/share/xsessions/xfce.desktop" "$ROOTFS/usr/share/xsessions/lightdm-xsession.desktop" 2>/dev/null || true

# SDDM requires an explicit password for normal logins. Leaving the password blank allows the user to log in just by hitting Enter, bypassing the autologin loop.
echo -e "${BLUE}[+] Ensuring SDDM autologin is disabled...${RESET}"
rm -f "$ROOTFS/etc/sddm.conf.d/autologin.conf" 2>/dev/null || true

# LightDM can hijack the display-manager symlink during package installation. Hardcoding the SDDM symlink guarantees the correct display manager starts.
chroot "$ROOTFS" bash -c "rm -f /etc/systemd/system/display-manager.service && systemctl enable sddm"

# Set systemd graphical target and enable SDDM service
echo -e "${BLUE}[+] Enabling SDDM display manager and graphical default target...${RESET}"
chroot "$ROOTFS" systemctl set-default graphical.target
chroot "$ROOTFS" systemctl enable sddm 2>/dev/null || true
chroot "$ROOTFS" systemctl disable podman-restart podman-auto-update 2>/dev/null || true

echo -e "${YELLOW}[*] Cleaning up package cache inside rootfs...${RESET}"
chroot "$ROOTFS" apt-get clean
rm -rf "$ROOTFS/var/lib/apt/lists/"*
rm -rf "$ROOTFS/var/cache/apt/archives/"*.deb

echo -e "${GREEN}[+] System configuration and provisioning completed successfully!${RESET}"
