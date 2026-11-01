#!/usr/bin/env bash
# desktop.sh — Hyprland Desktop & Apps
set -euo pipefail
TITOS_DIR="${TITOS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

echo ":: Installiere Hyprland & Umgebung / Installing Hyprland & environment..."
sudo pacman -S --needed --noconfirm \
    hyprland hyprpaper hypridle hyprlock \
    waybar wofi dunst kitty thunar \
    firefox neovim \
    grim slurp wl-clipboard \
    polkit-gnome xdg-desktop-portal-hyprland \
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji \
    figlet

echo ":: Verlinke Dotfiles / Symlinking dotfiles -> ~/.config ..."
mkdir -p "$HOME/.config/hypr" "$HOME/.config/waybar" "$HOME/.config/kitty" "$HOME/.config/nvim"
ln -sf "$TITOS_DIR/dotfiles/hyprland/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
ln -sf "$TITOS_DIR/dotfiles/waybar/config"          "$HOME/.config/waybar/config"
ln -sf "$TITOS_DIR/dotfiles/waybar/style.css"       "$HOME/.config/waybar/style.css"
ln -sf "$TITOS_DIR/dotfiles/kitty/kitty.conf"       "$HOME/.config/kitty/kitty.conf"
ln -sf "$TITOS_DIR/dotfiles/nvim/init.vim"          "$HOME/.config/nvim/init.vim"

echo ":: Installiere titos-splash / titos-update nach /usr/local/bin ..."
sudo install -m 755 "$TITOS_DIR/scripts/titos-splash"  /usr/local/bin/titos-splash
sudo install -m 755 "$TITOS_DIR/scripts/titos-update"  /usr/local/bin/titos-update

echo ":: Füge titos-splash zum Shell-Start hinzu / add splash to .zshrc ..."
RC="$HOME/.zshrc"
touch "$RC"
if ! grep -q 'titos-splash' "$RC"; then
    {
        echo ''
        echo '# titOS Begrüßungsscreen / welcome screen'
        echo 'command -v titos-splash >/dev/null && titos-splash'
    } >> "$RC"
fi

echo "✔ Desktop fertig / desktop done"
