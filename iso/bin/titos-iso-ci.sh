#!/usr/bin/env bash
# titos-iso-ci — CI-Einstiegspunkt für beide Architekturen
# x86_64: Arch-Linux-Toolchain im Docker-Container (ubuntu-latest Runner)
# aarch64: native ARM-Runner + ALARM-Rootfs-Chroot (kein qemu!)
#   Usage: sudo ./bin/titos-iso-ci.sh  [x86_64|aarch64]
set -euo pipefail
ARCH="${1:-$(uname -m)}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$REPO_ROOT/out"
mkdir -p "$OUT"

[[ $EUID -eq 0 ]] || { echo "Bitte mit sudo laufen lassen."; exit 1; }
echo ":: [titOS-CI] target=$ARCH host=$(uname -m)"

# titOS-Quellen liegen im Repo-Root (nicht iso/titos) — dem Builder via TITOS_SRC sagen
export TITOS_SRC="$REPO_ROOT"

cleanup() {
    umount "$ROOTFS/dev" "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/run" 2>/dev/null || true
}
ROOTFS="/var/tmp/titos-alarm-rootfs"

if [[ "$ARCH" == "x86_64" ]]; then
    # ─── x86_64: Arch-Toolchain-Container ────────────────────────────────────
    docker pull --platform linux/amd64 ghcr.io/archlinux/archlinux:latest
    docker run --privileged --platform linux/amd64 --rm \
        -v "$REPO_ROOT:/iso" \
        ghcr.io/archlinux/archlinux:latest \
        bash -ec '
            # stabiler Geo-Mirror zuerst (fastly hatte Timeouts)
            sed -i "1i Server = https://geo.mirror.pkgbuild.com/\$repo/os/\$arch" /etc/pacman.d/mirrorlist
            pacman -Syu --noconfirm || pacman -Syu --noconfirm
            pacman -S --needed --noconfirm archiso openssl zsh rsync
            cd /iso
            TITOS_SRC=/iso OUT=/iso/out ./bin/titos-iso-make
        '
    cp "$REPO_ROOT"/out/* "$OUT/" 2>/dev/null || true
else
    # ─── aarch64: ALARM-Rootfs nativ ─────────────────────────────────────────
    echo ":: Lade Arch Linux ARM rootfs (aarch64) ..."
    cd /var/tmp
    [[ -f alarm-aarch64.tar.gz ]] || \
        curl -fL --retry 3 -o alarm-aarch64.tar.gz \
            "http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz"

    echo ":: Entpacke nach $ROOTFS ..."
    rm -rf "$ROOTFS"
    mkdir -p "$ROOTFS"
    tar -xzf alarm-aarch64.tar.gz -C "$ROOTFS"
    rm -f /var/tmp/alarm-aarch64.tar.gz   # Platz sparen (Runner-Disk)
    cp -L /etc/resolv.conf "$ROOTFS/etc/resolv.conf"

    # pacman-Fehlalarme im chroot abstellen (OverlayFS kann cachedir nicht staten)
    mkdir -p "$ROOTFS/var/cache/pacman/pkg"
    sed -i '/^CheckSpace$/d' "$ROOTFS/etc/pacman.conf"

    echo ":: Bind-Mounts ..."
    mount --bind /dev  "$ROOTFS/dev"
    mount --bind /proc "$ROOTFS/proc"
    mount --bind /sys  "$ROOTFS/sys"
    mount --bind /run  "$ROOTFS/run"
    trap cleanup EXIT

    echo ":: Keyrings + Build-Tools im chroot ..."
    chroot "$ROOTFS" bash -ec '
        # Bootstrap-Trick: erste Transaktion ohne Sig-Check (Keyring-Verifikation
        # kommt sonst in den Zirkel: Keyring-Install prüft mit fehlendem Keyring)
        sed -i "s|^SigLevel.*|SigLevel = Never|" /etc/pacman.conf
        pacman -Sy --noconfirm archlinuxarm-keyring archlinux-keyring
        sed -i "s|^SigLevel.*|SigLevel = Required DatabaseOptional|" /etc/pacman.conf
        pacman-key --init
        pacman-key --populate archlinuxarm archlinux
        pacman -Syu --noconfirm
        pacman -S --needed --noconfirm openssl zsh sudo rsync dosfstools
        # archiso ist NICHT in den ALARM-Repos: any-Paket von Arch mirror ziehen
        curl -fL -o /tmp/archiso.pkg.tar.zst \
            "https://geo.mirror.pkgbuild.com/extra/os/x86_64/archiso-91-1-any.pkg.tar.zst" \
        && pacman -U --noconfirm /tmp/archiso.pkg.tar.zst \
        || echo "! archiso-Download fehlgeschlagen"
        pacman -Q archiso || exit 1
    '

    echo ":: Repo ins chroot ..."
    rm -rf "$ROOTFS/repo"
    cp -R "$REPO_ROOT" "$ROOTFS/repo"

    echo ":: Baue ARM64-ISO im chroot ..."
    chroot "$ROOTFS" bash -ec 'export TITOS_SRC=/repo; cd /repo && OUT=/repo/out ./bin/titos-iso-make'

    echo ":: Hole ISO + Checksumme ..."
    cp "$ROOTFS"/repo/out/*.iso "$ROOTFS"/repo/out/*.sha256 "$OUT/" 2>/dev/null || \
        cp "$ROOTFS"/repo/out/*  "$OUT/"
fi

echo ""
ls -lh "$OUT"