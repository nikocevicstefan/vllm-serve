#!/bin/bash

# Script to install vllm-serve
# This script will download the vllm-serve script and place it in a location of the user's choice

# Force bash if available
if [ -z "$BASH_VERSION" ]; then
  if command -v bash >/dev/null 2>&1; then
    exec bash "$0" "$@"
  else
    echo "Warning: This script is designed for bash. Some features may not work in other shells."
  fi
fi

echo "vLLM Serve Installer"
echo

# Default installation locations
USER_INSTALL_DIR="$HOME/.local/bin"
GLOBAL_INSTALL_DIR="/usr/local/bin"

# Detect active Python environment
PYTHON_CMD=""
if command -v python3 > /dev/null 2>&1; then
    PYTHON_CMD="python3"
elif command -v python > /dev/null 2>&1; then
    PYTHON_CMD="python"
fi

PYTHON_ENV_BIN=""
IN_VIRTUAL_ENV=false

# First check for explicit conda environment
if [ -n "$CONDA_PREFIX" ]; then
    CONDA_ENV_NAME=$(basename "$CONDA_PREFIX")
    # If not in base environment, consider it a valid conda env
    if [ "$CONDA_ENV_NAME" != "miniconda3" ] && [ "$CONDA_ENV_NAME" != "anaconda3" ] && [ "$CONDA_ENV_NAME" != "base" ]; then
        PYTHON_ENV_BIN="$CONDA_PREFIX/bin"
        IN_VIRTUAL_ENV=true
    fi
# Then check for standard virtual environment
elif [ -n "$VIRTUAL_ENV" ]; then
    PYTHON_ENV_BIN="$VIRTUAL_ENV/bin"
    IN_VIRTUAL_ENV=true
# Finally check if Python reports being in a virtual environment
elif [ -n "$PYTHON_CMD" ]; then
    # Check if Python reports being in a virtual environment
    IN_VENV=$($PYTHON_CMD -c "import sys; print(hasattr(sys, 'real_prefix') or (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix))" 2>/dev/null)
    if [ "$IN_VENV" = "True" ]; then
        # Get the directory where Python executables are installed
        PYTHON_ENV_BIN=$($PYTHON_CMD -c "import sys, os; print(os.path.dirname(sys.executable))")
        IN_VIRTUAL_ENV=true
    fi
fi

# Try to detect vLLM with Python (more reliable across different environments)
VLLM_FOUND=false

# Try with python3 first (most common on modern systems)
if command -v python3 > /dev/null 2>&1; then
    if python3 -c "import importlib.util; print(importlib.util.find_spec('vllm') is not None)" 2>/dev/null | grep -q "True"; then
        VLLM_FOUND=true
    fi
fi

# If not found, try with python (might be Python 3 on some systems)
if [ "$VLLM_FOUND" = false ] && command -v python > /dev/null 2>&1; then
    if python -c "import importlib.util; print(importlib.util.find_spec('vllm') is not None)" 2>/dev/null | grep -q "True"; then
        VLLM_FOUND=true
    fi
fi

# Also check for vllm command in PATH as a fallback
if [ "$VLLM_FOUND" = false ] && command -v vllm > /dev/null 2>&1; then
    VLLM_FOUND=true
fi

if [ "$VLLM_FOUND" = false ]; then
    echo "Warning: vLLM doesn't seem to be installed or is not accessible in this environment."
    echo "This script requires vLLM to be installed to function properly."
    echo "If you're using a conda/virtual environment, make sure it's activated before running this script."
    read -p "Do you want to continue anyway? [y/N]: " continue_anyway
    if [ "$continue_anyway" = "y" ] || [ "$continue_anyway" = "Y" ]; then
        # Continue with installation
        :
    else
        echo "Installation aborted."
        exit 1
    fi
else
    echo "vLLM installation detected."
fi

# Ask for installation type
echo "Installation options:"

# If we detected a Python/conda environment, offer it as first option
if [ "$IN_VIRTUAL_ENV" = true ] && [ -n "$PYTHON_ENV_BIN" ]; then
    if [ -n "$CONDA_PREFIX" ]; then
        CONDA_ENV_NAME=$(basename "$CONDA_PREFIX")
        echo "  1) Current conda environment ($CONDA_ENV_NAME) - Recommended"
        echo "     - Installs to $PYTHON_ENV_BIN"
        echo "     - Only available in this conda environment"
        echo "  2) User installation"
    elif [ -n "$VIRTUAL_ENV" ]; then
        VENV_NAME=$(basename "$VIRTUAL_ENV")
        echo "  1) Current virtual environment ($VENV_NAME) - Recommended"
        echo "     - Installs to $PYTHON_ENV_BIN"
        echo "     - Only available in this virtual environment"
        echo "  2) User installation"
    else
        echo "  1) Current Python virtual environment - Recommended"
        echo "     - Installs to $PYTHON_ENV_BIN"
        echo "     - Available in current virtual environment only"
        echo "  2) User installation"
    fi
    echo "     - Installs to $USER_INSTALL_DIR"
    echo "     - Available to your user account in all environments"
    echo "  3) Global installation (requires sudo privileges)"
    echo "     - Installs to $GLOBAL_INSTALL_DIR"
    echo "     - Available to all users on this system"
    echo "  4) Custom location"
else
    echo "  1) User installation (recommended for most users)"
    echo "     - Installs to $USER_INSTALL_DIR"
    echo "     - Only available to your user account"
    echo "  2) Global installation (requires sudo privileges)"
    echo "     - Installs to $GLOBAL_INSTALL_DIR"
    echo "     - Available to all users on this system"
    echo "  3) Custom location"
