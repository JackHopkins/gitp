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
    git_diff=$(git diff | jq -sRr @json)

    if [ -z "${GPT4_API_KEY}" ]; then
        read -p "Enter your GPT-4 API key: " GPT4_API_KEY
        echo "export GPT4_API_KEY=${GPT4_API_KEY}" >> ~/.bashrc
        source ~/.bashrc
    fi

    echo ${GPT4_API_KEY}
    echo ${git_diff}
    # Pass the diff, branch name, and intent to GPT-3.5-turbo to generate the commit message
    commit_message=$(curl -s -H "Content-Type: application/json" \
                         -H "Authorization: Bearer ${GPT4_API_KEY}" \
                         -d "{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"user\", \"content\": \"Generate a commit message based on the following data: Branch: ${branch_name}. Diff: ${git_diff}. Intent: ${intent}.\"}]}" \
                         https://api.openai.com/v1/chat/completions | jq -r '.choices[0].message.content' | tr -d '\n')

    echo ${commit_message}
    # Commit with the generated message
    git commit -m "${commit_message}"
else
    echo "Invalid command. Usage: gitp commit [-i intent]"
    exit 1
fi
