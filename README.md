# titOS

**AI-Powered Gaming Linux** — ein Arch-Linux-basiertes Desktop-Setup (Skripte + Dotfiles, kein eigenes ISO), inspiriert von [Omarchy](https://omarchy.org), mit Hyprland, vollem Gaming-Stack und einem lokalen KI-Assistenten.

*An Arch Linux based desktop setup (scripts + dotfiles, not a separate ISO), inspired by Omarchy, with Hyprland, a full gaming stack and a local AI assistant.*

---

## 🇩🇪 Deutsch

### Was ist titOS?
titOS verwandelt eine frische Arch-Linux-Installation in ein poliertes, Gaming-optimiertes System mit:
- **Hyprland** (Wayland Tiling Window Manager) + Waybar, Wofi, Dunst, Kitty, Thunar
- **Gaming-Stack**: linux-zen Kernel, Steam + Proton-GE, GameMode, MangoHud, Wine/DXVK/VKD3D, Lutris, Heroic, Gamepad-Support
- **Lokaler KI-Agent** (Ollama) — läuft offline, diagnostiziert Systemprobleme per `titos-help`
- **titOS-Branding**: animierter Plymouth-Boot-Splash, GRUB-Theme, animierter Terminal-Begrüßungsscreen

### Installation
> ⚠️ Voraussetzung: eine funktionierende Arch-Linux-Basis-Installation. Nicht als root ausführen.

```bash
git clone <repo-url> titos
cd titos
chmod +x install.sh
./install.sh
```
Der Installer erkennt deine GPU (AMD/NVIDIA/Intel) automatisch, zeigt einen Fortschrittsbalken, installiert alle Komponenten und bietet am Ende einen Neustart an.

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
titOS turns a fresh Arch Linux install into a polished, gaming-optimised system with Hyprland, a full gaming stack, a local AI assistant (Ollama) and custom titOS branding (animated Plymouth boot splash, GRUB theme, animated terminal welcome screen).

### Installation
> ⚠️ Requires a working Arch Linux base install. Do **not** run as root.
```bash
git clone <repo-url> titos
cd titos
chmod +x install.sh
./install.sh
```
The installer auto-detects your GPU, shows a progress bar, installs everything and offers a reboot at the end.

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
└── README.md
```

## Lizenz / License
MIT — frei nutzbar und anpassbar. / Free to use and modify.
