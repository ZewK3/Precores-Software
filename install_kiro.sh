#!/bin/bash
# Install Kiro AI IDE

set -e

KIRO_URL="https://prod.download.desktop.kiro.dev/releases/stable/linux-x64/signed/0.8.140/deb/kiro-ide-0.8.140-stable-linux-x64.deb"

echo "[INSTALL] Installing Dependencies..."
sudo apt update
sudo apt install -y curl

echo "[INSTALL] Downloading Kiro AI..."
curl -L -o kiro-ide.deb "$KIRO_URL"

echo "[INSTALL] Installing Kiro AI..."
sudo apt install -y ./kiro-ide.deb

echo "[INSTALL] Cleaning up..."
rm -f kiro-ide.deb

echo "[SUCCESS] Kiro AI installed successfully."
