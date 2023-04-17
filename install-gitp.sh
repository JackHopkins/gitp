#!/bin/bash

# Save this file as 'install-gitp.sh' and make it executable (chmod +x install-gitp.sh)

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
check_and_install jq
check_and_install git
check_and_install curl
check_and_install awk
check_and_install sed

# Check if gitp.sh exists in the current directory
if [ ! -f "./gitp.sh" ]; then
    echo "Error: gitp.sh not found in the current directory. Please make sure it exists."
    exit 1
fi

# Install the gitp script to /usr/local/bin
echo "Installing gitp..."
sudo cp ./gitp.sh /usr/local/bin/gitp
sudo chmod +x /usr/local/bin/gitp

# Prompt the user for GPT4_API_KEY if it's not already set
if [ -z "${GPT4_API_KEY}" ]; then
    read -p "Enter your GPT-4 API key: " GPT4_API_KEY
    if [ "$(uname)" == "Darwin" ]; then
        if [ "$SHELL" == "/bin/zsh" ]; then
            echo "export GPT4_API_KEY=${GPT4_API_KEY}" >> ~/.zshrc
            source ~/.zshrc
        else
            echo "export GPT4_API_KEY=${GPT4_API_KEY}" >> ~/.bash_profile
            source ~/.bash_profile
        fi
    else
        echo "export GPT4_API_KEY=${GPT4_API_KEY}" >> ~/.bashrc
        source ~/.bashrc
    fi
fi

# Create an alias for the git command
echo "Creating an alias for the git command to call gitp instead..."
if [ "$(uname)" == "Darwin" ]; then
    if [ "$SHELL" == "/bin/zsh" ]; then
        echo "alias git='gitp'" >> ~/.zshrc
        source ~/.zshrc
    else
        echo "alias git='gitp'" >> ~/.bash_profile
        source ~/.bash_profile
    fi
else
    echo "alias git='gitp'" >> ~/.bashrc
    source ~/.bashrc
fi

echo "Installation complete! gitp will now intercept all git commands."