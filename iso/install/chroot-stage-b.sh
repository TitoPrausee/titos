#!/usr/bin/env bash
# titOS chroot Stage B — läuft IM Zielsystem (root)
# Bootloader installieren, Dienste aktivieren, Install-Sudoers entfernen.
set -euo pipefail
DISK="${1:?DISK fehlt}"
EFI_MODE="${2:?EFI_MODE fehlt}"

echo ":: Bootloader / bootloader (${EFI_MODE}) ..."
if [[ "$EFI_MODE" == "yes" ]]; then
    grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=titOS --recheck
else
    grub-install --target=i386-pc --boot-directory=/boot "$DISK"
fi
grub-mkconfig -o /boot/grub/grub.cfg

echo ":: Dienste aktivieren ..."
systemctl enable NetworkManager
systemctl enable fstrim.timer 2>/dev/null || true
# SSH aus aber installierbar — Service nicht automatisch aktivieren

echo ":: Aufräumen ..."
rm -f /etc/sudoers.d/99-titos-temp-install
rm -f /tmp/titos-install.env /tmp/.titos-boot-pass

echo "✔ Stage B fertig."