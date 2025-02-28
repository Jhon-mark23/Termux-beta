#!/bin/bash

# Define script variables
SCRIPT_URL="https://raw.githubusercontent.com/Jhon-mark23/Termux-beta/refs/heads/Test/Base64.sh"
SCRIPT_NAME="menu.sh"
INSTALL_DIR="$HOME/dig_checker"
INSTALL_PATH="$INSTALL_DIR/$SCRIPT_NAME"
BIN_PATH="/data/data/com.termux/files/usr/bin/menu"

# Color variables
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
NC="\e[0m"

# Function to print a title
print_title() {
    echo -e "${YELLOW}==================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${YELLOW}==================================${NC}"
}

# Function to show steps with error handling
show_step() {
    echo -e "${GREEN}[✔]${NC} $1"
}

show_error() {
    echo -e "${RED}[✖] Error: $1${NC}"
    exit 1
}

clear
print_title "Termux Script Auto-Installer"

echo -e "${YELLOW}Starting installation...${NC}"
sleep 1

# Step 1: Update package list
show_step "Updating package list..."
pkg update -y > /dev/null 2>&1 || show_error "Failed to update package list."

# Step 2: Install required dependencies
show_step "Installing required packages..."
pkg install -y dnsutils curl coreutils bc > /dev/null 2>&1 || show_error "Failed to install required packages."

# Step 3: Create installation directory
show_step "Creating installation directory..."
mkdir -p "$INSTALL_DIR" || show_error "Failed to create installation directory."

# Step 4: Download and decode Base64 script
show_step "Downloading and decoding script..."
BASE64_DATA=$(curl -s "$SCRIPT_URL")
if [[ -z "$BASE64_DATA" ]]; then
    show_error "Failed to download the script. Check the URL."
fi
echo "$BASE64_DATA" | base64 -d > "$INSTALL_PATH" || show_error "Failed to decode Base64 script."

# Step 5: Set script permissions
show_step "Setting up executable permissions..."
chmod +x "$INSTALL_PATH" || show_error "Failed to set execute permissions for script."

# Step 6: Move script to bin path
show_step "Placing script in /usr/bin/..."
mv -f "$INSTALL_PATH" "$BIN_PATH" || show_error "Failed to move script to /usr/bin."
chmod +x "$BIN_PATH" || show_error "Failed to set execute permissions for menu."

# Final Message
print_title "Installation Complete!"
echo -e "Run the script using: ${GREEN}menu${NC}"
