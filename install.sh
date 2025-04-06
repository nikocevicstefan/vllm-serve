#!/bin/bash

# Script to install vllm-serve.sh
# This script will download the vllm-serve.sh script and place it in a location of the user's choice

echo "vLLM Serve Installer"
echo

# Default installation location
DEFAULT_INSTALL_DIR="$HOME/.local/bin"

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

# Ask for installation directory
read -p "Where do you want to install vllm-serve.sh? [$DEFAULT_INSTALL_DIR]: " INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}

# Create directory if it doesn't exist
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Directory $INSTALL_DIR does not exist. Creating it..."
    mkdir -p "$INSTALL_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create directory $INSTALL_DIR"
        exit 1
    fi
fi

# Download the script
SCRIPT_URL="https://raw.githubusercontent.com/nikocevicstefan/vllm-serve/main/vllm-serve.sh"
echo "Downloading vllm-serve.sh from $SCRIPT_URL..."

if command -v curl &> /dev/null; then
    curl -o "$INSTALL_DIR/vllm-serve" "$SCRIPT_URL"
elif command -v wget &> /dev/null; then
    wget -O "$INSTALL_DIR/vllm-serve" "$SCRIPT_URL"
else
    echo "Error: Neither curl nor wget is installed. Cannot download the script."
    exit 1
fi

if [ $? -ne 0 ]; then
    echo "Error: Failed to download the script."
    exit 1
fi

# Make it executable
chmod +x "$INSTALL_DIR/vllm-serve"
if [ $? -ne 0 ]; then
    echo "Error: Failed to make the script executable."
    exit 1
fi

# Check if the directory is in PATH
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

echo
echo "Installation complete! You can now use vllm-serve by running:"
if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
    echo "  vllm-serve"
else
    echo "  $INSTALL_DIR/vllm-serve"
fi

exit 0 