#!/bin/bash
set -e
set -u

die() {
    echo "✗ FATAL: $*" >&2
    exit 1
}

run() {
    echo " -> $*"
    "$@" || die "Command failed: $*"
}

echo ">> Cloning Omarchy..."
rm -rf ../omarchy 2>/dev/null || true
run git clone https://github.com/basecamp/omarchy ../omarchy
cd ../omarchy || die "cannot cd into ../omarchy"
echo " ✓ Cloned"

echo ""
echo ">> Checking yay..."
if ! command -v yay &> /dev/null; then
    echo " Installing yay..."
    run sudo pacman -S --needed --noconfirm base-devel
    rm -rf /tmp/yay
    run git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay || die "cannot cd /tmp/yay"
    run makepkg -si --noconfirm
    rm -rf /tmp/yay
fi
echo " ✓ yay ready"

echo ""
echo ">> Setting up Omarchy repository..."
run sudo pacman-key --recv-keys F0134EE680CAC571
run sudo pacman-key --lsign-key F0134EE680CAC571

if ! grep -q "\[omarchy\]" /etc/pacman.conf; then
    printf '\n[omarchy]\nSigLevel = Optional TrustedOnly\nServer = https://pkgs.omarchy.org/$arch\n' | \
    sudo tee -a /etc/pacman.conf >/dev/null || die "failed to update /etc/pacman.conf"
fi

if ! sudo pacman -Syu --noconfirm; then
    echo " ⚠ pacman -Syu failed; continuing, but Omarchy repo may be out of date" >&2
fi
echo " ✓ Repository configured"

echo ""
echo ">> User configuration"
echo "Username:"
read -r OMARCHY_USER_NAME
export OMARCHY_USER_NAME
echo "Email:"
read -r OMARCHY_USER_EMAIL
export OMARCHY_USER_EMAIL

echo ""
echo ">> Configuring SDDM autologin..."
run sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/autologin.conf > /dev/null <<EOF
[Autologin]
User=$USER
Session=hyprland
EOF
echo " ✓ Configured"

echo ""
echo ">> Applying CachyOS compatibility patches..."
[[ ! -f "install.sh" ]] && die "install.sh not found. Make sure you are inside the omarchy folder!"

if [[ -f "bin/omarchy-update-restart" ]]; then
    sed -i "s# | sed 's/-arch/\\\\.arch/'##" bin/omarchy-update-restart
    sed -i "s#'{print \$2}'#'{print \$2 \" - \" \$1}' | sed 's/-linux//'#" bin/omarchy-update-restart
    sed -i "/linux-cachyos/ ! s/pacman -Q linux/pacman -Q linux-cachyos/" bin/omarchy-update-restart
fi



if [[ -f "install/omarchy-base.packages" ]]; then
    sed -i '/tldr/d' install/omarchy-base.packages || die "failed to remove tldr package"
fi

if [[ -f "install/preflight/all.sh" ]]; then
    sed -i '/run_logged \$OMARCHY_INSTALL\/preflight\/pacman\.sh/d' install/preflight/all.sh || \
    die "failed to patch install/preflight/all.sh"
fi

if [[ -f "install/config/all.sh" ]]; then
    sed -i '/run_logged \$OMARCHY_INSTALL\/config\/hardware\/nvidia\.sh/d' install/config/all.sh || \
    die "failed to patch install/config/all.sh"
fi

if [[ -f "install/login/all.sh" ]]; then
    sed -i \
    -e '/run_logged \$OMARCHY_INSTALL\/login\/plymouth\.sh/d' \
    -e '/run_logged \$OMARCHY_INSTALL\/login\/limine-snapper\.sh/d' \
    -e '/run_logged \$OMARCHY_INSTALL\/login\/alt-bootloaders\.sh/d' \
    install/login/all.sh || die "failed to patch install/login/all.sh"
fi

if [[ -f "install/post-install/all.sh" ]]; then
    sed -i '/run_logged \$OMARCHY_INSTALL\/post-install\/pacman\.sh/d' install/post-install/all.sh || \
    die "failed to patch install/post-install/all.sh"
fi

if [[ -f "config/uwsm/env" ]]; then
    cp config/uwsm/env config/uwsm/env.bak
    if grep -q "omarchy-cmd-present mise" config/uwsm/env; then
        sed -i '/omarchy-cmd-present mise.*activate bash/c\
if command -v mise > /dev/null 2>&1; then\
    eval "$(mise activate bash)"\
fi' config/uwsm/env || die "failed to patch config/uwsm/env"
    fi
fi
echo " ✓ CachyOS patches applied"

echo ""
echo ">> Copying to ~/.local/share/omarchy..."
mkdir -p ~/.local/share/omarchy
cp -r . ~/.local/share/omarchy
cd ~/.local/share/omarchy || die "cannot cd ~/.local/share/omarchy"
echo " ✓ Copied"

echo ""
echo ">> Backing up existing config..."
if [[ -d ~/.config/hypr ]]; then
    cp -r ~/.config/hypr ~/.config/hypr.backup.$(date +%s)
    echo " ✓ Backed up (~/.config/hypr.backup.*)"
else
    echo " ⊘ No existing config"
fi

echo ""
echo ">> Configuring Fish..."
if command -v fish &> /dev/null; then
    fish -c "set -Ux OMARCHY_PATH $HOME/.local/share/omarchy" 2>/dev/null
    fish -c "fish_add_path $HOME/.local/share/omarchy/bin" 2>/dev/null || true
    echo " ✓ Fish configured"
else
    echo " ⊘ Fish not found"
fi

echo ""
echo "======================================================================"
echo " READY TO INSTALL"
echo "======================================================================"
echo ""
echo "✓ CachyOS patches applied"
echo "✓ SDDM autologin configured"
echo "✓ Fish configured"
echo ""
echo "Press Enter to launch Omarchy installer..."
read -r

[[ ! -x "install.sh" ]] && chmod +x install.sh
echo ""
echo ">> Launching Omarchy installer..."
./install.sh
