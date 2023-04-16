#!/bin/bash

if [ -z "${GPT4_API_KEY}" ]; then
    if [ "$(uname)" == "Darwin" ]; then
        if [ "$SHELL" == "/bin/zsh" ]; then
            source ~/.zshrc
        else
            source ~/.bash_profile
        fi
    else
        source ~/.bashrc
    fi
fi

if [ "$1" == "commit" ]; then
    shift
    intent=""
    append_commit="false"
    passthrough_flags=()

    while (( "$#" )); do
        case "$1" in
            -i|--intent)
                intent="$2"
                shift 2
                ;;
            -a|--append)
                append_commit="true"
                shift
                ;;
            *)
                passthrough_flags+=( "$1" )
                shift
                ;;
        esac
    done

    branch_name=$(git symbolic-ref --short -q HEAD)
    git_diff=$(git diff --staged | jq -sRr @json)

    if [ -z "${git_diff}" ] || [ "${git_diff}" == '""' ]; then
        echo "No changes to commit. Exiting."
        exit 0
    fi

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

    gpt_message="Generate a commit message based on the following data: Branch: ${branch_name}. Git Diff: ${git_diff}."
    if [ -n "${intent}" ]; then
        gpt_message="${gpt_message} Intent: ${intent}."
    fi
    gpt_message=$(echo "${gpt_message}" | tr -d '\n' | jq -sRr @json)
    payload="{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"user\", \"content\": ${gpt_message}}]}"

    api_response=$(curl -s -H "Content-Type: application/json" \
                         -H "Authorization: Bearer ${GPT4_API_KEY}" \
                         -d "${payload}" \
                         https://api.openai.com/v1/chat/completions)

    error_message=$(echo "${api_response}" | jq -r '.error.message // empty')
    if [ -n "${error_message}" ]; then
        echo "An error occurred while generating the commit message:"
        echo "${error_message}"
        exit 1
    fi

    commit_message=$(echo "${api_response}" | jq -r '.choices[0].message.content' | tr -d '\n')

    if [ "${append_commit}" == "true" ]; then
        git commit --amend --no-edit --all "${passthrough_flags[@]}"
    else
        git commit -m "${commit_message}" "${passthrough_flags[@]}"
    fi
else
    echo "Invalid command. Usage: gitp commit [-i intent] [-a] [other git commit flags]"
    exit 1
fi