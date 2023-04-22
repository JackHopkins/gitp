#!/bin/bash

# Generate the tags file with scope information
ctags -R --fields=+lS --languages=-all --languages=+sh,+c,+C++,+python --extras=+q --exclude=.git --exclude=.gitp -f .gitp/tags

# Save git diff output to a temporary file
temp_diff_file=$(mktemp)
git diff HEAD~1 > "$temp_diff_file"

# Read git diff output from the temporary file
git_diff=$(cat "$temp_diff_file")

# Get the list of modified functions and variables from the diff using perl
modified_items=$(echo "$git_diff" | perl -nle 'print $& if m{^\+[\w_]+\(\)}')

# Remove the '+' and '()' characters to get the item names
modified_item_names=$(echo "$modified_items" | sed 's/+\(.*\)(.*/\1/')

# Iterate through the modified item names and find their definitions in the tags file
while read -r item_name; do
  if [[ ! -z "$item_name" ]]; then
    tag_line=$(grep -m 1 "^$item_name\\s" .gitp/tags)
    # Get the source file, the search pattern, and the function scope from the tag_line
    source_file=$(echo "$tag_line" | awk '{print $2}')
    search_pattern=$(echo "$tag_line" | awk '{print $3}' | sed 's/\/\^//;s/\$\/;//')
    function_scope=$(echo "$tag_line" | awk -F'scope:' '{print $2}' | awk '{print $1}')

    # Find the function definition line number
    function_line_number=$(grep -n -m 1 -E "$search_pattern" "$source_file" | cut -f1 -d:)

    if [[ ! -z "$function_line_number" ]]; then
      if [[ ! -z "$function_scope" ]]; then
        # Extract the function using ctags scope information
        function_start_line=$(grep -n -m 1 -E "^$function_scope\\s" .gitp/tags | awk -F'scope:' '{print $2}' | awk '{print $2}' | sed 's/\/\^//;s/\$\/;//' | xargs -I {} grep -n -m 1 -E {} "$source_file" | cut -f1 -d:)
        function_end_line=$(grep -n -m 1 -E "^$function_scope\\s" .gitp/tags | awk '{print $3}' | sed 's/\/\^//;s/\$\/;//' | xargs -I {} grep -n -m 1 -E {} "$source_file" | cut -f1 -d:)
        sed -n "${function_start_line},${function_end_line}p" "$source_file"
      else
        echo "Function extraction for '$item_name' is not supported due to missing scope information."
      fi
    fi
  fi
done <<< "$modified_item_names"

# Remove the temporary file
rm "$temp_diff_file"
