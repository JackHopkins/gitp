#!/bin/bash

# Save this file as 'install-gitp.sh' and make it executable (chmod +x install-gitp.sh)

# Check if jq is installed and install it if necessary
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Installing jq..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y jq
    elif command -v yum &> /dev/null; then
        sudo yum install -y jq
    elif command -v brew &> /dev/null; then
        brew install jq
    else
        echo "Error: Package manager not supported. Please install jq manually."
        exit 1
    fi
fi

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

echo "Installation complete! You can now use the gitp command."
