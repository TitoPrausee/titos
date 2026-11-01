#!/usr/bin/env bash
# titOS chroot Stage A — läuft IM Zielsystem (root)
# Locale, Hostname, yay-Bau, Benutzer, dann titOS install.sh als Benutzer.
set -euo pipefail

set -a
source /tmp/titos-install.env
set +a
TITOS_USER="${TITOS_USER:?TITOS_USER fehlt}"
TITOS_GPU="${TITOS_GPU:-amd}"
BOOT_PASSWORD="$(cat /tmp/.titos-boot-pass)"

echo ":: Lokalisierung / locale ..."
sed -i 's/^#de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=de_DE.UTF-8" > /etc/locale.conf
printf 'KEYMAP=de-latin1\nFONT=ter-116n\n' > /etc/vconsole.conf

echo ":: Zeitzone Europe/Berlin ..."
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

echo ":: Hostname -> titos ..."
echo "titos" > /etc/hostname
printf '127.0.0.1   localhost\n::1         localhost\n127.0.1.1   titos\n' > /etc/hosts

echo ":: mkinitcpio (linux-zen) ..."
mkinitcpio -P

echo ":: baut yay (AUR-Helper) ..."
if ! command -v yay >/dev/null 2>&1; then
    install -d -m 755 /tmp/yaybuild
    git clone -q https://aur.archlinux.org/yay.git /tmp/yaybuild/yay
    chown -R nobody: /tmp/yaybuild/yay
    if ! (cd /tmp/yaybuild/yay && sudo -u nobody makepkg --noconfirm -sf); then
        pacman -S --needed --noconfirm go
        (cd /tmp/yaybuild/yay && sudo -u nobody makepkg --noconfirm -sf)
    fi
    pacman -U --noconfirm /tmp/yaybuild/yay/yay-*.pkg.tar.zst
    rm -rf /tmp/yaybuild
fi

echo ":: Benutzer ${TITOS_USER} anlegen ..."
if ! id "$TITOS_USER" >/dev/null 2>&1; then
    useradd -m -G wheel -s /bin/bash "$TITOS_USER"
fi
printf '%s:%s' "$TITOS_USER" "$BOOT_PASSWORD" | chpasswd

echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/10-titos-wheel
chmod 440 /etc/sudoers.d/10-titos-wheel
# Temp NOPASSWD nur während der Installation (wird in Stage B entfernt)
echo "${TITOS_USER} ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/99-titos-temp-install
chmod 440 /etc/sudoers.d/99-titos-temp-install

echo ":: titOS-Quellen nach /opt/titos ..."
cp -R /usr/lib/titos-iso/titos /opt/titos
chown -R "${TITOS_USER}":"${TITOS_USER}" /opt/titos

echo ":: titOS install.sh --iso (als ${TITOS_USER}, GPU=${TITOS_GPU^^}) ..."
runuser -u "${TITOS_USER}" -- bash -c \
    "set -a; source /tmp/titos-install.env; set +a; bash /opt/titos/install.sh --iso"

echo ":: Hyprland-Hinweis in .zshrc ..."
if ! grep -q 'Hyprland' "/home/${TITOS_USER}/.zshrc" 2>/dev/null; then
    printf '\n# titOS\ncommand -v titos-splash >/dev/null && echo "  Desktop starten: Hyprland"\n' \
        >> "/home/${TITOS_USER}/.zshrc"
    chown "${TITOS_USER}":"${TITOS_USER}" "/home/${TITOS_USER}/.zshrc"
fi

echo "✔ Stage A fertig."