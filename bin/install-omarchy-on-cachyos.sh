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
    cd - || die "cannot return to omarchy directory"
fi
echo " ✓ yay ready"

echo ""
echo ">> Setting up Omarchy repository..."
run sudo pacman-key --recv-keys F0134EE680CAC571
run sudo pacman-key --lsign-key F0134EE680CAC571

if ! grep -q "[omarchy]" /etc/pacman.conf; then
    printf '
[omarchy]
SigLevel = Optional TrustedOnly
Server = https://pkgs.omarchy.org/$arch
' | \
    sudo tee -a /etc/pacman.conf >/dev/null || die "failed to update /etc/pacman.conf"
fi

if ! sudo pacman -Syu --noconfirm; then
    echo " ⚠ pacman -Syu failed; continuing, but Omarchy repo may be out of date" >&2
fi
echo " ✓ Repository configured"

echo ""
echo ">> User configuration"
OMARCHY_USER_NAME="$USER"
echo "Using current user: $OMARCHY_USER_NAME"
echo "Email:"
read -r OMARCHY_USER_EMAIL
export OMARCHY_USER_NAME
export OMARCHY_USER_EMAIL

echo ""
echo ">> Configuring SDDM autologin..."
run sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/autologin.conf > /dev/null <<EOF
[Autologin]
User=$OMARCHY_USER_NAME
Session=hyprland
EOF
echo " ✓ Configured (autologin for $OMARCHY_USER_NAME)"

echo ""
echo ">> Applying CachyOS compatibility patches..."
[[ ! -f "install.sh" ]] && die "install.sh not found. Make sure you are inside the omarchy folder!"

# Patch omarchy-update-restart for CachyOS kernel naming
if [[ -f "bin/omarchy-update-restart" ]]; then
    sed -i "s# | sed 's/-arch/\\\\.arch/'##" bin/omarchy-update-restart
    sed -i "s#'{print $2}'#'{print $2 " - " $1}' | sed 's/-linux//'#" bin/omarchy-update-restart
    sed -i "/linux-cachyos/ ! s/pacman -Q linux/pacman -Q linux-cachyos/" bin/omarchy-update-restart
fi

# Remove tldr package (conflicts with CachyOS)
if [[ -f "install/omarchy-base.packages" ]]; then
    sed -i '/tldr/d' install/omarchy-base.packages || die "failed to remove tldr package"
fi

# ADD FISH PACKAGE TO INSTALL LIST
if [[ -f "install/omarchy-base.packages" ]]; then
    echo "omarchy-fish" >> install/omarchy-base.packages
    echo " ✓ Added omarchy-fish to package list"
fi

# Skip preflight pacman checks (CachyOS already configured)
if [[ -f "install/preflight/all.sh" ]]; then
    sed -i '/run_logged $OMARCHY_INSTALL/preflight/pacman.sh/d' install/preflight/all.sh || \
    die "failed to patch install/preflight/all.sh"
fi

# Skip nvidia setup (handle manually if needed)
if [[ -f "install/config/all.sh" ]]; then
    sed -i '/run_logged $OMARCHY_INSTALL/config/hardware/nvidia.sh/d' install/config/all.sh || \
    die "failed to patch install/config/all.sh"
fi

# Skip plymouth, limine-snapper, alt-bootloaders (CachyOS uses Limine differently)
if [[ -f "install/login/all.sh" ]]; then
    sed -i \
    -e '/run_logged $OMARCHY_INSTALL/login/plymouth.sh/d' \
    -e '/run_logged $OMARCHY_INSTALL/login/limine-snapper.sh/d' \
    -e '/run_logged $OMARCHY_INSTALL/login/alt-bootloaders.sh/d' \
    install/login/all.sh || die "failed to patch install/login/all.sh"
fi

# Skip post-install pacman configuration
if [[ -f "install/post-install/all.sh" ]]; then
    sed -i '/run_logged $OMARCHY_INSTALL/post-install/pacman.sh/d' install/post-install/all.sh || \
    die "failed to patch install/post-install/all.sh"
fi

# INJECT FISH SETUP INTO FINISHED.SH
if [[ -f "install/post-install/finished.sh" ]]; then
    sed -i '1i run_logged omarchy-setup-fish' install/post-install/finished.sh || \
    die "failed to patch finished.sh"
    echo " ✓ Injected fish setup into finish sequence"
fi

echo " ✓ CachyOS patches applied"

echo ""
echo ">> Copying patched Omarchy to ~/.local/share/omarchy..."
rm -rf ~/.local/share/omarchy
mkdir -p ~/.local/share/omarchy
cp -a . ~/.local/share/omarchy || die "failed to copy omarchy files"
cd ~/.local/share/omarchy || die "cannot cd to ~/.local/share/omarchy"
echo " ✓ Copied (with git repository preserved)"

echo ""
echo "======================================================================"
echo " READY TO INSTALL OMARCHY WITH FISH SHELL"
echo "======================================================================"
echo ""
echo "✓ CachyOS compatibility patches applied"
echo "✓ SDDM autologin configured for $OMARCHY_USER_NAME"
echo "✓ omarchy-fish added to package list"
echo "✓ omarchy-setup-fish injected into finish sequence"
echo "✓ Git repository preserved for future updates"
echo ""
echo "IMPORTANT: Keep bash as your login shell."
echo "Fish will launch automatically in your terminal."
echo ""
echo "Press Enter to launch Omarchy installer..."
read -r

[[ ! -x "install.sh" ]] && chmod +x install.sh
echo ""
echo ">> Launching Omarchy installer..."
./install.sh
