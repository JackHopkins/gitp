#!/bin/bash

# Function to check and install a package
check_and_install() {
    package=$1
    if ! command -v "$package" &> /dev/null; then
        echo "$package is not installed. Installing $package..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y "$package"
        elif command -v yum &> /dev/null; then
            sudo yum install -y "$package"
        elif command -v brew &> /dev/null; then
            brew install "$package"
        else
            echo "Error: Package manager not supported. Please install $package manually."
            exit 1
        fi
    fi
}

# Check if the required dependencies are installed and install them if necessary
check_and_install git
check_and_install ctags
check_and_install readtags

# Check if uctag.sh exists in the current directory
if [ ! -f "./uctags.sh" ]; then
    echo "Error: uctags.sh not found in the current directory. Please make sure it exists."
    exit 1
fi

# Create the user's local bin directory if it doesn't exist
if [ ! -d "$HOME/.local/bin" ]; then
    mkdir -p "$HOME/.local/bin"
fi

# Install the uctag script to the user's local bin directory
echo "Installing uctag.sh at the user level..."
cp ./uctags.sh "$HOME/.local/bin/uctags.sh"
chmod +x "$HOME/.local/bin/uctags.sh"

echo "Installation complete! uctags.sh has been installed to ~/.local/bin/"