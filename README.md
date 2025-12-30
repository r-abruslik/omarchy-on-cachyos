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

```bash
git clone https://github.com/r-abruslik/omarchy-on-cachyos.git
cd omarchy-on-cachyos
chmod +x install.sh
./install.sh
```
