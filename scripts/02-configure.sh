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
    umount -l "$ROOTFS/dev/pts" "$ROOTFS/dev" "$ROOTFS/proc" "$ROOTFS/sys" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

echo -e "${BLUE}[+] Mounting virtual filesystems into rootfs...${RESET}"
mkdir -p "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/dev" "$ROOTFS/dev/pts"
mount --bind /proc "$ROOTFS/proc"
mount --bind /sys "$ROOTFS/sys"
mount --bind /dev "$ROOTFS/dev"
mount --bind /dev/pts "$ROOTFS/dev/pts"

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

echo -e "${YELLOW}[*] Installing required packages inside chroot...${RESET}"
chroot "$ROOTFS" env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    linux-image-amd64 \
    live-boot \
    live-config \
    systemd-sysv \
    network-manager \
    xorg \
    xserver-xorg \
    xserver-xorg-video-all \
    xserver-xorg-input-all \
    dbus-x11 \
    x11-xserver-utils \
    desktop-base \
    xfce4 \
    xfce4-goodies \
    lightdm \
    sudo \
    python3 \
    python3-pip \
    python3-rich \
    rsync \
    parted \
    dosfstools \
    e2fsprogs \
    grub-efi-amd64-bin \
    grub-pc-bin \
    xfce4-terminal \
    kate \
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
    fastfetch \
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

# Add Composer vendor bin path to default profile for all users
mkdir -p "$ROOTFS/etc/profile.d"
cat <<'EOF' > "$ROOTFS/etc/profile.d/composer.sh"
#!/usr/bin/env bash
export PATH="$PATH:$HOME/.config/composer/vendor/bin"
EOF
chmod +x "$ROOTFS/etc/profile.d/composer.sh"

echo -e "${BLUE}[+] Provisioning desktop assets and configuration...${RESET}"
# GTK Theme
mkdir -p "$ROOTFS/usr/share/themes/Eclipse-Dark"
cp -r "$PROJECT_ROOT/config/gtk/"* "$ROOTFS/usr/share/themes/Eclipse-Dark/"

# XFCE Config for default skeleton
mkdir -p "$ROOTFS/etc/skel/.config"
cp -r "$PROJECT_ROOT/config/xfce/"* "$ROOTFS/etc/skel/.config/"

# Wallpaper
mkdir -p "$ROOTFS/usr/share/backgrounds/eclipse"
cp "$PROJECT_ROOT/config/wallpaper/eclipse-wallpaper.png" "$ROOTFS/usr/share/backgrounds/eclipse/"

echo -e "${BLUE}[+] Provisioning native Python utilities...${RESET}"
mkdir -p "$ROOTFS/usr/local/bin"
cp "$PROJECT_ROOT/src/eclipse-sysinfo" "$ROOTFS/usr/local/bin/"
cp "$PROJECT_ROOT/src/eclipse-control" "$ROOTFS/usr/local/bin/"
cp "$PROJECT_ROOT/src/eclipse-installer" "$ROOTFS/usr/local/bin/"
# Create desktop launchers for Eclipse Utilities
mkdir -p "$ROOTFS/usr/share/applications"
cat <<'EOF' > "$ROOTFS/usr/share/applications/eclipse-sysinfo.desktop"
[Desktop Entry]
Version=1.0
Name=Eclipse SysInfo
Comment=Display system metrics and Eclipse OS specs
Exec=xfce4-terminal -e eclipse-sysinfo
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
Exec=xfce4-terminal -e "sudo eclipse-installer"
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

# Copy XFCE desktop configuration and Desktop shortcuts to live user home directory if created
if [[ -d "$ROOTFS/home/eclipse" ]]; then
    mkdir -p "$ROOTFS/home/eclipse/.config" "$ROOTFS/home/eclipse/Desktop"
    cp -r "$PROJECT_ROOT/config/xfce/"* "$ROOTFS/home/eclipse/.config/"
    cp -r "$ROOTFS/etc/skel/Desktop/"* "$ROOTFS/home/eclipse/Desktop/" 2>/dev/null || true
    chmod +x "$ROOTFS/home/eclipse/Desktop/"*.desktop 2>/dev/null || true
    chroot "$ROOTFS" chown -R eclipse:eclipse /home/eclipse
fi

# Write sudoers file for eclipse user
mkdir -p "$ROOTFS/etc/sudoers.d"
echo "eclipse ALL=(ALL) NOPASSWD: ALL" > "$ROOTFS/etc/sudoers.d/eclipse"
chmod 0440 "$ROOTFS/etc/sudoers.d/eclipse"

# Configure LightDM autologin
echo -e "${BLUE}[+] Configuring LightDM autologin...${RESET}"
mkdir -p "$ROOTFS/etc/lightdm/lightdm.conf.d"
cat <<'EOF' > "$ROOTFS/etc/lightdm/lightdm.conf.d/80-autologin.conf"
[Seat:*]
autologin-user=eclipse
autologin-user-timeout=0
EOF

if [[ -f "$ROOTFS/etc/lightdm/lightdm.conf" ]]; then
    sed -i 's/^#\?autologin-user=.*/autologin-user=eclipse/' "$ROOTFS/etc/lightdm/lightdm.conf"
    sed -i 's/^#\?autologin-user-timeout=.*/autologin-user-timeout=0/' "$ROOTFS/etc/lightdm/lightdm.conf"
fi

# Set systemd graphical target and enable LightDM service
echo -e "${BLUE}[+] Enabling LightDM and setting graphical default target...${RESET}"
chroot "$ROOTFS" systemctl set-default graphical.target
chroot "$ROOTFS" systemctl enable lightdm

echo -e "${YELLOW}[*] Cleaning up package cache inside rootfs...${RESET}"
chroot "$ROOTFS" apt-get clean
rm -rf "$ROOTFS/var/lib/apt/lists/"*
rm -rf "$ROOTFS/var/cache/apt/archives/"*.deb

echo -e "${GREEN}[+] System configuration and provisioning completed successfully!${RESET}"
