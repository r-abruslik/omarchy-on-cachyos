#!/bin/bash

set -e
set -u

die() {
  echo "✗ FATAL: $*" >&2
  exit 1
}

run() {
  echo "  -> $*"
  "$@" || die "Command failed: $*"
}

# usage: safe_write /path/to/file <<'EOF' ... EOF
safe_write() {
  local target="$1"
  cat > "$target" || die "Failed to write $target"
}

comment_out_if_present() {
  local pattern="$1" file="$2"
  [[ -f "$file" ]] || return 0
  sed -i "s/^${pattern}/# ${pattern}/" "$file" || \\
    die "Failed to comment out ${pattern} in ${file}"
}

# Prerequisites check
echo ">> Checking prerequisites..."
command -v git >/dev/null 2>&1 || die "git is not installed"
echo "  ✓ git installed"

# Clone Omarchy
echo ""
echo ">> Cloning Omarchy..."
rm -rf ../omarchy 2>/dev/null || true
run git clone https://www.github.com/basecamp/omarchy ../omarchy
cd ../omarchy || die "cannot cd into ../omarchy"
echo "  ✓ Cloned"

# Install yay if needed
echo ""
echo ">> Checking yay..."
if ! command -v yay &> /dev/null; then
  echo "  Installing yay..."
  run sudo pacman -S --needed --noconfirm git base-devel
  rm -rf /tmp/yay
  run git clone https://aur.archlinux.org/yay.git /tmp/yay
  (
    cd /tmp/yay || die "cannot cd /tmp/yay"
    run makepkg -si --noconfirm
  )
  rm -rf /tmp/yay
fi
echo "  ✓ yay ready"

# Setup Omarchy repo
echo ""
echo ">> Setting up Omarchy repository..."
run sudo pacman-key --recv-keys F0134EE680CAC571
run sudo pacman-key --lsign-key F0134EE680CAC571
if ! grep -q "\\[omarchy\\]" /etc/pacman.conf; then                                                                                printf '\\n[omarchy]\\nSigLevel = Optional TrustedOnly\\nServer = https://pkgs.omarchy.org/$arch\\n' | \\
    sudo tee -a /etc/pacman.conf >/dev/null || die "failed to update /etc/pacman.conf"
fi                                                                                                                               if ! sudo pacman -Syu --noconfirm; then
  echo "  ⚠ pacman -Syu failed; continuing, but Omarchy repo may be out of date" >&2
fi                                                                                                                               echo "  ✓ Repository configured"

# User config                                                                                                                    echo ""
echo ">> User configuration"
echo "Username:"                                                                                                                 read -r OMARCHY_USER_NAME
export OMARCHY_USER_NAME
echo "Email:"                                                                                                                    read -r OMARCHY_USER_EMAIL
export OMARCHY_USER_EMAIL
                                                                                                                                 # SDDM autologin
echo ""
echo ">> Configuring SDDM autologin..."                                                                                          run sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/autologin.conf > /dev/null <<EOF
[Autologin]                                                                                                                      User=$OMARCHY_USER_NAME
Session=hyprland
EOF                                                                                                                              echo "  ✓ Autologin configured"

# CachyOS patches                                                                                                                echo ""
echo ">> Applying CachyOS compatibility patches..."
[[ ! -f "install.sh" ]] && die "install.sh not found"
# Kernel detection for CachyOS
if [[ -f "bin/omarchy-update-restart" ]]; then                                                                                     sed -i \\
    -e "s/ | sed 's\\/-arch\\/\\\\.arch\\/'//'" \\
    -e "s/'{print \\$2}'/'{print \\$2 \\\"-\\\" \\$1}' | sed 's\\/-linux\\/\\/'/" \\                                                 -e "/linux-cachyos/ ! s/pacman -Q linux/pacman -Q linux-cachyos/" \\
    bin/omarchy-update-restart || die "failed to patch bin/omarchy-update-restart"
