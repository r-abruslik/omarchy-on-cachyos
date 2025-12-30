Gave mroboff's script to AI scaffolding stack(gemini3pro,claude,llama70B,etc) to fix and change it to my liking. 
The script patches Omarchy's Hyprland configs before running Omarchy's installer, so Hyprland boots cleanly on v0.53+ after the first reboot.

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

git clone https://github.com/r-abruslik/omarchy-on-cachyos.git
cd omarchy-on-cachyos
chmod +x install.sh
./install.sh
