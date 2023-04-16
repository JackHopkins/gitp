commit_message_full=$(echo "Subject\n\nBody" | tr -d '\r')
commit_message_subject=$(echo "${commit_message_full}" | awk -F'\n\n' '{print $1}')
commit_message_body=$(echo "${commit_message_full}" | awk -F'\n\n' '{print $2}' | sed 's/\\n/\n/g')

echo "${commit_message_subject}"
echo "Blah"
echo "${commit_message_body}"