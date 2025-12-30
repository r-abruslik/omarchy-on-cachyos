#!/bin/bash

# ==============================================================================
# Omarchy-on-CachyOS Installer (Final Production Edition)
# ==============================================================================
# Installs Omarchy desktop environment on top of CachyOS Hyprland edition
#
# What this script does:
# 1. Applies CachyOS compatibility patches (removes conflicting scripts)
# 2. Pre-configures SDDM autologin
# 3. Fixes Hyprland v0.53 syntax errors (12 config files)
# 4. Configures Fish shell (CachyOS default)
# 5. Runs Omarchy's installer with all fixes pre-applied
#
# Technical approach:
# - Patches are applied to SOURCE directory (~/.local/share/omarchy/default/)
# - Omarchy's install.sh copies these to runtime config (~/.config/)
# - This ensures working config immediately after reboot
# ==============================================================================

set -e  # Exit on any error
set -u  # Exit on undefined variable

# ==============================================================================
# PHASE 1: Prerequisites Check
# ==============================================================================

echo ">> Checking prerequisites..."

if ! command -v git &> /dev/null; then
    echo "✗ Error: git is not installed. Please install git before running this script."
    exit 1
fi
echo "  ✓ git is installed"

# ==============================================================================
# PHASE 2: Clone Omarchy Repository
# ==============================================================================

echo ""
echo ">> Cloning Omarchy from repository..."

# Remove existing directory for clean install (suppress error if doesn't exist)
rm -rf ../omarchy 2>/dev/null || true

if ! git clone https://www.github.com/basecamp/omarchy ../omarchy; then
    echo "✗ Error: Failed to clone Omarchy repository."
    exit 1
fi
echo "  ✓ Successfully cloned Omarchy repository"

cd ../omarchy || { echo "✗ Error: Failed to change to omarchy directory."; exit 1; }

# ==============================================================================
# PHASE 3: Install yay AUR Helper (if needed)
# ==============================================================================

echo ""
echo ">> Checking for yay AUR helper..."

if ! command -v yay &> /dev/null; then
    echo "  yay not found. Installing yay..."

    sudo pacman -S --needed --noconfirm git base-devel || { echo "✗ Error: Failed to install build dependencies."; exit 1; }

    git clone https://aur.archlinux.org/yay.git /tmp/yay || { echo "✗ Error: Failed to clone yay repository."; exit 1; }
    cd /tmp/yay || exit 1
    makepkg -si --noconfirm || { echo "✗ Error: Failed to build yay."; exit 1; }
    cd - > /dev/null || exit 1
    rm -rf /tmp/yay

    if ! command -v yay &> /dev/null; then
        echo "✗ Error: yay installation verification failed."
        exit 1
    fi
    echo "  ✓ yay has been successfully installed"
else
    echo "  ✓ yay is already installed"
fi

# ==============================================================================
# PHASE 4: Setup Omarchy Repository & Signing Keys
# ==============================================================================

echo ""
echo ">> Setting up Omarchy signing keys and repository..."

sudo pacman-key --recv-keys F0134EE680CAC571 || { echo "✗ Error: Failed to receive signing key."; exit 1; }
sudo pacman-key --lsign-key F0134EE680CAC571 || { echo "✗ Error: Failed to sign key locally."; exit 1; }

# Idempotent check before adding repo
if ! grep -q "\[omarchy\]" /etc/pacman.conf; then
    echo -e "\n[omarchy]\nSigLevel = Optional TrustedOnly\nServer = https://pkgs.omarchy.org/\$arch" | sudo tee -a /etc/pacman.conf > /dev/null
    echo "  ✓ Added Omarchy repository to pacman.conf"
else
    echo "  ✓ Omarchy repository already configured"
fi

sudo pacman -Syu --noconfirm || echo "  ⚠ Warning: System update had issues, but continuing..."

# ==============================================================================
# PHASE 5: User Configuration
# ==============================================================================

echo ""
echo ">> User configuration..."
echo ""
echo "Please enter your username:"
read -r OMARCHY_USER_NAME
export OMARCHY_USER_NAME

echo ""
echo "Please enter your email address:"
read -r OMARCHY_USER_EMAIL
export OMARCHY_USER_EMAIL

echo "  ✓ User configuration saved"

# ==============================================================================
# PHASE 6: SDDM Autologin Pre-Configuration
# ==============================================================================

echo ""
echo ">> Pre-configuring SDDM autologin..."

sudo mkdir -p /etc/sddm.conf.d

sudo tee /etc/sddm.conf.d/autologin.conf > /dev/null <<EOF
[Autologin]
User=$OMARCHY_USER_NAME
Session=hyprland
EOF

