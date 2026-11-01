#!/usr/bin/env bash
# base.sh — Basis-System Setup / Base system setup
set -euo pipefail

USE_ISO="${USE_ISO:-0}"
export USE_ISO

echo ":: Konfiguriere pacman / Configuring pacman..."
# Parallel-Downloads & Farbe aktivieren / enable parallel downloads & color
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
sudo sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
grep -q '^ParallelDownloads' /etc/pacman.conf || echo 'ParallelDownloads = 10' | sudo tee -a /etc/pacman.conf

echo ":: Aktualisiere System / Updating system..."
sudo pacman -Syu --noconfirm

echo ":: Installiere Basis-Pakete / Installing base packages..."
sudo pacman -S --needed --noconfirm git curl wget base-devel zsh

# yay (AUR-Helper) installieren / install yay
if ! command -v yay >/dev/null 2>&1; then
    echo ":: Installiere yay (AUR) ..."
    tmp="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay.git "$tmp/yay"
    (cd "$tmp/yay" && makepkg -si --noconfirm)
    rm -rf "$tmp"
fi

# oh-my-zsh installieren / install oh-my-zsh (nur als normaler User / only as regular user)
if [[ $EUID -ne 0 ]]; then
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        echo ":: Installiere oh-my-zsh ..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    # Standard-Shell auf zsh setzen / set default shell to zsh
    if [[ "$SHELL" != *zsh ]]; then
        chsh -s "$(command -v zsh)" || sudo chsh -s "$(command -v zsh)" "$USER" || true
    fi
else
    echo ":: Überspringe oh-my-zsh/chsh im Root-Kontext / skipping oh-my-zsh/chsh as root"
fi

echo "✔ Basis-System fertig / base system done"
