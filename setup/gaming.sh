#!/usr/bin/env bash
# gaming.sh — Gaming-Stack Installation / Gaming stack installation
set -euo pipefail
GPU_VENDOR="${GPU_VENDOR:-amd}"

echo ":: Aktiviere Multilib-Repo / Enabling multilib repo..."
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
fi
sudo pacman -Sy --noconfirm

echo ":: Installiere Gaming-Kernel (linux-zen) / Installing gaming kernel..."
sudo pacman -S --needed --noconfirm linux-zen linux-zen-headers

echo ":: Installiere Steam & Tools / Installing Steam & tools..."
sudo pacman -S --needed --noconfirm \
    steam \
    gamemode lib32-gamemode \
    mangohud lib32-mangohud \
    wine-staging winetricks \
    vulkan-tools vulkan-icd-loader lib32-vulkan-icd-loader \
    lutris

echo ":: GPU-Treiber / GPU drivers: ${GPU_VENDOR}"
case "$GPU_VENDOR" in
    amd)
        sudo pacman -S --needed --noconfirm vulkan-radeon lib32-vulkan-radeon mesa lib32-mesa
        ;;
    nvidia)
        sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings
        ;;
    intel)
        sudo pacman -S --needed --noconfirm vulkan-intel lib32-vulkan-intel mesa lib32-mesa
        ;;
esac

echo ":: AUR-Gaming-Pakete / AUR gaming packages..."
# Proton-GE Manager, DXVK, VKD3D, Heroic, Gamepad-Support
AUR_PKGS=(protonup-qt dxvk-bin vkd3d-proton-bin heroic-games-launcher-bin xpadneo-dkms)
if [[ "${USE_ISO:-0}" -eq 1 ]]; then
    echo "   AUR-Pakete sind bereits offline in der ISO enthalten / already baked into ISO"
else
    yay -S --needed --noconfirm "${AUR_PKGS[@]}" || echo "! Einige AUR-Pakete fehlgeschlagen / some AUR packages failed"
fi

echo "✔ Gaming-Stack fertig / gaming stack done"
