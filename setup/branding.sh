#!/usr/bin/env bash
# branding.sh — titOS Branding (Plymouth, GRUB, Hostname, os-release)
set -euo pipefail
TITOS_DIR="${TITOS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

echo ":: Setze Hostname / Setting hostname -> titos ..."
echo "titos" | sudo tee /etc/hostname >/dev/null

echo ":: Passe /etc/os-release an / Customising os-release ..."
sudo tee /etc/os-release >/dev/null <<OSR
NAME="titOS"
PRETTY_NAME="titOS — AI-Powered Gaming Linux"
ID=titos
ID_LIKE=arch
BUILD_ID=rolling
ANSI_COLOR="1;35"
HOME_URL="https://github.com/titos"
LOGO=titos
OSR

echo ":: Installiere Plymouth / Installing Plymouth..."
sudo pacman -S --needed --noconfirm plymouth
sudo mkdir -p /usr/share/plymouth/themes/titos
sudo cp -r "$TITOS_DIR/plymouth/titos/." /usr/share/plymouth/themes/titos/
# Plymouth-Hook in mkinitcpio / add plymouth hook
if ! grep -q 'plymouth' /etc/mkinitcpio.conf; then
    sudo sed -i 's/^\(HOOKS=.*\)base udev/\1base udev plymouth/' /etc/mkinitcpio.conf
fi
sudo plymouth-set-default-theme -R titos || sudo plymouth-set-default-theme titos
# Kernel-Cmdline Hinweis / add 'splash' to kernel params (GRUB)
sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 splash quiet"/' /etc/default/grub || true

echo ":: Installiere GRUB-Theme / Installing GRUB theme..."
sudo mkdir -p /boot/grub/themes/titos
sudo cp -r "$TITOS_DIR/grub/titos-grub-theme/." /boot/grub/themes/titos/
if grep -q '^GRUB_THEME=' /etc/default/grub; then
    sudo sed -i 's|^GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/titos/theme.txt"|' /etc/default/grub
else
    echo 'GRUB_THEME="/boot/grub/themes/titos/theme.txt"' | sudo tee -a /etc/default/grub >/dev/null
fi

echo ":: Regeneriere initramfs & GRUB / Regenerating initramfs & GRUB config..."
sudo mkinitcpio -P || true
sudo grub-mkconfig -o /boot/grub/grub.cfg || echo "! grub-mkconfig fehlgeschlagen (ggf. kein GRUB) / failed (maybe no GRUB)"

echo "✔ Branding fertig / branding done"
