Enhanced version of [mroboff's script](https://github.com/mroboff/omarchy-on-cachyos).
# omarchy-on-cachyos

Installs Omarchy on CachyOS Hyprland.

## Prerequisites

- Fresh **CachyOS** install (fully updated)
- **Limine** bootloader
- **Btrfs + Snapper** filesystem
- **Bash** shell as default
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
