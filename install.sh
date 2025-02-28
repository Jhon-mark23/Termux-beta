#!/bin/bash

# Define the script URL and installation path
SCRIPT_URL="https://raw.githubusercontent.com/Jhon-mark23/Termux-beta/main/menu.sh"
SCRIPT_NAME="menu.sh"
INSTALL_DIR="$HOME/dig_checker"
INSTALL_PATH="$INSTALL_DIR/$SCRIPT_NAME"

# Update package list and install required tools
echo "Updating Termux and installing required packages..."
pkg update -y && pkg upgrade -y
pkg install -y dnsutils curl coreutils bc

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Download the script
echo "Downloading $SCRIPT_NAME..."
curl -o "$INSTALL_PATH" "$SCRIPT_URL"

# Make it executable
chmod +x "$INSTALL_PATH"

# Ensure ~/bin exists and add it to PATH if missing
mkdir -p "$HOME/bin"
ln -sf "$INSTALL_PATH" "$HOME/bin/menu"

if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
fi
source "$HOME/.bashrc"

echo "Installation complete!"
echo "Run the script using: menu"
