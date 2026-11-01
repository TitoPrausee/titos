#!/usr/bin/env bash
# titOS Live-Installer — läuft in der Live-Umgebung (root)
# Partitionsiert, pacstrap't Arch + linux-zen und lässt Stage A/B das
# titOS-System aufsetzen. Interaktiv (auch über Serielle Konsole nutzbar).
set -euo pipefail

# ─── Farben ──────────────────────────────────────────────────────────────────
P='\033[1;35m'; C='\033[1;36m'; G='\033[1;32m'; Y='\033[1;33m'; R='\033[0m'; D='\033[2m'

echo -e "${P}══════════════════════════════════════════════${R}"
echo -e "${P}  titOS Installer — AI-Powered Gaming Linux${R}"
echo -e "${P}══════════════════════════════════════════════${R}"
echo
echo -e "${D}Achtung: die Netzwerkverbindung muss stehen${R}"
echo -e "${D}(Ethernet: DHCP automatisch — WLAN: 'nmtui' vorher verbinden)${R}"
echo
echo -e "${C}Verfügbare Platten / available disks:${R}"
lsblk -d -e 7,11 -o NAME,SIZE,TYPE,MODEL 2>/dev/null || lsblk -d -o NAME,SIZE,TYPE,MODEL
echo

read -rp "Ziel-Platte eingeben (z.B. /dev/vda oder /dev/sda): " DISK
DISK="${DISK:-}"
[[ -b "$DISK" ]] || { echo -e "${Y}✖${R} $DISK ist keine Blockplatte. Abbruch."; exit 1; }

read -rp "$(echo -e "${Y}⚠ ALLE Daten auf ${DISK} werden gelöscht! Fortfahren? [ja/NEIN]: ${R}")" OK
if [[ "${OK,,}" != "ja" ]]; then echo "Abgebrochen."; exit 1; fi

# ─── Benutzer ────────────────────────────────────────────────────────────────
read -rp "Benutzername [tito]: " U
TITOS_USER="${U:-tito}"
while :; do
    read -rsp "Passwort für ${TITOS_USER}: " P1; echo
    read -rsp "Wiederholen: " P2; echo
    if [[ -n "$P1" && "$P1" == "$P2" ]]; then break; fi
    echo -e "${Y}!${R} Passwörter leer oder ungleich — nochmal."
done
printf '%s' "$P1" > /tmp/.titos-boot-pass
chmod 600 /tmp/.titos-boot-pass

# ─── UEFI oder BIOS ──────────────────────────────────────────────────────────
EFI_MODE="no"
[[ -d /sys/firmware/efi/efivars ]] && EFI_MODE="yes"
echo -e "${C}→ Boot-Modus: ${EFI_MODE^^}${R}"

# ─── Partitionierung ─────────────────────────────────────────────────────────
echo -e "${C}:: Partitioniere ${DISK} ...${R}"
wipefs -af "$DISK"
sgdisk -o "$DISK"
# 1) 1 MiB BIOS-Boot (schadet UEFI nicht, rettet BIOS-Boots)
sgdisk -n 1:0:+1M -t 1:EF02 "$DISK"
# 2) 1 GiB ESP
sgdisk -n 2:0:+1G -t 2:EF00 "$DISK"
# 3) Rest als Root
sgdisk -n 3:0:0 -t 3:8300 "$DISK"

P2="${DISK}2"; P3="${DISK}3"
echo -e "${C}:: Formatiere ...${R}"
mkfs.fat -F32 -n TITOS-EFI "$P2"
mkfs.ext4 -F -L titos-root "$P3"

mount "$P3" /mnt
mkdir -p /mnt/efi
mount "$P2" /mnt/efi

# ─── Architektur / Architektur (x86_64 | aarch64) ────────────────────────────
ARCH="$(uname -m)"
IS_ARM=0
[[ "$ARCH" == "aarch64" ]] && IS_ARM=1

