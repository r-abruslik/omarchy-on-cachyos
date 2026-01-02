#!/bin/bash
set -e
sudo -v
rm -rf ../omarchy 2>/dev/null || true
git clone https://github.com/basecamp/omarchy ../omarchy >/dev/null 2>&1 && cd ../omarchy
command -v yay &>/dev/null || { sudo pacman -S --needed --noconfirm base-devel >/dev/null 2>&1; rm -rf /tmp/yay; git clone https://aur.archlinux.org/yay.git /tmp/yay >/dev/null 2>&1; (cd /tmp/yay && makepkg -si --noconfirm >/dev/null 2>&1); rm -rf /tmp/yay; }
sudo pacman-key --recv-keys F0134EE680CAC571 >/dev/null 2>&1
sudo pacman-key --lsign-key F0134EE680CAC571 >/dev/null 2>&1
grep -q "\\[omarchy\\]" /etc/pacman.conf || printf '\\n[omarchy]\\nSigLevel = Optional TrustedOnly\\nServer = https://pkgs.omarchy.org/$arch\\n' | sudo tee -a /etc/pacman.conf >/dev/null
sudo pacman -Syu --noconfirm >/dev/null 2>&1 || true
echo "Username:"; read -r OMARCHY_USER_NAME; echo "Email:"; read -r OMARCHY_USER_EMAIL
export OMARCHY_USER_NAME OMARCHY_USER_EMAIL
sudo mkdir -p /etc/sddm.conf.d && printf "[Autologin]\\nUser=$OMARCHY_USER_NAME\\nSession=hyprland\\n" | sudo tee /etc/sddm.conf.d/autologin.conf >/dev/null
sed -i -e "s/ | sed 's\\/-arch\\/\\\\.arch\\/'//'" -e "s/'{print \\$2}'/'{print \\$2 \\\"-\\\" \\$1}' | sed 's\\/-linux\\/\\/'/" -e "/linux-cachyos/ ! s/pacman -Q linux/pacman -Q linux-cachyos/" bin/omarchy-update-restart 2>/dev/null || true
sed -i '/tldr/d' install/omarchy-base.packages 2>/dev/null || true
sed -i '/run_logged \\$OMARCHY_INSTALL\\/preflight\\/pacman\\.sh/d' install/preflight/all.sh 2>/dev/null || true
sed -i '/run_logged \\$OMARCHY_INSTALL\\/config\\/hardware\\/nvidia\\.sh/d' install/config/all.sh 2>/dev/null || true
sed -i -e '/run_logged \\$OMARCHY_INSTALL\\/login\\/plymouth\\.sh/d' -e '/run_logged \\$OMARCHY_INSTALL\\/login\\/limine-snapper\\.sh/d' -e '/run_logged \\$OMARCHY_INSTALL\\/login\\/alt-bootloaders\\.sh/d' install/login/all.sh 2>/dev/null || true
sed -i '/run_logged \\$OMARCHY_INSTALL\\/post-install\\/pacman\\.sh/d' install/post-install/all.sh 2>/dev/null || true
[[ -f "config/uwsm/env" ]] && cp config/uwsm/env config/uwsm/env.bak && sed -i '/omarchy-cmd-present mise.*activate bash/c\\
if [ "$SHELL" = "/bin/bash" ] && command -v mise &> /dev/null; then\\
  eval "$(mise activate bash)"\\
elif [ "$SHELL" = "/bin/fish" ] && command -v mise &> /dev/null; then\\
  mise activate fish | source\\
fi' config/uwsm/env 2>/dev/null || true
mkdir -p ~/.local/share/omarchy && cp -r . ~/.local/share/omarchy && cd ~/.local/share/omarchy
[[ -d ~/.config/hypr ]] && cp -r ~/.config/hypr ~/.config/hypr.backup.$(date +%s)
command -v fish &>/dev/null && fish -c "set -Ux OMARCHY_PATH $HOME/.local/share/omarchy" 2>/dev/null && fish -c "fish_add_path $HOME/.local/share/omarchy/bin" 2>/dev/null || true
chmod +x install.sh 2>/dev/null || true
./install.sh
