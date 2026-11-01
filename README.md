# titOS

**AI-Powered Gaming Linux** — ein Arch-Linux-basiertes Desktop-Setup (Skripte + Dotfiles) mit eigenem **ISO-Builder**, inspiriert von [Omarchy](https://omarchy.org), mit Hyprland, vollem Gaming-Stack und einem lokalen KI-Assistenten.

*An Arch Linux based desktop setup (scripts + dotfiles) with its own ISO builder, inspired by Omarchy, with Hyprland, a full gaming stack and a local AI assistant.*

---

## 🇩🇪 Deutsch

### Was ist titOS?
titOS verwandelt jede x86-64-Maschine (AMD oder Intel, alt oder neu) in ein poliertes, Gaming-optimiertes System mit:
- **Hyprland** (Wayland Tiling Window Manager) + Waybar, Wofi, Dunst, Kitty, Thunar
- **Gaming-Stack**: linux-zen Kernel, Steam + Proton-GE, GameMode, MangoHud, Wine/DXVK/VKD3D, Lutris, Heroic, Gamepad-Support
- **Lokaler KI-Agent** (Ollama) — läuft offline, diagnostiziert Systemprobleme per `titos-help`
- **titOS-Branding**: animierter Plymouth-Boot-Splash, GRUB-Theme, animierter Terminal-Begrüßungsscreen
- **Bootbare ISO** (`iso/`) — komplettes Live-System mit eigenem Installer, kein fertig installiertes Arch nötig

### ISO bauen / installieren

#### Voraussetzung
Ein Arch-Linux-Build-Host mit `archiso`:

```bash
sudo pacman -S --needed archiso
```

#### Bauen
```bash
cd iso
sudo OUT="$PWD/out" ./bin/titos-iso-make
# Ergebnis: iso/out/*.iso + *.iso.sha256
```

#### Installieren per USB-Stick
1. ISO auf USB-Stick schreiben (z. B. [balenaEtcher](https://etcher.balena.io/), `dd` oder [caligula](https://github.com/ifd3f/caligula))
2. Booten — die Live-Umgebung loggt sich automatisch als `titos` ein
3. Netzwerk verbinden (Ethernet per DHCP automatisch, WLAN per `nmtui`)
4. `titos-install` ausführen — fragt Zielplatte, Benutzername und Passwort ab, partitiert (BIOS + UEFI), installiert Arch + linux-zen, baut yay, legt den Benutzer an und führt anschließend den kompletten titOS-Installer (`install.sh --iso`) aus. Danach GRUB + Reboot.

#### CPU-Support
Die ISO basiert auf dem **x86-64-Baseline**-Paketset von Arch Linux und bootet damit auf **allen x86-64-CPUs**:
- AMD & Intel, alt und neu (x86-64-v1 Baseline — keine v2/v3-Voraussetzung)
- Microcode für Intel (`intel-ucode`) und AMD (`amd-ucode`) ist enthalten
- BIOS- und UEFI-Boot werden beide unterstützt (syslinux + systemd-boot)
- GPU-Treiber wählt der Installer automatisch (AMD / NVIDIA / Intel)

> Eine ARM64/aarch64-ISO ist bewusst nicht enthalten: der titOS-Gaming-Stack (Steam, Proton, DXVK) ist x86-only. Ein ARM-Derivat ohne Gaming-Stack wäre ein separates Projekt.

### Installation auf bestehendem Arch (ohne ISO)
> ⚠️ Voraussetzung: eine funktionierende Arch-Linux-Basis-Installation. Nicht als root ausführen.

```bash
git clone https://github.com/TitoPrausee/titos.git titos
cd titos
chmod +x install.sh
./install.sh
```
Der Installer erkennt deine GPU (AMD/NVIDIA/Intel) automatisch, zeigt einen Fortschrittsbalken, installiert alle Komponenten und bietet am Ende einen Neustart an.
Für automatisierte Installationen (z. B. aus dem ISO-Installer heraus): `./install.sh --iso` (überspringt alle Rückfragen, GPU via `TITOS_GPU=amd|nvidia|intel`).

### Gaming-Features
| Komponente | Zweck |
|-----------|-------|
| linux-zen | Low-Latency Gaming-Kernel |
| Steam + Proton-GE | Windows-Spiele, bessere EAC-Kompatibilität |
| GameMode | Automatischer CPU/GPU-Boost beim Spielen |
| MangoHud | Performance-Overlay (FPS, Temps) |
| Wine + DXVK + VKD3D | DirectX-Spiele ohne Steam |
| xpadneo | Xbox-Controller (Bluetooth) |
| Vulkan-Treiber | AMD / NVIDIA / Intel |

### KI-Agent nutzen
```bash
titos-help                         # Fragt interaktiv nach deinem Problem
titos-help "Mein Steam startet nicht"
titos-help --game "Forza Horizon 5"   # Spielspezifische Hilfe
titos-ai                           # Alias für titos-help
```
Der Agent sammelt automatisch fehlgeschlagene Dienste, Fehler-Logs und Hardware-Infos und schickt sie an das lokale Ollama-LLM (Standard: `llama3.2`, Fallback `mistral`). **Keine Internetverbindung nötig.**
Beim Shell-Start weist titOS automatisch auf `titos-help` hin, wenn fehlgeschlagene Dienste erkannt werden.

### Anpassung
- Dotfiles liegen in `dotfiles/` und werden nach `~/.config/` verlinkt — Änderungen am Repo wirken sofort.
- Hyprland: `dotfiles/hyprland/hyprland.conf`
- Waybar: `dotfiles/waybar/config` + `style.css`
- KI-Modell wechseln: `export TITOS_MODEL=mistral` vor `titos-help`.
- System aktualisieren: `titos-update`

---

## 🇬🇧 English

### What is titOS?
titOS turns any x86-64 machine (AMD or Intel, old or new) into a polished, gaming-optimised system with Hyprland, a full gaming stack, a local AI assistant (Ollama) and custom titOS branding (animated Plymouth boot splash, GRUB theme, animated terminal welcome screen). The `iso/` directory additionally builds a bootable live ISO with a self-contained installer.

### ISO build / install
Requires an Arch Linux build host with `archiso` (`sudo pacman -S --needed archiso`):
```bash
cd iso
sudo OUT="$PWD/out" ./bin/titos-iso-make
# Result: iso/out/*.iso + *.iso.sha256
```
Write the ISO to a USB stick, boot it (auto-login as `titos`), connect the network (`nmtui` for WLAN), run `titos-install`. It asks for target disk, username and password, partitions (BIOS + UEFI), installs Arch + linux-zen, builds yay, creates your user and runs the full titOS setup inside, then GRUB + reboot.

**CPU support:** The ISO uses Arch's x86-64 baseline package set — it boots on *all* x86-64 CPUs (AMD + Intel, old and new), ships both microcode packages, and supports BIOS as well as UEFI boot. GPU drivers are auto-selected by the installer (AMD/NVIDIA/Intel).

> No aarch64/ARM ISO by design: the gaming stack (Steam, Proton, DXVK) is x86-only. An ARM derivative without the gaming stack would be a separate project.

### Installation on existing Arch (no ISO)
> ⚠️ Requires a working Arch Linux base install. Do **not** run as root.
```bash
git clone https://github.com/TitoPrausee/titos.git titos
cd titos
chmod +x install.sh
./install.sh
```
The installer auto-detects your GPU, shows a progress bar, installs everything and offers a reboot at the end.
For automated installs (e.g. from the ISO installer): `./install.sh --iso` (skips all prompts, GPU via `TITOS_GPU=amd|nvidia|intel`).

### Gaming features
linux-zen kernel, Steam + Proton-GE, GameMode, MangoHud, Wine/DXVK/VKD3D, Lutris, Heroic, xpadneo gamepad support, Vulkan drivers (AMD/NVIDIA/Intel).

### Using the AI agent
```bash
titos-help                      # asks for your problem interactively
titos-help "Steam won't launch"
titos-help --game "Forza Horizon 5"
```
It collects failed services, error logs and hardware info and sends them to the local Ollama LLM (default `llama3.2`, fallback `mistral`). **No internet required.**

### Customisation
Dotfiles live in `dotfiles/` and are symlinked to `~/.config/`. Run `titos-update` to update the system, Proton-GE and the Ollama model.

---

## Projektstruktur / Project structure
```
titos/
├── install.sh              # Haupt-Installer / main installer
├── setup/                  # base, gaming, ai-agent, desktop, branding
├── dotfiles/               # hyprland, waybar, kitty, nvim
├── plymouth/titos/         # animierter Boot-Splash / animated boot splash
├── grub/titos-grub-theme/  # GRUB-Theme
├── scripts/                # titos-splash, titos-help, titos-update
├── iso/                    # ISO-Builder (archiso-Profil + Live-Installer)
│   ├── bin/titos-iso-make  # Build-Skript (root + archiso nötig)
│   ├── install/            # run.sh (Partitionierung/pacstrap) + chroot-Stages
│   ├── airootfs/           # Live-System-Overlay (Autologin, Boot-Hinweis)
│   └── packages.x86_64     # Paketliste der Live-Umgebung
└── README.md
```

## Lizenz / License
MIT — frei nutzbar und anpassbar. / Free to use and modify.