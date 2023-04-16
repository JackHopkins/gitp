#!/bin/bash

GPT4_API_KEY_FILE="$HOME/.gpt4_api_key"

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
    git_diff=$(git diff)

    if [ -f "${GPT4_API_KEY_FILE}" ]; then
        GPT4_API_KEY=$(cat "${GPT4_API_KEY_FILE}")
    else
        read -p "Enter your GPT-4 API key: " GPT4_API_KEY
        echo "${GPT4_API_KEY}" > "${GPT4_API_KEY_FILE}"
    fi
    echo "Running"
    echo ${GPT4_API_KEY}
    # Pass the diff, branch name, and intent to GPT-3.5-turbo to generate the commit message
    commit_message=$(curl -s -H "Content-Type: application/json" \
                         -H "Authorization: Bearer ${GPT4_API_KEY}" \
                         -d "{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"user\", \"content\": \"Generate a commit message based on the following data: Branch: ${branch_name}. Diff: ${git_diff}. Intent: ${intent}.\"}]}" \
                         https://api.openai.com/v1/chat/completions | jq -r '.choices[0].message.text' | tr -d '\n')

    # Commit with the generated message
    #git commit -m "${commit_message}"
else
    echo "Invalid command. Usage: gitp commit [-i intent]"
    exit 1
fi
