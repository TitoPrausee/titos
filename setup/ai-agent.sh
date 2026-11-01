#!/usr/bin/env bash
# ai-agent.sh — Lokaler KI-Agent mit Ollama / Local AI agent with Ollama
set -euo pipefail
TITOS_DIR="${TITOS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

echo ":: Installiere Ollama / Installing Ollama..."
if ! command -v ollama >/dev/null 2>&1; then
    yay -S --needed --noconfirm ollama 2>/dev/null || sudo pacman -S --needed --noconfirm ollama
fi

echo ":: Aktiviere Ollama-Service / Enabling Ollama service..."
sudo systemctl enable --now ollama.service || true
sleep 3

echo ":: Lade Standard-Modell / Pulling default model (llama3.2)..."
if ! ollama pull llama3.2; then
    echo "! llama3.2 fehlgeschlagen, versuche mistral / falling back to mistral"
    ollama pull mistral || echo "! Modell-Download fehlgeschlagen / model pull failed"
fi

echo ":: Installiere titos-help / titos-ai nach /usr/local/bin ..."
sudo install -m 755 "$TITOS_DIR/scripts/titos-help" /usr/local/bin/titos-help
sudo ln -sf /usr/local/bin/titos-help /usr/local/bin/titos-ai

echo "✔ KI-Agent fertig / AI agent done"
