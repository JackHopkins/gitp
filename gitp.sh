#!/bin/bash

if [ "$1" == "commit" ]; then
    shift
    intent=""
    while getopts ":i:" opt; do
        case $opt in
            i)
                intent="${OPTARG}"
                ;;
            *)
                echo "Usage: gitp commit [-i intent]"
                exit 1
                ;;
        esac
    done

    branch_name=$(git symbolic-ref --short -q HEAD)
    git_diff=$(git diff --staged | jq -sRr @json)

    if [ -z "${git_diff}" ] || [ "${git_diff}" == '""' ]; then
        echo "No changes to commit. Exiting."
        exit 0
    fi

    echo ${git_diff}
    echo ${branch_name}

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

    # Prepare the GPT message content
    gpt_message="Generate a commit message based on the following data: Branch: ${branch_name}. Git Diff: ${git_diff}."
    if [ -n "${intent}" ]; then
        gpt_message="${gpt_message} Intent: ${intent}."
    fi

    payload="{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"user\", \"content\": \"${gpt_message}\"}]}"
    echo ${payload}
    # Pass the diff, branch name, and intent to GPT-3.5-turbo to generate the commit message
    commit_message=$(curl -s -H "Content-Type: application/json" \
                         -H "Authorization: Bearer ${GPT4_API_KEY}" \
                         -d "${payload}" \
                         https://api.openai.com/v1/chat/completions | jq -r '.choices[0].message.text' | tr -d '\n')

    # Commit with the generated message
    git commit -m "${commit_message}"
else
    echo "Invalid command. Usage: gitp commit [-i intent]"
    exit 1
fi