fi
# Remove tldr (tealdeer conflict)
if [[ -f "install/omarchy-base.packages" ]]; then                                                                                  sed -i '/tldr/d' install/omarchy-base.packages || die "failed to remove tldr package"
fi
                                                                                                                                 # Disable conflicting scripts
if [[ -f "install/preflight/all.sh" ]]; then
  sed -i '/run_logged \\$OMARCHY_INSTALL\\/preflight\\/pacman\\.sh/d' install/preflight/all.sh || \\                                 die "failed to patch install/preflight/all.sh"
fi
                                                                                                                                 if [[ -f "install/config/all.sh" ]]; then
  sed -i '/run_logged \\$OMARCHY_INSTALL\\/config\\/hardware\\/nvidia\\.sh/d' install/config/all.sh || \\
    die "failed to patch install/config/all.sh"                                                                                  fi

if [[ -f "install/login/all.sh" ]]; then                                                                                           sed -i \\
    -e '/run_logged \\$OMARCHY_INSTALL\\/login\\/plymouth\\.sh/d' \\
    -e '/run_logged \\$OMARCHY_INSTALL\\/login\\/limine-snapper\\.sh/d' \\                                                           -e '/run_logged \\$OMARCHY_INSTALL\\/login\\/alt-bootloaders\\.sh/d' \\
    install/login/all.sh || die "failed to patch install/login/all.sh"
fi
if [[ -f "install/post-install/all.sh" ]]; then
  sed -i '/run_logged \\$OMARCHY_INSTALL\\/post-install\\/pacman\\.sh/d' install/post-install/all.sh || \\                           die "failed to patch install/post-install/all.sh"
fi
                                                                                                                                 # Patch mise for Fish/Bash
if [[ -f "config/uwsm/env" ]]; then
  cp config/uwsm/env config/uwsm/env.bak
  if grep -q "omarchy-cmd-present mise" config/uwsm/env; then                                                                        sed -i '/omarchy-cmd-present mise.*activate bash/c\\                                                                         if [ "$SHELL" = "/bin/bash" ] && command -v mise &> /dev/null; then\\
  eval "$(mise activate bash)"\\                                                                                                 elif [ "$SHELL" = "/bin/fish" ] && command -v mise &> /dev/null; then\\                                                            mise activate fish | source\\
fi' config/uwsm/env || die "failed to patch config/uwsm/env"                                                                       fi                                                                                                                             fi
echo "  ✓ Patches applied"                                                                                                                                                                                                                                        # Copy to local
echo ""                                                                                                                          echo ">> Copying to ~/.local/share/omarchy..."                                                                                   mkdir -p ~/.local/share/omarchy
cp -r . ~/.local/share/omarchy                                                                                                   cd ~/.local/share/omarchy || die "cannot cd ~/.local/share/omarchy"                                                              echo "  ✓ Copied"

# Backup existing Hyprland config                                                                                                echo ""
echo ">> Backing up existing config..."
if [[ -d ~/.config/hypr ]]; then
  cp -r ~/.config/hypr ~/.config/hypr.backup.$(date +%s)
  echo "  ✓ Backed up (~/.config/hypr.backup.<timestamp>)"
else
  echo "  ⊘ No existing config"                                                                                                  fi

# Hyprland v0.53 fixes (applied to source before install.sh copies them)                                                         echo ""
echo ">> Applying Hyprland v0.53 fixes..."
HYPR_APPS="default/hypr/apps"
[[ -d "$HYPR_APPS" ]] || die "$HYPR_APPS not found"

# Fix 1: hyprshot.conf
comment_out_if_present "layerrule = noanim, selection" "$HYPR_APPS/hyprshot.conf"

# Fix 2: jetbrains.conf
safe_write "$HYPR_APPS/jetbrains.conf" <<'EOF'
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
# Fix 3: localsend.conf
safe_write "$HYPR_APPS/localsend.conf" <<'EOF'
windowrulev2 = float, class:(Share|localsend)                                                                                    windowrulev2 = center, class:(Share|localsend)
EOF

