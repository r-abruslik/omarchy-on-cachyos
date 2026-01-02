#!/bin/bash
set -e

# Silent sudo auth
sudo -v

# Clone and setup
rm -rf ../omarchy 2>/dev/null || true
git clone https://github.com/basecamp/omarchy ../omarchy &>/dev/null
cd ../omarchy

# Install yay if needed
if ! command -v yay &>/dev/null; then
  sudo pacman -S --needed --noconfirm base-devel &>/dev/null
  rm -rf /tmp/yay
  git clone https://aur.archlinux.org/yay.git /tmp/yay &>/dev/null
  (cd /tmp/yay && makepkg -si --noconfirm) &>/dev/null
  rm -rf /tmp/yay
fi

# Setup Omarchy repo
sudo pacman-key --recv-keys F0134EE680CAC571 &>/dev/null
sudo pacman-key --lsign-key F0134EE680CAC571 &>/dev/null
grep -q "\\[omarchy\\]" /etc/pacman.conf || printf '\\n[omarchy]\\nSigLevel = Optional TrustedOnly\\nServer = https://pkgs.omarchy.org/$arch\\n' | sudo tee -a /etc/pacman.conf &>/dev/null
sudo pacman -Syu --noconfirm &>/dev/null || true

# Apply patches - NVIDIA config ENABLED (no nvidia.sh removal)
sed -i "s/ | sed 's\\/-arch\\/\\\\.arch\\/'//'" bin/omarchy-update-restart 2>/dev/null || true
sed -i "s/'{print \\$2}'/'{print \\$2 \\\"-\\\" \\$1}' | sed 's\\/-linux\\/\\/'/" bin/omarchy-update-restart 2>/dev/null || true
sed -i "/linux-cachyos/ ! s/pacman -Q linux/pacman -Q linux-cachyos/" bin/omarchy-update-restart 2>/dev/null || true
sed -i '/tldr/d' install/omarchy-base.packages 2>/dev/null || true
sed -i '/run_logged \\$OMARCHY_INSTALL\\/preflight\\/pacman\\.sh/d' install/preflight/all.sh 2>/dev/null || true
sed -i '/run_logged \\$OMARCHY_INSTALL\\/login\\/plymouth\\.sh/d; /run_logged \\$OMARCHY_INSTALL\\/login\\/limine-snapper\\.sh/d; /run_logged \\$OMARCHY_INSTALL\\/login\\/alt-bootloaders\\.sh/d' install/login/all.sh 2>/dev/null || true
sed -i '/run_logged \\$OMARCHY_INSTALL\\/post-install\\/pacman\\.sh/d' install/post-install/all.sh 2>/dev/null || true

# Copy and run
mkdir -p ~/.local/share/omarchy
cp -r . ~/.local/share/omarchy
cd ~/.local/share/omarchy
[[ ! -x install.sh ]] && chmod +x install.sh
./install.sh
