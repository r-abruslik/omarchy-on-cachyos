#!/bin/bash
set -e
sudo -v
rm -rf ../omarchy 2>/dev/null || true
git clone https://github.com/basecamp/omarchy ../omarchy >/dev/null 2>&1 && cd ../omarchy
command -v yay &>/dev/null || { sudo pacman -S --needed --noconfirm git base-devel >/dev/null 2>&1; rm -rf /tmp/yay; git clone https://aur.archlinux.org/yay.git /tmp/yay >/dev/null 2>&1; (cd /tmp/yay && makepkg -si --noconfirm >/dev/null 2>&1); rm -rf /tmp/yay; }
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
HYPR_APPS="default/hypr/apps"
sed -i "s/^layerrule = noanim, selection/# layerrule = noanim, selection/" "$HYPR_APPS/hyprshot.conf" 2>/dev/null || true
cat > "$HYPR_APPS/jetbrains.conf" <<'EOF'
windowrulev2 = tag +jetbrains-splash, class:(^jetbrains-.*), title:(splash), floating:1
windowrulev2 = center, tag:jetbrains-splash
windowrulev2 = noinitialfocus, tag:jetbrains-splash
windowrulev2 = noborder, tag:jetbrains-splash
windowrulev2 = tag +jetbrains, class:(^jetbrains-.*), title:(^$), floating:1
windowrulev2 = center, tag:jetbrains
windowrulev2 = stayfocused, tag:jetbrains
windowrulev2 = noborder, tag:jetbrains
windowrulev2 = size >50% >50%, class:(^jetbrains-.*), title:(^$), floating:1
windowrulev2 = noinitialfocus, class:(^jetbrains-.*), title:(^win.*), floating:1
windowrulev2 = nofocus, class:(^jetbrains-.*), title:(^win.*)
EOF
cat > "$HYPR_APPS/localsend.conf" <<'EOF'
windowrulev2 = float, class:(Share|localsend)
windowrulev2 = center, class:(Share|localsend)
EOF
cat > "$HYPR_APPS/pip.conf" <<'EOF'
windowrulev2 = tag +pip, title:(Picture.?in.?[Pp]icture)
windowrulev2 = float, tag:pip
windowrulev2 = pin, tag:pip
windowrulev2 = size 600 338, tag:pip
windowrulev2 = keepaspectratio, tag:pip
windowrulev2 = noborder, tag:pip
windowrulev2 = opacity 1 override 1 override, tag:pip
windowrulev2 = move 100%-w-40 4%, tag:pip
EOF
cat > "$HYPR_APPS/qemu.conf" <<'EOF'
windowrulev2 = opacity 1 override 1 override, class:(qemu)
EOF
cat > "$HYPR_APPS/retroarch.conf" <<'EOF'
windowrulev2 = fullscreen, class:(com.libretro.RetroArch)
windowrulev2 = opacity 1 override 1 override, class:(com.libretro.RetroArch)
windowrulev2 = idleinhibit fullscreen, class:(com.libretro.RetroArch)
EOF
cat > "$HYPR_APPS/steam.conf" <<'EOF'
windowrulev2 = float, class:(steam)
windowrulev2 = center, class:(steam), title:(Steam)
windowrulev2 = opacity 1 override 1 override, class:(steam)
windowrulev2 = size 1100 700, class:(steam), title:(Steam)
windowrulev2 = size 460 800, class:(steam), title:(Friends List)
windowrulev2 = idleinhibit fullscreen, class:(steam_app_.*)
EOF
cat > "$HYPR_APPS/system.conf" <<'EOF'
windowrulev2 = float, tag:floating-window
windowrulev2 = center, tag:floating-window
windowrulev2 = size 875 600, tag:floating-window
windowrulev2 = tag +floating-window, class:(org.omarchy.bluetui)
windowrulev2 = tag +floating-window, class:(org.omarchy.impala)
windowrulev2 = tag +floating-window, class:(org.omarchy.wiremix)
windowrulev2 = tag +floating-window, class:(org.omarchy.btop)
windowrulev2 = tag +floating-window, class:(org.omarchy.terminal)
windowrulev2 = tag +floating-window, class:(org.omarchy.bash)
windowrulev2 = tag +floating-window, class:(org.gnome.NautilusPreviewer)
windowrulev2 = tag +floating-window, class:(org.gnome.Evince)
windowrulev2 = tag +floating-window, class:(com.gabm.satty)
windowrulev2 = tag +floating-window, class:(Omarchy)
windowrulev2 = tag +floating-window, class:(About)
windowrulev2 = tag +floating-window, class:(TUI.float)
windowrulev2 = tag +floating-window, class:(imv)
windowrulev2 = tag +floating-window, class:(mpv)
windowrulev2 = tag +floating-window, class:(xdg-desktop-portal-gtk), title:(Open)
windowrulev2 = tag +floating-window, class:(sublime_text), title:(Open)
windowrulev2 = tag +floating-window, class:(DesktopEditors), title:(Open)
windowrulev2 = tag +floating-window, class:(org.gnome.Nautilus), title:(Open)
windowrulev2 = float, class:(org.gnome.Calculator)
windowrulev2 = fullscreen, class:(org.omarchy.screensaver)
windowrulev2 = opacity 1 override 1 override, class:(zoom)
windowrulev2 = opacity 1 override 1 override, class:(vlc)
windowrulev2 = opacity 1 override 1 override, class:(mpv)
windowrulev2 = opacity 1 override 1 override, class:(org.kde.kdenlive)
windowrulev2 = opacity 1 override 1 override, class:(com.obsproject.Studio)
windowrulev2 = opacity 1 override 1 override, class:(com.github.PintaProject.Pinta)
windowrulev2 = opacity 1 override 1 override, class:(imv)
windowrulev2 = opacity 1 override 1 override, class:(org.gnome.NautilusPreviewer)
windowrulev2 = rounding 8, tag:pop
windowrulev2 = idleinhibit always, tag:noidle
EOF
cat > "$HYPR_APPS/terminals.conf" <<'EOF'
windowrulev2 = tag +terminal, class:(Alacritty)
windowrulev2 = tag +terminal, class:(kitty)
windowrulev2 = tag +terminal, class:(com.mitchellh.ghostty)
EOF
sed -i "s/^layerrule = noanim, walker/# layerrule = noanim, walker/" "$HYPR_APPS/walker.conf" 2>/dev/null || true
cat > "$HYPR_APPS/webcam-overlay.conf" <<'EOF'
windowrulev2 = float, title:(WebcamOverlay)
windowrulev2 = pin, title:(WebcamOverlay)
windowrulev2 = noinitialfocus, title:(WebcamOverlay)
windowrulev2 = nodim, title:(WebcamOverlay)
windowrulev2 = move 100%-w-40 100%-w-40, title:(WebcamOverlay)
EOF
sed -i 's/^windowrule = scrolltouchpad/# windowrule = scrolltouchpad/' default/hypr/input.conf 2>/dev/null || true
sed -i 's/^windowrule = scrolltouchpad/# windowrule = scrolltouchpad/' config/hypr/input.conf 2>/dev/null || true
command -v fish &>/dev/null && fish -c "set -Ux OMARCHY_PATH $HOME/.local/share/omarchy" 2>/dev/null && fish -c "fish_add_path $HOME/.local/share/omarchy/bin" 2>/dev/null || true
chmod +x install.sh 2>/dev/null || true
./install.sh