# Fix 4: pip.conf
safe_write "$HYPR_APPS/pip.conf" <<'EOF'                                                                                         windowrulev2 = tag +pip, title:(Picture.?in.?[Pp]icture)
windowrulev2 = float, tag:pip
windowrulev2 = pin, tag:pip
windowrulev2 = size 600 338, tag:pip
windowrulev2 = keepaspectratio, tag:pip
windowrulev2 = noborder, tag:pip
windowrulev2 = opacity 1 override 1 override, tag:pip
windowrulev2 = move 100%-w-40 4%, tag:pip
EOF

# Fix 5: qemu.conf
safe_write "$HYPR_APPS/qemu.conf" <<'EOF'
windowrulev2 = opacity 1 override 1 override, class:(qemu)
EOF

# Fix 6: retroarch.conf
safe_write "$HYPR_APPS/retroarch.conf" <<'EOF'
windowrulev2 = fullscreen, class:(com.libretro.RetroArch)
windowrulev2 = opacity 1 override 1 override, class:(com.libretro.RetroArch)
windowrulev2 = idleinhibit fullscreen, class:(com.libretro.RetroArch)
EOF

# Fix 7: steam.conf
safe_write "$HYPR_APPS/steam.conf" <<'EOF'
windowrulev2 = float, class:(steam)
windowrulev2 = center, class:(steam), title:(Steam)
windowrulev2 = opacity 1 override 1 override, class:(steam)
windowrulev2 = size 1100 700, class:(steam), title:(Steam)
windowrulev2 = size 460 800, class:(steam), title:(Friends List)
windowrulev2 = idleinhibit fullscreen, class:(steam_app_.*)
EOF

# Fix 8: system.conf
safe_write "$HYPR_APPS/system.conf" <<'EOF'
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

# Fix 9: terminals.conf
safe_write "$HYPR_APPS/terminals.conf" <<'EOF'
windowrulev2 = tag +terminal, class:(Alacritty)
windowrulev2 = tag +terminal, class:(kitty)
windowrulev2 = tag +terminal, class:(com.mitchellh.ghostty)
EOF

# Fix 10: walker.conf
comment_out_if_present "layerrule = noanim, walker" "$HYPR_APPS/walker.conf"

# Fix 11: webcam-overlay.conf
safe_write "$HYPR_APPS/webcam-overlay.conf" <<'EOF'
windowrulev2 = float, title:(WebcamOverlay)
windowrulev2 = pin, title:(WebcamOverlay)
windowrulev2 = noinitialfocus, title:(WebcamOverlay)
windowrulev2 = nodim, title:(WebcamOverlay)
windowrulev2 = move 100%-w-40 100%-w-40, title:(WebcamOverlay)
EOF

# Fix 12: input.conf
for f in "default/hypr/input.conf" "config/hypr/input.conf"; do
  [[ -f "$f" ]] && sed -i 's/^windowrule = scrolltouchpad/# windowrule = scrolltouchpad/' "$f"
done

echo "  ✓ 12 files patched"

# Fish shell config
echo ""
echo ">> Configuring Fish..."
if command -v fish &> /dev/null; then
  fish -c "set -Ux OMARCHY_PATH $HOME/.local/share/omarchy" 2>/dev/null
  fish -c "fish_add_path $HOME/.local/share/omarchy/bin" 2>/dev/null || true
  echo "  ✓ Fish configured"
else
  echo "  ⊘ Fish not found"
fi

# Summary
echo ""
echo "======================================================================"
echo "  READY TO INSTALL"
echo "======================================================================"
echo ""
echo "✓ CachyOS patches applied"
echo "✓ SDDM autologin configured"
echo "✓ Hyprland v0.53 fixes applied (12 files)"
echo "✓ Fish configured"
echo ""
echo "Press Enter to launch Omarchy installer..."
read -r

# Launch Omarchy installer (shows its own UI and reboot button)
[[ ! -x "install.sh" ]] && chmod +x install.sh
echo ""
echo ">> Launching Omarchy installer..."
./install.sh
