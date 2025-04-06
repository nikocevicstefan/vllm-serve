#!/bin/bash

# Script to install vllm-serve
# This script will download the vllm-serve script and place it in a location of the user's choice

echo "vLLM Serve Installer"
echo

# Default installation locations
USER_INSTALL_DIR="$HOME/.local/bin"
GLOBAL_INSTALL_DIR="/usr/local/bin"

# Check if vLLM is installed
if ! command -v vllm &> /dev/null; then
    echo "Warning: vLLM doesn't seem to be installed or is not in your PATH."
    echo "This script requires vLLM to be installed to function properly."
    read -p "Do you want to continue anyway? [y/N]: " continue_anyway
    if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
        echo "Installation aborted."
        exit 1
    fi
fi

# Ask for installation type
echo "Installation options:"
echo "  1) User installation (recommended for most users)"
echo "     - Installs to $USER_INSTALL_DIR"
echo "     - Only available to your user account"
echo "  2) Global installation (requires sudo privileges)"
echo "     - Installs to $GLOBAL_INSTALL_DIR"
echo "     - Available to all users on this system"
echo "  3) Custom location"
read -p "Choose installation type [1]: " install_type
install_type=${install_type:-1}

case $install_type in
    1)
        INSTALL_DIR="$USER_INSTALL_DIR"
        NEEDS_SUDO=false
        ;;
    2)
        INSTALL_DIR="$GLOBAL_INSTALL_DIR"
        NEEDS_SUDO=true
        # Check if user has sudo privileges
        if ! sudo -v &> /dev/null; then
            echo "Error: You need sudo privileges for global installation."
            echo "Please run this script with sudo or choose a different installation option."
            exit 1
        fi
        ;;
    3)
        read -p "Enter custom installation directory: " INSTALL_DIR
        if [[ "$INSTALL_DIR" == "/usr/"* ]] || [[ "$INSTALL_DIR" == "/opt/"* ]]; then
            echo "This location may require sudo privileges."
            NEEDS_SUDO=true
            # Check if user has sudo privileges
            if ! sudo -v &> /dev/null; then
                echo "Error: You need sudo privileges for this location."
                echo "Please run this script with sudo or choose a different installation directory."
                exit 1
            fi
        else
            NEEDS_SUDO=false
        fi
        ;;
    *)
        echo "Invalid choice. Using user installation."
        INSTALL_DIR="$USER_INSTALL_DIR"
        NEEDS_SUDO=false
        ;;
esac

# Create directory if it doesn't exist
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Directory $INSTALL_DIR does not exist. Creating it..."
    if [ "$NEEDS_SUDO" = true ]; then
        sudo mkdir -p "$INSTALL_DIR"
    else
        mkdir -p "$INSTALL_DIR"
    fi
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create directory $INSTALL_DIR"
        exit 1
    fi
fi

# Download the script
SCRIPT_URL="https://raw.githubusercontent.com/nikocevicstefan/vllm-serve/main/vllm-serve.sh"
echo "Downloading vllm-serve from $SCRIPT_URL..."

# Prepare a temporary file
TMP_FILE=$(mktemp)

# Download to the temporary file first
if command -v curl &> /dev/null; then
    curl -s -o "$TMP_FILE" "$SCRIPT_URL"
elif command -v wget &> /dev/null; then
    wget -q -O "$TMP_FILE" "$SCRIPT_URL"
else
    echo "Error: Neither curl nor wget is installed. Cannot download the script."
    exit 1
fi

if [ $? -ne 0 ]; then
    echo "Error: Failed to download the script."
    rm -f "$TMP_FILE"
    exit 1
fi

# Move to final location
if [ "$NEEDS_SUDO" = true ]; then
    sudo mv "$TMP_FILE" "$INSTALL_DIR/vllm-serve"
    sudo chmod +x "$INSTALL_DIR/vllm-serve"
else
    mv "$TMP_FILE" "$INSTALL_DIR/vllm-serve"
    chmod +x "$INSTALL_DIR/vllm-serve"
fi

if [ $? -ne 0 ]; then
    echo "Error: Failed to install the script."
    exit 1
fi

# Check if the directory is in PATH (only for user installation)
if [ "$install_type" = "1" ] || [ "$install_type" = "3" ] && [ "$NEEDS_SUDO" = false ]; then
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        echo
        echo "The installation directory is not in your PATH."
        echo "You might want to add the following line to your ~/.bashrc or ~/.zshrc:"
        echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
        
        # Ask if the user wants to add it to their PATH
        read -p "Do you want to add it to your PATH now? [y/N]: " add_to_path
        if [[ "$add_to_path" =~ ^[Yy]$ ]]; then
            # Determine which shell config file to use
            SHELL_CONFIG=""
            if [ -f "$HOME/.bashrc" ]; then
                SHELL_CONFIG="$HOME/.bashrc"
            elif [ -f "$HOME/.zshrc" ]; then
                SHELL_CONFIG="$HOME/.zshrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                SHELL_CONFIG="$HOME/.bash_profile"
            elif [ -f "$HOME/.profile" ]; then
                SHELL_CONFIG="$HOME/.profile"
            else
                echo "Could not determine your shell configuration file. Please add the directory to your PATH manually."
            fi
            
            if [ -n "$SHELL_CONFIG" ]; then
                echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_CONFIG"
                echo "Added to $SHELL_CONFIG. The change will take effect in new terminal sessions."
                echo "To use it in the current session, run: export PATH=\"\$PATH:$INSTALL_DIR\""
            fi
        fi
    fi
fi

echo
echo "Installation complete! You can now use vllm-serve by running:"

if [ "$install_type" = "2" ] || [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
    echo "  vllm-serve"
else
    echo "  $INSTALL_DIR/vllm-serve"
    echo 
    echo "To make it globally available immediately for this session, run:"
    echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
fi

exit 0 