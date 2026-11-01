#!/usr/bin/env bash
# titOS Installer — Haupt-Installer / Main installer
# Installiert das komplette titOS System auf einem Arch-Linux-Rechner.
# Installs the complete titOS system on an Arch Linux machine.
set -euo pipefail

# ─── Unattended-Modus / unattended mode (ISO) ────────────────────────────────
USE_ISO=0
if [[ "${1:-}" == "--iso" || "${1:-}" == "--yes" ]]; then
    USE_ISO=1
fi

# ─── Pfade / Paths ────────────────────────────────────────────────────────────
TITOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export TITOS_DIR

# ─── Farben / Colors ──────────────────────────────────────────────────────────
C_RESET='\033[0m'
C_PURPLE='\033[1;35m'
C_CYAN='\033[1;36m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[1;31m'
C_DIM='\033[2m'

# ─── Hilfsfunktionen / Helpers ────────────────────────────────────────────────
info()  { echo -e "${C_CYAN}::${C_RESET} $*"; }
ok()    { echo -e "${C_GREEN}✔${C_RESET} $*"; }
warn()  { echo -e "${C_YELLOW}!${C_RESET} $*"; }
err()   { echo -e "${C_RED}✖${C_RESET} $*" >&2; }

# Fortschrittsbalken / Progress bar
STEP=0
TOTAL=5
progress() {
    STEP=$((STEP + 1))
    local pct=$(( STEP * 100 / TOTAL ))
    local filled=$(( pct / 5 ))
    local bar=""
    for ((i=0; i<20; i++)); do
        if (( i < filled )); then bar+="█"; else bar+="░"; fi
    done
    echo -e "\n${C_PURPLE}[${bar}] ${pct}%${C_RESET}  ${C_DIM}Schritt ${STEP}/${TOTAL} — $1${C_RESET}\n"
}

# Fragen überspringen im ISO-Modus / skip prompts in ISO mode
ask_continue() {
    if [[ $USE_ISO -eq 1 ]]; then return 0; fi
    read -rp "$(echo -e "${C_YELLOW}Fortfahren? / Continue? [Y/n]: ${C_RESET}")" go
    case "${go,,}" in n*) echo "Abgebrochen / aborted."; exit 0;; esac
}

# ─── ASCII-Art Titel / ASCII art banner ──────────────────────────────────────
banner() {
    clear
    echo -e "${C_PURPLE}"
    cat <<'EOF'
   _   _   _    ___  ____
  | |_(_) |_  / _ \/ ___|
  | __| | __|| | | \___ \
  | |_| | |_ | |_| |___) |
   \__|_|\__| \___/|____/
EOF
    echo -e "${C_CYAN}        titOS Installer${C_RESET}"
    echo -e "${C_DIM}   AI-Powered Gaming Linux — Arch based${C_RESET}\n"
}

# ─── Root-Check ───────────────────────────────────────────────────────────────
require_not_root() {
    if [[ $USE_ISO -eq 1 ]]; then
        ok "ISO-Modus: läuft im chroot als root. / ISO mode: running as root in chroot."
        return 0
    fi
    if [[ "${EUID}" -eq 0 ]]; then
        err "Bitte NICHT als root ausführen. / Do NOT run as root."
        err "Das Skript nutzt sudo wo nötig. / The script uses sudo where needed."
        exit 1
    fi
    if ! command -v sudo >/dev/null 2>&1; then
        err "sudo wird benötigt. / sudo is required."
        exit 1
    fi
}

# ─── Hardware-Erkennung / Hardware detection ──────────────────────────────────
GPU_VENDOR=""
detect_gpu() {
    info "Erkenne GPU... / Detecting GPU..."
    local lspci_out
    lspci_out="$(lspci 2>/dev/null | grep -Ei 'vga|3d|display' || true)"
    echo -e "${C_DIM}${lspci_out}${C_RESET}"
    if echo "$lspci_out" | grep -qi nvidia; then
        GPU_VENDOR="nvidia"
    elif echo "$lspci_out" | grep -Eqi 'amd|ati|radeon'; then
        GPU_VENDOR="amd"
    elif echo "$lspci_out" | grep -qi intel; then
        GPU_VENDOR="intel"
    fi

    if [[ -n "$GPU_VENDOR" ]]; then
        ok "Automatisch erkannt / Auto-detected: ${C_CYAN}${GPU_VENDOR^^}${C_RESET}"
        read -rp "$(echo -e "${C_YELLOW}Übernehmen? / Accept? [Y/n]: ${C_RESET}")" ans
        case "${ans,,}" in n*) GPU_VENDOR="";; esac
    fi

    while [[ -z "$GPU_VENDOR" ]]; do
        echo -e "GPU manuell wählen / choose manually:"
        echo "  1) AMD"
        echo "  2) NVIDIA"
        echo "  3) Intel"
        read -rp "Auswahl / choice [1-3]: " choice
        case "$choice" in
            1) GPU_VENDOR="amd";;
            2) GPU_VENDOR="nvidia";;
            3) GPU_VENDOR="intel";;
            *) warn "Ungültig / invalid";;
        esac
    done
    export GPU_VENDOR
    ok "GPU gesetzt / GPU set: ${GPU_VENDOR^^}"
}

