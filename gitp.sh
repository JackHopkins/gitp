#!/bin/bash

instruction="From the following data, generate a commit subject line and then a full description of the changes made in the form {subject}\n\n{description}, not including the git diff or branch:"

function generate_branch_name() {
    local intent="$1"
    local existing_branches="$2"
    local gpt_message="Generate a short new branch name in the style of the existing branches: ${existing_branches}, that captures the purpose of: ${intent}."
    gpt_message=$(echo "${gpt_message}" | tr -d '\n' | jq -sRr @json)
    local payload="{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"user\", \"content\": ${gpt_message}}]}"

    local api_response=$(curl -s -H "Content-Type: application/json" \
                             -H "Authorization: Bearer ${GPT4_API_KEY}" \
                             -d "${payload}" \
                             https://api.openai.com/v1/chat/completions)

    local error_message=$(echo "${api_response}" | jq -r '.error.message // empty')
    if [ -n "${error_message}" ]; then
        echo "An error occurred while generating the branch name:"
        echo "${error_message}"
        exit 1
    fi

    local branch_name=$(echo "${api_response}" | jq -r '.choices[0].message.content' | tr -d '\n' | tr -d '"')
    echo "${branch_name}"
}

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

    gpt_message="${instruction}: Branch: ${branch_name}. Git Diff: ${git_diff}."
    if [ -n "${intent}" ]; then
        gpt_message="${gpt_message} Intent: ${intent}."
    fi
    gpt_message=$(echo "${gpt_message}" | jq -sRr @json)
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

    commit_message_full=$(echo "${api_response}" | jq -r '.choices[0].message.content' | tr -d '\r')

    #echo ${commit_message_full}

    commit_message_subject=$(echo "${commit_message_full}" | awk -F'\n\n' '{print $1}')

    #echo ${commit_message_subject}

    commit_message_body=$(echo "${commit_message_full}" | awk -F'\n\n' '{print $2}' | sed 's/\\n/\n/g')

    #echo ${commit_message_body}

    if [ "${append_commit}" == "true" ]; then
        git commit --amend --no-edit --all "${passthrough_flags[@]}"
    else
        git commit -m "${commit_message_subject}" -m "${commit_message_body}" "${passthrough_flags[@]}"
    fi

    # Append the generated commit message to the branch description
    branch_desc_ref="refs/notes/branch-descriptions/${branch_name}"
    tmp_file=$(mktemp)

    # Check if the branch description ref exists
    if git show-ref --quiet --verify "${branch_desc_ref}" 2>/dev/null; then
        git show "${branch_desc_ref}" > "${tmp_file}"
    fi

    echo -e "\n${commit_message_subject}\n" >> "${tmp_file}"
    git notes --ref "branch-descriptions/${branch_name}" add -f -F "${tmp_file}"
    rm "${tmp_file}"

elif [ "$1" == "branch" ]; then
    shift

    if [ "$#" -eq 0 ]; then
        branches_output=$(git branch)
        echo "${branches_output}" | while read -r branch_line; do
            branch_name=$(echo "${branch_line}" | sed 's/^\* //;s/^  //')
            branch_desc_ref="refs/notes/branch-descriptions/${branch_name}"
            if git show-ref --quiet --verify "${branch_desc_ref}" 2>/dev/null; then
                branch_desc=$(git notes --ref "branch-descriptions/${branch_name}" show | sed 's/^/  /')
                echo -e "${branch_line}\n${branch_desc}\n"
            else
                echo "${branch_line}"
            fi
        done
    else
        passthrough_flags=()
        while (( "$#" )); do
            passthrough_flags+=( "$1" )
            shift
        done

        git branch "${passthrough_flags[@]}"
    fi
elif [ "$1" == "checkout" ]; then
    shift
    intent=""
    branch_flag=false
    passthrough_flags=()

    while (( "$#" )); do
        case "$1" in
            -i|--intent)
                intent="$2"
                shift 2
                ;;
            -b|--branch)
                branch_flag=true
                passthrough_flags+=( "$1" )
                shift
                ;;
            *)
                passthrough_flags+=( "$1" )
                shift
                ;;
        esac
    done

    if [ -n "${intent}" ] && [ "${branch_flag}" = true ]; then
        echo "Error: Cannot use both -i and -b flags simultaneously."
        exit 1
    fi

    if [ -n "${intent}" ]; then
        existing_branches=$(git branch --list | tr -d '* ' | jq -R . | jq -s .)
        new_branch_name=$(generate_branch_name "${intent}" "${existing_branches}")
        git checkout -b "${new_branch_name}"
    else
        git checkout "${passthrough_flags[@]}"
    fi

else
    command git "$@"
fi