#!/bin/bash

instruction="From the following data, generate a commit subject line and then a full description of the changes made in the form {subject}\n\n{description}, not including the git diff or branch:"

function generate_commit_message() {
    local branch_name="$1"
    local git_diff="$2"
    local intent="$3"
    local GPT_MODEL_CHOICE="$4"
    local GPT4_API_KEY="$5"

    local instruction="From the following data, generate a commit subject line and then a full description of the changes made in the form {subject}\n\n{description}, not including the git diff or branch:"
    local gpt_message="${instruction}: Branch: ${branch_name}. Git Diff: ${git_diff}."
    if [ -n "${intent}" ]; then
        gpt_message="${gpt_message} Intent: ${intent}."
    fi
    gpt_message=$(echo "${gpt_message}" | jq -sRr @json)
    local payload="{\"model\": \"${GPT_MODEL_CHOICE}\", \"messages\": [{\"role\": \"user\", \"content\": ${gpt_message}}]}"

    local api_response=$(curl -s -H "Content-Type: application/json" \
                             -H "Authorization: Bearer ${GPT4_API_KEY}" \
                             -d "${payload}" \
                             https://api.openai.com/v1/chat/completions)

    local error_message=$(echo "${api_response}" | jq -r '.error.message // empty')
    if [ -n "${error_message}" ]; then
        # Return the error message
        echo "${error_message}"
        return 1
    fi

    local commit_message_full=$(echo "${api_response}" | jq -r '.choices[0].message.content' | tr -d '\r')
    local commit_message_subject=$(printf "%b" "$(echo "${commit_message_full}" | awk -F'\n\n' '{print $1}' | sed -E 's/^"?(Subject: )?//')")
    local commit_message_body=$(printf "%b" "$(echo "${commit_message_full}" | awk -F'\n\n' '{print $2}' | sed -E 's/^"?(Description: )?//')")

    # Return the generated commit message subject and body
    echo -e "${commit_message_subject}\n${commit_message_body}"
    return 0
}

# Function to improve commit message
function improve_commit_message() {
    local commit_hash="$1"
    local branch_name="$2"
    local intent="$3"
    local GPT_MODEL_CHOICE="$4"
    local GPT4_API_KEY="$5"

    # Get the original commit message
    local original_message=$(git log -n 1 --pretty=format:"%B" "${commit_hash}")

    # Get the git diff for the commit
    local git_diff=$(git diff "${commit_hash}^" "${commit_hash}" | jq -sRr @json)

    # Generate the commit message using GPT (similar to the 'commit' section)
    read -r commit_message_subject commit_message_body < <(generate_commit_message "${branch_name}" "${git_diff}" "${intent}" "${GPT_MODEL_CHOICE}" "${GPT4_API_KEY}")

    # Combine the generated message with the original message
    local combined_message="${commit_message_subject}\n\n${commit_message_body}\n\n###RAW###\n\n${original_message}"

    # Create a temporary file to store the combined message
    local tmp_file=$(mktemp)
    echo -e "${combined_message}" > "${tmp_file}"

    # Create a custom script to open the editor in the foreground
    #local editor_script=$(mktemp)
    #echo "#!/bin/bash" > "${editor_script}"
    #echo "${EDITOR:-vi} -f \"\$1\"" >> "${editor_script}"
    #chmod +x "${editor_script}"

    # Open the editor for the user to review and edit the message
    #GIT_EDITOR="${editor_script}" git commit --amend -e -F "${tmp_file}"
    ${EDITOR:-vi} -f "${tmp_file}" </dev/tty

    git commit --amend -F "${tmp_file}"

    # Clean up the temporary files
    rm "${tmp_file}"
    #rm "${editor_script}"
}


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

    commit_message_output=( $(generate_commit_message "${branch_name}" "${git_diff}" "${intent}" "${GPT_MODEL_CHOICE}" "${GPT4_API_KEY}") )
    if [ $? -ne 0 ]; then
        echo "An error occurred while generating the commit message:"
        echo "${commit_message_output[0]}"  # The error message is stored in the first element of the array
        exit 1
    fi

    # Assign the elements of the array to the subject and body variables
    commit_message_subject="${commit_message_output[0]}"
    commit_message_body="${commit_message_output[1]}"

    # Debug: Print the read commit message subject and body
    #echo "Debug: Read Subject: ${commit_message_subject}" >&2
    #echo "Debug: Read Body: ${commit_message_body}" >&2

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

# Check if the command is 'git log'
elif [ "$1" == "log" ]; then
    shift

    backfill_flag="false"
    num_commits=""
    passthrough_flags=()

    # Parse the flags
    while (( "$#" )); do
        case "$1" in
            --backfill)
                backfill_flag="true"
                shift
                ;;
            -n)
                num_commits="$2"
                shift 2
                ;;
            *)
                passthrough_flags+=( "$1" )
                shift
                ;;
        esac
    done

    # Check if the backfill flag is set
    if [ "${backfill_flag}" == "true" ]; then
        # Get the list of commit hashes (up to the -n provided)
        if [ -n "${num_commits}" ]; then
            commit_hashes=$(git log -n "${num_commits}" --pretty=format:"%H")
        else
            commit_hashes=$(git log --pretty=format:"%H")
        fi

        # Iterate through each commit hash
        while read -r commit_hash; do
            # Call the function to improve the commit message
            improve_commit_message "${commit_hash}" "${branch_name}" "${intent}" "${GPT_MODEL_CHOICE}" "${GPT4_API_KEY}"
        done <<< "${commit_hashes}"
    else
        git log "${passthrough_flags[@]}"
    fi
elif [ "$1" == "branch" ]; then
    shift
    if [ "$#" -eq 0 ]; then
        branches_output=$(git branch --color=always)
        echo "${branches_output}" | while read -r branch_line; do
            branch_name=$(echo "${branch_line}" | sed 's/^\* //;s/^  //')
            branch_desc_ref="refs/notes/branch-descriptions/${branch_name}"
            if git show-ref --quiet --verify "${branch_desc_ref}" 2>/dev/null; then
                branch_desc=$(git notes --ref "branch-descriptions/${branch_name}" show 2>/dev/null)
                if [ $? -eq 0 ]; then
                    echo -e "${branch_line}\n$(echo "${branch_desc}" | sed 's/^/  /')\n"
                else
                    echo "${branch_line}"
                fi
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