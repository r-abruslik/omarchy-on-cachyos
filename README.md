Enhanced version of [mroboff's script](https://github.com/mroboff/omarchy-on-cachyos) with Hyprland v0.53+ fixes applied before installation, ensuring clean boot on first reboot.

# omarchy-on-cachyos

Installs Omarchy on CachyOS Hyprland with pre-patched configs for Hyprland v0.53+.

## Prerequisites

- Fresh **CachyOS** install (fully updated)
- **Limine** bootloader (required by Omarchy)
- Recommended:
  - **Btrfs + Snapper** filesystem
  - **Fish** shell as default
  - **CachyOS Hyprland** desktop profile (includes SDDM)
- **git** installed

## Installation

### Standard (Recommended)

Full feedback with progress messages and error checking:

```bash
git clone https://github.com/r-abruslik/omarchy-on-cachyos.git
cd omarchy-on-cachyos/bin
chmod +x install-omarchy-on-cachyos.sh
./install-omarchy-on-cachyos.sh
```

### YOLO Mode (Advanced)

Silent installation without error checking:

```bash
git clone https://github.com/r-abruslik/omarchy-on-cachyos.git
cd omarchy-on-cachyos/bin
chmod +x install-omarchy-yolo.sh
./install-omarchy-yolo.sh
```

## Post-Install: Restore CachyOS Performance Settings (Optional)

If you want CachyOS's performance optimizations back, add to `~/.config/hypr/looknfeel.conf`:

```bash
# CachyOS performance tweaks
misc {
    vrr = 2  # Variable refresh rate
}

render {
    direct_scanout = true  # Direct scanout bypass
}
