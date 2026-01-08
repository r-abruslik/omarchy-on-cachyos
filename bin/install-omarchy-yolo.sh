#!/bin/bash
rm -rf ../omarchy && git clone https://github.com/basecamp/omarchy ../omarchy && cd ../omarchy
command -v yay || (sudo pacman -S --needed --noconfirm base-devel && git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si --noconfirm && cd -)
sudo pacman-key --recv-keys F0134EE680CAC571 && sudo pacman-key --lsign-key F0134EE680CAC571
grep -q "\[omarchy\]" /etc/pacman.conf || printf '\n[omarchy]\nSigLevel = Optional TrustedOnly\nServer = https://pkgs.omarchy.org/$arch\n' | sudo tee -a /etc/pacman.conf
sudo pacman -Syu --noconfirm
echo "Username:" && read -r OMARCHY_USER_NAME && export OMARCHY_USER_NAME
echo "Email:" && read -r OMARCHY_USER_EMAIL && export OMARCHY_USER_EMAIL
sudo mkdir -p /etc/sddm.conf.d && sudo tee /etc/sddm.conf.d/autologin.conf <<< "[Autologin]
User=$OMARCHY_USER_NAME
Session=hyprland"
sed -i "s# | sed 's/-arch/\\\\.arch/'##" bin/omarchy-update-restart
sed -i "s#'{print \$2}'#'{print \$2 \" - \" \$1}' | sed 's/-linux//'#" bin/omarchy-update-restart
sed -i "/linux-cachyos/ ! s/pacman -Q linux/pacman -Q linux-cachyos/" bin/omarchy-update-restart
sed -i '/tldr/d' install/omarchy-base.packages
echo "omarchy-fish" >> install/omarchy-base.packages
sed -i '/run_logged \$OMARCHY_INSTALL\/preflight\/pacman\.sh/d' install/preflight/all.sh
sed -i '/run_logged \$OMARCHY_INSTALL\/config\/hardware\/nvidia\.sh/d' install/config/all.sh
sed -i -e '/run_logged \$OMARCHY_INSTALL\/login\/plymouth\.sh/d' -e '/run_logged \$OMARCHY_INSTALL\/login\/limine-snapper\.sh/d' -e '/run_logged \$OMARCHY_INSTALL\/login\/alt-bootloaders\.sh/d' install/login/all.sh
sed -i '/run_logged \$OMARCHY_INSTALL\/post-install\/pacman\.sh/d' install/post-install/all.sh
sed -i '1i run_logged omarchy-setup-fish' install/post-install/finished.sh
chmod +x install.sh && ./install.sh
