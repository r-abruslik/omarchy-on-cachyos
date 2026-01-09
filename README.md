Enhanced version of [mroboff's script](https://github.com/mroboff/omarchy-on-cachyos).
# omarchy-on-cachyos

Installs Omarchy on CachyOS Hyprland.

## Prerequisites

- Fresh **CachyOS** install (fully updated)
- **Limine** bootloader
- **Btrfs + Snapper** filesystem
- **CachyOS Hyprland** desktop profile (includes SDDM)
- **git** installed

## Installation

```bash
git clone https://github.com/r-abruslik/omarchy-on-cachyos.git
cd omarchy-on-cachyos/bin
chmod +x install-omarchy-on-cachyos.sh
./install-omarchy-on-cachyos.sh
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