echo "  ✓ SDDM autologin configured for: $OMARCHY_USER_NAME"

# ==============================================================================
# PHASE 7: Mroboff's CachyOS Compatibility Patches
# ==============================================================================

echo ""
echo ">> Applying CachyOS compatibility patches..."

# Verify we're in the correct directory
if [[ ! -f "install.sh" ]]; then
    echo "✗ Error: Not in omarchy directory - install.sh not found."
    exit 1
fi

# 1. Kernel update logic -> CachyOS (combined sed operations)
if [[ -f "bin/omarchy-update-restart" ]]; then
    sed -i \
        -e "s/ | sed 's\/-arch\/\\.arch\/'//" \
        -e "s/'{print \$2}'/'{print \$2 \"-\" \$1}' | sed 's\/-linux\/\/'//" \
        -e "/linux-cachyos/ ! s/pacman -Q linux/pacman -Q linux-cachyos/" \
        bin/omarchy-update-restart
    echo "  ✓ Updated kernel restart detection for CachyOS"
fi

# 2. Remove tldr (conflict with tealdeer)
if [[ -f "install/omarchy-base.packages" ]]; then
    sed -i '/tldr/d' install/omarchy-base.packages
    echo "  ✓ Removed tldr package"
fi

# 3. Strip conflicting scripts from the "all.sh" lists
[[ -f "install/preflight/all.sh" ]] && sed -i '/run_logged $OMARCHY_INSTALL\/preflight\/pacman\.sh/d' install/preflight/all.sh
[[ -f "install/config/all.sh" ]] && sed -i '/run_logged $OMARCHY_INSTALL\/config\/hardware\/nvidia\.sh/d' install/config/all.sh

if [[ -f "install/login/all.sh" ]]; then
    sed -i \
        -e '/run_logged $OMARCHY_INSTALL\/login\/plymouth\.sh/d' \
        -e '/run_logged $OMARCHY_INSTALL\/login\/limine-snapper\.sh/d' \
        -e '/run_logged $OMARCHY_INSTALL\/login\/alt-bootloaders\.sh/d' \
        install/login/all.sh
fi

[[ -f "install/post-install/all.sh" ]] && sed -i '/run_logged $OMARCHY_INSTALL\/post-install\/pacman\.sh/d' install/post-install/all.sh

echo "  ✓ Disabled conflicting CachyOS scripts (nvidia, plymouth, limine, pacman)"

# 4. Patch UWSM env for multi-shell support
if [[ -f "config/uwsm/env" ]]; then
    # Create backup
    cp config/uwsm/env config/uwsm/env.bak
    echo "  ✓ Created backup: config/uwsm/env.bak"

    # Replace mise activation block for Bash/Fish support
    if grep -q "omarchy-cmd-present mise" config/uwsm/env; then
        sed -i '/omarchy-cmd-present mise.*activate bash/c\
if [ "$SHELL" = "/bin/bash" ] && command -v mise &> /dev/null; then\
  eval "$(mise activate bash)"\
elif [ "$SHELL" = "/bin/fish" ] && command -v mise &> /dev/null; then\
  mise activate fish | source\
fi' config/uwsm/env
        echo "  ✓ Updated mise activation for Bash/Fish support"
    fi
fi

# ==============================================================================
# PHASE 8: Copy to Local Installation Directory
# ==============================================================================

echo ""
echo ">> Copying files to ~/.local/share/omarchy..."

mkdir -p ~/.local/share/omarchy
cp -r . ~/.local/share/omarchy || { echo "✗ Error: Failed to copy files."; exit 1; }
cd ~/.local/share/omarchy || { echo "✗ Error: Failed to change to ~/.local/share/omarchy."; exit 1; }

echo "  ✓ Files copied successfully"

# ==============================================================================
# PHASE 8.5: Backup Existing Hyprland Configuration
# ==============================================================================

echo ""
echo ">> Backing up existing Hyprland configuration..."

if [[ -d ~/.config/hypr ]]; then
    BACKUP_DIR=~/.config/hypr.backup.$(date +%s)
    cp -r ~/.config/hypr "$BACKUP_DIR"
    echo "  ✓ Backed up to: $BACKUP_DIR"
else
    echo "  ⊘ No existing Hyprland config found (fresh install)"
fi

# ==============================================================================
# PHASE 9: Apply Hyprland v0.53 Compatibility Fixes
# ==============================================================================

