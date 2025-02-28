#!/bin/bash

# Define the URL of your script
SCRIPT_URL="https://raw.githubusercontent.com/Jhon-mark23/Termux-beta/refs/heads/main/menu.sh"
SCRIPT_NAME="menu"
INSTALL_DIR="$HOME/dig_checker"
INSTALL_PATH="$INSTALL_DIR/$SCRIPT_NAME"

# Update package list and install required tools
echo "Updating Termux and installing required packages..."
pkg update -y && pkg upgrade -y
pkg install -y dnsutils curl coreutils

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Download the script and rename it
echo "Downloading $SCRIPT_NAME..."
curl -o "$INSTALL_PATH" "$SCRIPT_URL"

# Make it executable
chmod +x "$INSTALL_PATH"

# Create a shortcut command
if ! grep -q "alias menu=" "$HOME/.bashrc"; then
    echo "alias menu='$INSTALL_PATH'" >> "$HOME/.bashrc"
fi
source "$HOME/.bashrc"

echo "Installation complete!"
echo "Run the script using: menu"
