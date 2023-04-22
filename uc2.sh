# Support for Shell Script
find . -iname "*.sh" > ./.gitp/cscope.files
cscope -cb -i ./.gitp/cscope.files -f ./.gitp/cscope.out
ctags --fields=+i -n -L ./.gitp/cscope.files --exclude=.git --exclude=.gitp -f .gitp/tags
cqmakedb -s ./.gitp/codequery.db -c ./.gitp/cscope.out -t ./.gitp/tags -p

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
      cqsearch -s ./.gitp/codequery.db -p 1 -t $item_name
      cqsearch -s ./.gitp/codequery.db -p 2 -t $item_name
      cqsearch -s ./.gitp/codequery.db -p 3 -t $item_name
      cqsearch -s ./.gitp/codequery.db -p 4 -t $item_name
      cqsearch -s ./.gitp/codequery.db -p 5 -t $item_name
  fi
done <<< "$modified_item_names"