# CRITICAL TIMING: These patches MUST be applied to SOURCE directory
# (~/.local/share/omarchy/default/hypr/apps/*) BEFORE running install.sh
#
# Flow: Source patches → install.sh copies → ~/.config/hypr/apps/*
# Without this: Hyprland crashes on startup with deprecated v0.45 syntax

echo ""
echo ">> Applying Hyprland v0.53 compatibility fixes..."

HYPR_APPS="default/hypr/apps"

# Verify directory exists (FATAL if missing - Omarchy structure changed)
if [[ ! -d "$HYPR_APPS" ]]; then
    echo "✗ FATAL: $HYPR_APPS directory not found."
    echo "  Omarchy structure may have changed. This script requires:"
    echo "  ~/.local/share/omarchy/default/hypr/apps/"
    echo "  Please report this issue if you're using the latest Omarchy."
    exit 1
fi

# 1. Fix hyprshot.conf (invalid layerrule)
if [[ -f "$HYPR_APPS/hyprshot.conf" ]]; then
    sed -i 's/^layerrule = noanim, selection/# layerrule = noanim, selection/' "$HYPR_APPS/hyprshot.conf"
    echo "  ✓ Fixed hyprshot.conf"
fi

# 2. Fix jetbrains.conf (rewrite with proper windowrulev2 + nofocus)
cat > "$HYPR_APPS/jetbrains.conf" <<'EOF'
# JetBrains IDE Fixes (Hyprland v0.53 compatible)
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
echo "  ✓ Fixed jetbrains.conf"

# 3. Fix localsend.conf (pipe in regex)
cat > "$HYPR_APPS/localsend.conf" <<'EOF'
windowrulev2 = float, class:(Share|localsend)
windowrulev2 = center, class:(Share|localsend)
EOF
echo "  ✓ Fixed localsend.conf"

# 4. Fix pip.conf (complex regex + proper opacity)
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
echo "  ✓ Fixed pip.conf"

# 5. Fix qemu.conf
cat > "$HYPR_APPS/qemu.conf" <<'EOF'
windowrulev2 = opacity 1 override 1 override, class:(qemu)
EOF
echo "  ✓ Fixed qemu.conf"

# 6. Fix retroarch.conf (idleinhibit syntax + opacity)
cat > "$HYPR_APPS/retroarch.conf" <<'EOF'
windowrulev2 = fullscreen, class:(com.libretro.RetroArch)
windowrulev2 = opacity 1 override 1 override, class:(com.libretro.RetroArch)
windowrulev2 = idleinhibit fullscreen, class:(com.libretro.RetroArch)
EOF
echo "  ✓ Fixed retroarch.conf"

# 7. Fix steam.conf (proper game idleinhibit + opacity)
cat > "$HYPR_APPS/steam.conf" <<'EOF'
windowrulev2 = float, class:(steam)
windowrulev2 = center, class:(steam), title:(Steam)
windowrulev2 = opacity 1 override 1 override, class:(steam)
windowrulev2 = size 1100 700, class:(steam), title:(Steam)
windowrulev2 = size 460 800, class:(steam), title:(Friends List)
windowrulev2 = idleinhibit fullscreen, class:(steam_app_.*)
EOF
echo "  ✓ Fixed steam.conf"

# 8. Fix system.conf (split massive regex into individual rules)
cat > "$HYPR_APPS/system.conf" <<'EOF'
windowrulev2 = float, tag:floating-window
windowrulev2 = center, tag:floating-window
windowrulev2 = size 875 600, tag:floating-window

# Tag floating window classes (split for maintainability)
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

# File dialogs
windowrulev2 = tag +floating-window, class:(xdg-desktop-portal-gtk), title:(Open)
windowrulev2 = tag +floating-window, class:(sublime_text), title:(Open)
windowrulev2 = tag +floating-window, class:(DesktopEditors), title:(Open)
windowrulev2 = tag +floating-window, class:(org.gnome.Nautilus), title:(Open)

# Other floating windows
windowrulev2 = float, class:(org.gnome.Calculator)
windowrulev2 = fullscreen, class:(org.omarchy.screensaver)
windowrulev2 = float, class:(org.omarchy.screensaver)

# Opacity overrides (proper v0.53 syntax)
windowrulev2 = opacity 1 override 1 override, class:(zoom)
windowrulev2 = opacity 1 override 1 override, class:(vlc)
windowrulev2 = opacity 1 override 1 override, class:(mpv)
windowrulev2 = opacity 1 override 1 override, class:(org.kde.kdenlive)
windowrulev2 = opacity 1 override 1 override, class:(com.obsproject.Studio)
windowrulev2 = opacity 1 override 1 override, class:(com.github.PintaProject.Pinta)
windowrulev2 = opacity 1 override 1 override, class:(imv)
windowrulev2 = opacity 1 override 1 override, class:(org.gnome.NautilusPreviewer)

