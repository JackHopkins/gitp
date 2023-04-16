response="Add trimming of quotes around branch name returned from API\n\nThis change modifies the generate_branch_name function in `gitp.sh` to remove any quotation marks around the branch name returned from the API before returning it. This was necessary to ensure that the branch name is properly formatted and can be used in subsequent git commands."

commit_message_full=$(echo ${response} | tr -d '\r')
commit_message_subject=$(echo "${commit_message_full}" | awk -F'\n\n' '{print $1}')
commit_message_body=$(echo "${commit_message_full}" | awk -F'\n\n' '{print $2}' | sed 's/\\n/\n/g')

echo "${commit_message_subject}"
echo "Blah"
echo "${commit_message_body}"