# ─── Subscript-Runner ─────────────────────────────────────────────────────────
run_step() {
    local script="$1"
    local label="$2"
    progress "$label"
    if [[ ! -f "$TITOS_DIR/setup/$script" ]]; then
        err "Fehlt / missing: setup/$script"
        exit 1
    fi
    bash "$TITOS_DIR/setup/$script"
    ok "$label abgeschlossen / done"
}

# ─── Hauptablauf / Main flow ──────────────────────────────────────────────────
main() {
    require_not_root
    banner
    echo -e "Willkommen beim ${C_PURPLE}titOS${C_RESET} Installer!"
    echo -e "${C_DIM}Dieses Skript richtet ein Gaming-optimiertes Arch-Linux mit"
    echo -e "Hyprland, Gaming-Stack und lokalem KI-Agenten ein.${C_RESET}\n"
    echo -e "${C_DIM}This installs a gaming-optimised Arch Linux with Hyprland,"
    echo -e "a gaming stack and a local AI agent.${C_RESET}\n"

    ask_continue

    if [[ $USE_ISO -eq 1 ]]; then
        GPU_VENDOR="${TITOS_GPU:-}"
        if [[ -z "$GPU_VENDOR" ]]; then
            # chroot-GPU-Erkennung / chroot GPU detection
            local lspci_out
            lspci_out="$(lspci 2>/dev/null | grep -Ei 'vga|3d|display' || true)"
            if echo "$lspci_out" | grep -qi nvidia; then
                GPU_VENDOR="nvidia"
            elif echo "$lspci_out" | grep -Eqi 'amd|ati|radeon'; then
                GPU_VENDOR="amd"
            elif echo "$lspci_out" | grep -qi intel; then
                GPU_VENDOR="intel"
            else
                GPU_VENDOR="amd"   # sicherer Default / safe default
            fi
        fi
        export GPU_VENDOR
        ok "ISO-Modus: GPU ${GPU_VENDOR^^} (erkennbar nach erstem Boot korrigierbar / re-detect after first boot)"
        echo -e "${C_DIM}tipp / tip: nach dem ersten Boot 'titos-install' mit TITOS_GPU= überschreiben${C_RESET}"
    else
        detect_gpu
    fi

    run_step base.sh     "Basis-System / Base system"
    run_step gaming.sh   "Gaming-Stack"
    run_step ai-agent.sh "KI-Agent / AI agent (Ollama)"
    run_step desktop.sh  "Desktop (Hyprland) & Apps"
    run_step branding.sh "titOS Branding"

    echo -e "\n${C_GREEN}════════════════════════════════════════════${C_RESET}"
    ok "titOS wurde erfolgreich installiert! / installed successfully!"
    echo -e "${C_DIM}Tippe 'titos-help' für den KI-Assistenten. / Type 'titos-help' for the AI assistant.${C_RESET}"
    echo -e "${C_GREEN}════════════════════════════════════════════${C_RESET}\n"

    if [[ $USE_ISO -eq 1 ]]; then
        ok "titOS ISO-Installation fertig. / ISO installation done."
        echo -e "${C_DIM}Neustart bitte vom ISO-Installer auslösen. / Reboot is triggered by the ISO installer.${C_RESET}"
        return 0
    fi
    read -rp "$(echo -e "${C_YELLOW}Jetzt neustarten? / Reboot now? [y/N]: ${C_RESET}")" rb
    case "${rb,,}" in
        y*) info "Starte neu... / rebooting..."; sudo reboot;;
        *)  info "Starte später manuell neu. / Reboot later manually.";;
    esac
}

main "$@"