# Special rules
windowrulev2 = rounding 8, tag:pop
windowrulev2 = idleinhibit always, tag:noidle
EOF
echo "  ✓ Fixed system.conf"

# 9. Fix terminals.conf (split into individual rules)
cat > "$HYPR_APPS/terminals.conf" <<'EOF'
windowrulev2 = tag +terminal, class:(Alacritty)
windowrulev2 = tag +terminal, class:(kitty)
windowrulev2 = tag +terminal, class:(com.mitchellh.ghostty)
EOF
echo "  ✓ Fixed terminals.conf"

# 10. Fix walker.conf (invalid layerrule)
if [[ -f "$HYPR_APPS/walker.conf" ]]; then
    sed -i 's/^layerrule = noanim, walker/# layerrule = noanim, walker/' "$HYPR_APPS/walker.conf"
    echo "  ✓ Fixed walker.conf"
fi

# 11. Fix webcam-overlay.conf
cat > "$HYPR_APPS/webcam-overlay.conf" <<'EOF'
windowrulev2 = float, title:(WebcamOverlay)
windowrulev2 = pin, title:(WebcamOverlay)
windowrulev2 = noinitialfocus, title:(WebcamOverlay)
windowrulev2 = nodim, title:(WebcamOverlay)
windowrulev2 = move 100%-w-40 100%-w-40, title:(WebcamOverlay)
EOF
echo "  ✓ Fixed webcam-overlay.conf"

# 12. Fix input.conf (remove invalid scrolltouchpad rule if present)
for input_file in "default/hypr/input.conf" "config/hypr/input.conf"; do
    if [[ -f "$input_file" ]]; then
        sed -i 's/^windowrule = scrolltouchpad/# windowrule = scrolltouchpad/' "$input_file"
    fi
done
echo "  ✓ Fixed input.conf files"

echo "  ✓ All Hyprland v0.53 compatibility fixes applied (12 files)"

# ==============================================================================
# PHASE 10: Fish Shell Configuration
# ==============================================================================

echo ""
echo ">> Configuring Fish shell environment..."

if command -v fish &> /dev/null; then
    # Set environment variables with error checking
    if fish -c "set -Ux OMARCHY_PATH $HOME/.local/share/omarchy" 2>/dev/null; then
        fish -c "fish_add_path $HOME/.local/share/omarchy/bin" 2>/dev/null || echo "  ⚠ Warning: fish_add_path failed"
        echo "  ✓ Fish shell configured with OMARCHY_PATH and PATH"
    else
        echo "  ✗ Warning: Failed to set Fish universal variables"
    fi
else
    echo "  ⊘ Fish shell not found (unexpected on CachyOS)"
fi

# ==============================================================================
# PHASE 11: Installation Summary
# ==============================================================================

echo ""
echo "======================================================================"
echo "                    INSTALLATION READY                               "
echo "======================================================================"
echo ""
echo "✓ CachyOS conflict scripts removed (nvidia/plymouth/limine/pacman)"
echo "✓ SDDM autologin pre-configured for: $OMARCHY_USER_NAME"
echo "✓ Hyprland v0.53 compatibility fixes applied (12 config files)"
echo "✓ Fish shell configured (CachyOS default)"
echo "✓ Omarchy repository added to pacman.conf"
echo "✓ mise activation supports both Bash and Fish"
echo ""
echo "IMPORTANT NOTES:"
echo "• Omarchy installer will run next and show its own progress"
echo "• At the end, you'll see a green reboot button"
echo "• All fixes are pre-applied, so Hyprland will work after reboot"
echo "• If you installed CachyOS without a desktop environment, run:"
echo "  ~/.local/share/omarchy/install/login/plymouth.sh"
echo "  after installation completes (before rebooting)"
echo ""
echo "======================================================================"
echo ""
echo "Press Enter to begin the Omarchy installation..."
read -r

# ==============================================================================
# PHASE 12: Launch Omarchy Installer
# ==============================================================================

if [[ ! -x "install.sh" ]]; then
    chmod +x install.sh || { echo "✗ Error: Failed to make install.sh executable."; exit 1; }
fi

echo ""
echo ">> Launching Omarchy installer..."
echo ">> (Omarchy will now take over and show its own interface)"
echo ""

# Launch Omarchy installer - it will handle completion message and reboot prompt
./install.sh

# Script ends here - Omarchy shows its own completion UI with green reboot button