fi

read -p "Choose installation type [1]: " install_type
install_type=${install_type:-1}

# Handle the case where Python environment is detected
if [ "$IN_VIRTUAL_ENV" = true ] && [ -n "$PYTHON_ENV_BIN" ]; then
    case $install_type in
        1)
            INSTALL_DIR="$PYTHON_ENV_BIN"
            # Check if we have write permissions to the Python env directory
            if [ -w "$PYTHON_ENV_BIN" ]; then
                NEEDS_SUDO=false
            else
                NEEDS_SUDO=true
                # Check if user has sudo privileges
                if ! sudo -v > /dev/null 2>&1; then
                    echo "Error: You need sudo privileges to install to $PYTHON_ENV_BIN"
                    echo "Please run this script with sudo or choose a different installation option."
                    exit 1
                fi
            fi
            ;;
        2)
            INSTALL_DIR="$USER_INSTALL_DIR"
            NEEDS_SUDO=false
            ;;
        3)
            INSTALL_DIR="$GLOBAL_INSTALL_DIR"
            NEEDS_SUDO=true
            # Check if user has sudo privileges
            if ! sudo -v > /dev/null 2>&1; then
                echo "Error: You need sudo privileges for global installation."
                echo "Please run this script with sudo or choose a different installation option."
                exit 1
            fi
            ;;
        4)
            read -p "Enter custom installation directory: " INSTALL_DIR
            if [ "${INSTALL_DIR#/usr/}" != "$INSTALL_DIR" ] || [ "${INSTALL_DIR#/opt/}" != "$INSTALL_DIR" ]; then
                echo "This location may require sudo privileges."
                NEEDS_SUDO=true
                # Check if user has sudo privileges
                if ! sudo -v > /dev/null 2>&1; then
                    echo "Error: You need sudo privileges for this location."
                    echo "Please run this script with sudo or choose a different installation directory."
                    exit 1
                fi
            else
                NEEDS_SUDO=false
            fi
            ;;
        *)
            echo "Invalid choice. Using Python environment installation."
            INSTALL_DIR="$PYTHON_ENV_BIN"
            # Check if we have write permissions to the Python env directory
            if [ -w "$PYTHON_ENV_BIN" ]; then
                NEEDS_SUDO=false
            else
                NEEDS_SUDO=true
                # Check if user has sudo privileges
                if ! sudo -v > /dev/null 2>&1; then
                    echo "Error: You need sudo privileges to install to $PYTHON_ENV_BIN"
                    exit 1
                fi
            fi
            ;;
    esac
else
    # Standard options when no Python environment is detected
    case $install_type in
        1)
            INSTALL_DIR="$USER_INSTALL_DIR"
            NEEDS_SUDO=false
            ;;
        2)
            INSTALL_DIR="$GLOBAL_INSTALL_DIR"
            NEEDS_SUDO=true
            # Check if user has sudo privileges
            if ! sudo -v > /dev/null 2>&1; then
                echo "Error: You need sudo privileges for global installation."
                echo "Please run this script with sudo or choose a different installation option."
                exit 1
            fi
            ;;
        3)
            read -p "Enter custom installation directory: " INSTALL_DIR
            if [ "${INSTALL_DIR#/usr/}" != "$INSTALL_DIR" ] || [ "${INSTALL_DIR#/opt/}" != "$INSTALL_DIR" ]; then
                echo "This location may require sudo privileges."
                NEEDS_SUDO=true
                # Check if user has sudo privileges
                if ! sudo -v > /dev/null 2>&1; then
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
fi

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
if command -v curl > /dev/null 2>&1; then
    curl -s -o "$TMP_FILE" "$SCRIPT_URL"
elif command -v wget > /dev/null 2>&1; then
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
if [ "$install_type" = "1" ] && [ "$IN_VIRTUAL_ENV" = false ] || [ "$install_type" = "3" ] && [ "$NEEDS_SUDO" = false ]; then
    # Use case statement to check if path contains install dir
    case ":$PATH:" in
        *":$INSTALL_DIR:"*) 
            PATH_CONTAINS_INSTALL_DIR=true 
            ;;
        *) 
            PATH_CONTAINS_INSTALL_DIR=false 
            ;;
    esac
    
    if [ "$PATH_CONTAINS_INSTALL_DIR" = false ]; then
        echo
        echo "The installation directory is not in your PATH."
        echo "You might want to add the following line to your ~/.bashrc or ~/.zshrc:"
        echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
        
        # Ask if the user wants to add it to their PATH
        read -p "Do you want to add it to your PATH now? [y/N]: " add_to_path
        if [ "$add_to_path" = "y" ] || [ "$add_to_path" = "Y" ]; then
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

# Use case statement to check if path contains install dir
case ":$PATH:" in
    *":$INSTALL_DIR:"*) 
        PATH_CONTAINS_INSTALL_DIR=true 
        ;;
    *) 
        PATH_CONTAINS_INSTALL_DIR=false 
        ;;
esac

if [ "$install_type" = "2" ] || [ "$PATH_CONTAINS_INSTALL_DIR" = true ] || [ "$IN_VIRTUAL_ENV" = true ] && [ "$install_type" = "1" ]; then
    echo "  vllm-serve"
else
    echo "  $INSTALL_DIR/vllm-serve"
    echo 
    echo "To make it globally available immediately for this session, run:"
    echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
fi

exit 0 