#!/bin/bash
# Install Google Chrome

set -e

echo "[INSTALL] Installing Dependencies..."
sudo apt update
sudo apt install -y wget

echo "[INSTALL] Downloading Google Chrome..."
wget -O google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

echo "[INSTALL] Installing Google Chrome..."
sudo apt install -y ./google-chrome-stable_current_amd64.deb

echo "[INSTALL] Cleaning up..."
rm -f google-chrome-stable_current_amd64.deb

echo "[SUCCESS] Google Chrome installed successfully."