# ─── Basis-System ────────────────────────────────────────────────────────────
if [[ $IS_ARM -eq 1 ]]; then
    echo -e "${C}:: pacstrap Basis-System (linux-aarch64) — dauert ein paar Minuten ...${R}"
    pacstrap -K /mnt \
        base linux-aarch64 linux-aarch64-headers linux-firmware \
        base-devel git go \
        arch-install-scripts \
        sudo zsh networkmanager \
        grub efibootmgr \
        pciutils usbutils \
        openssh vim nano tmux jq curl wget \
        terminus-font man-db \
        archlinux-keyring archlinuxarm-keyring \
        dosfstools e2fsprogs gptfdisk btrfs-progs rsync
else
    echo -e "${C}:: pacstrap Basis-System (linux-zen) — dauert ein paar Minuten ...${R}"
    pacstrap -K /mnt \
        base linux-zen linux-zen-headers linux-firmware \
        intel-ucode amd-ucode \
        base-devel git go \
        arch-install-scripts \
        sudo zsh networkmanager \
        grub efibootmgr \
        pciutils usbutils \
        openssh vim nano tmux jq curl wget \
        terminus-font man-db \
        archlinux-keyring \
        dosfstools e2fsprogs gptfdisk btrfs-progs rsync
fi

printf 'TITOS_ARCH=%s\n' "$ARCH" > /tmp/titos-install.env

echo -e "${C}:: Schreibe fstab ...${R}"
genfstab -U /mnt >> /mnt/etc/fstab

echo -e "${C}:: DNS für chroot rüberkopieren ...${R}"
cp -L /etc/resolv.conf /mnt/etc/resolv.conf

# ─── Konfig für chroot vorbereiten ───────────────────────────────────────────
if [[ $IS_ARM -eq 1 ]]; then
    GPU="none"   # ARM: kein dedizierter Gaming-GPU-Pfad / no dedicated GPU stack
else
    GPU="amd"
    if lspci 2>/dev/null | grep -qi nvidia; then
        GPU="nvidia"
    elif lspci 2>/dev/null | grep -Eiq 'amd|ati|radeon'; then
        GPU="amd"
    elif lspci 2>/dev/null | grep -qi intel; then
        GPU="intel"
    fi
fi
echo -e "${C}→ GPU-Vendor für Titel: ${GPU}${R}"
printf 'TITOS_GPU=%s\nTITOS_USER=%s\nIS_ARM=%s\n' "$GPU" "$TITOS_USER" "$IS_ARM" >> /tmp/titos-install.env
chmod 644 /tmp/titos-install.env

# Stage-Skripte + Boot-Pass + Env ins Zielsystem kopieren
mkdir -p /mnt/usr/lib/titos-iso/install /mnt/tmp
cp /usr/lib/titos-iso/install/chroot-stage-a.sh /mnt/usr/lib/titos-iso/install/
cp /usr/lib/titos-iso/install/chroot-stage-b.sh /mnt/usr/lib/titos-iso/install/
cp /tmp/titos-install.env /mnt/tmp/
cp /tmp/.titos-boot-pass /mnt/tmp/

# ─── Stage A: Locale, Hostname, yay, User, titOS-Installer ───────────────────
echo -e "${C}:: Stage A — Basis-Setup im Zielsystem ...${R}"
arch-chroot /mnt /usr/lib/titos-iso/install/chroot-stage-a.sh

# ─── Stage B: Bootloader + Dienste ───────────────────────────────────────────
echo -e "${C}:: Stage B — Bootloader & Dienste ...${R}"
arch-chroot /mnt /usr/lib/titos-iso/install/chroot-stage-b.sh "$DISK" "$EFI_MODE"

umount -R /mnt

echo ""
echo -e "${G}══════════════════════════════════════════════${R}"
echo -e "${G}  titOS Installation abgeschlossen.${R}"
echo -e "${G}══════════════════════════════════════════════${R}"
read -rp "Jetzt neu starten? [Enter/Strg+C]: " _
systemctl reboot --no-wall 2>/dev/null || reboot -f