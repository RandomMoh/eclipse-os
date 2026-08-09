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
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/packages.microsoft.gpg
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
chmod +x "$ROOTFS/usr/local/bin/eclipse-sysinfo" \
         "$ROOTFS/usr/local/bin/eclipse-control" \
         "$ROOTFS/usr/local/bin/eclipse-installer"

echo -e "${BLUE}[+] Provisioning live user 'eclipse'...${RESET}"
if ! chroot "$ROOTFS" id -u eclipse &>/dev/null; then
    chroot "$ROOTFS" useradd -m -s /bin/bash eclipse
fi
echo "eclipse:eclipse" | chroot "$ROOTFS" chpasswd

for g in sudo video audio plugdev netdev; do
    chroot "$ROOTFS" groupadd -f "$g"
    chroot "$ROOTFS" usermod -aG "$g" eclipse
done

# Copy XFCE desktop configuration to live user home directory if created
if [[ -d "$ROOTFS/home/eclipse" ]]; then
    mkdir -p "$ROOTFS/home/eclipse/.config"
    cp -r "$PROJECT_ROOT/config/xfce/"* "$ROOTFS/home/eclipse/.config/"
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
