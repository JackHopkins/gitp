#!/bin/bash

# Save this file as 'uninstall-gitp.sh' and make it executable (chmod +x uninstall-gitp.sh)

# Remove the gitp script from /usr/local/bin
echo "Uninstalling gitp..."
sudo rm /usr/local/bin/gitp

# Remove the GPT4_API_KEY environment variable from the shell configuration file
echo "Removing GPT4_API_KEY environment variable..."
if [ "$(uname)" == "Darwin" ]; then
    if [ "$SHELL" == "/bin/zsh" ]; then
        sed -i '' '/export GPT4_API_KEY/d' ~/.zshrc
        source ~/.zshrc
    else
        sed -i '' '/export GPT4_API_KEY/d' ~/.bash_profile
        source ~/.bash_profile
    fi
else
    sed -i '/export GPT4_API_KEY/d' ~/.bashrc
    source ~/.bashrc
fi

echo "Uninstallation complete! gitp command and GPT4_API_KEY environment variable have been removed."