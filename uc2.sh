# Save git diff output to a temporary file
temp_diff_file=$(mktemp)
git diff HEAD~1 > "$temp_diff_file"

# Read git diff output from the temporary file
git_diff=$(cat "$temp_diff_file")

# Get the list of modified functions and variables from the diff using perl
modified_items=$(echo "$git_diff" | perl -nle 'print $& if m{^\+[\w_]+\(\)}')


# Remove the '+' and '()' characters to get the item names
modified_item_names=$(echo "$modified_items" | sed 's/+\(.*\)(.*/\1/')

languages=("c" "python" "java" "shell" "ruby" "javascript" "golang")

# Iterate through the modified item names
while read -r item_name; do
  if [[ ! -z "$item_name" ]]; then
    # Search for the item_name in each language's tags file
    for lang in "${languages[@]}"; do

      tags_file="./.gitp/$lang/tags"
      db_path="./.gitp/$lang/codequery.db"
      if [ -e "$tags_file" ]; then
        if grep -q -w -e "^$item_name" "$tags_file"; then
          #echo "$item_name"
          cqsearch -s "$db_path" -p 1 -t "$item_name" -l 0 >> output.txt
          cqsearch -s "$db_path" -p 2 -t "$item_name" -l 0 >> output.txt
          cqsearch -s "$db_path" -p 3 -t "$item_name" -l 0 >> output.txt
          cqsearch -s "$db_path" -p 4 -t "$item_name" -l 0 >> output.txt
          cqsearch -s "$db_path" -p 5 -t "$item_name" -l 0 >> output.txt
          cqsearch -s "$db_path" -p 6 -t "$item_name" -l 0 >> output.txt
          cqsearch -s "$db_path" -p 7 -t "$item_name" -l 0 >> output.txt
          cqsearch -s "$db_path" -p 8 -t "$item_name" -l 0 >> output.txt
          cqsearch -s "$db_path" -p 9 -t "$item_name" -l 0 >> output.txt
          cqsearch -s "$db_path" -p 10 -t "$item_name" -l 0 >> output.txt
          cqsearch -s "$db_path" -p 11 -t "$item_name" -l 0 >> output.txt
          cqsearch -s "$db_path" -p 12 -t "$item_name" -l 0 >> output.txt
          cqsearch -s "$db_path" -p 13 -t "$item_name" -l 0 >> output.txt

          break
        fi
      fi
    done
  fi
done <<< "$modified_item_names"