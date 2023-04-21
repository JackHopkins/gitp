#!/bin/bash

# Check if a .git directory exists in the local directory
if [ -d "./.git" ]; then
    # If so, create a .gitp directory if it doesn't already exist
    if [ ! -d "./.gitp" ]; then
        mkdir ./.gitp
    fi

    # Check if .gitignore exists
    if [ -f "./.gitignore" ]; then
        # If so, add the .gitp directory to .gitignore if it's not already there
        if ! grep -qxF ".gitp" ./.gitignore; then
            echo ".gitp" >> ./.gitignore
        fi
    else
        # If .gitignore doesn't exist, create one and add the .gitp directory
        echo ".gitp" > ./.gitignore
    fi
else
    echo "Error: No .git directory found in the current directory."
    exit 1
fi


# Generate the ctags index excluding the .gitp directory
ctags -R --exclude=./.gitp --c-kinds=+p --extras=+q -f .gitp/tags

echo "Ctags index has been created and stored in the .gitp directory."
# Get the most recent changes
echo "Getting the most recent changes with 'git diff'..."
git_diff_output=$(git diff HEAD~1 --name-status)

# Extract the changed files
changed_files=$(echo "$git_diff_output" | awk '{if ($1 != "D") print $2}')

# Extract the methods and members that have been changed
echo "Extracting changed methods and members..."
changed_methods_and_members=""
for file in $changed_files; do
    git_diff_methods_and_members=$(git diff HEAD~1 -U0 -- "$file" | \
        awk '/^[\+\-]((public|private|protected|static)[[:space:]]+)*[a-zA-Z0-9_]+[[:space:]]+[a-zA-Z0-9_]+[[:space:]]*\(/ { gsub(/^[\+\-]/, "", $0); print $0} /^[\+\-](function[[:space:]]+)?[a-zA-Z0-9_]+[[:space:]]*\(\)/ { gsub(/^[\+\-]/, "", $0); print $0} /^[\+\-][a-zA-Z0-9_]+=/ { gsub(/^[\+\-]/, "", $0); print $0}')
    changed_methods_and_members+="$git_diff_methods_and_members"$'\n'
done

# Remove any duplicate entries
unique_changed_methods_and_members=$(echo "$changed_methods_and_members" | sort -u)

# Read the unique changed methods and members
all_ctags_output=""
for method_or_member in $unique_changed_methods_and_members; do
    # Use grep with -w and -F flags to search for exact matches efficiently
    ctags_output=$(grep -wF -e "$method_or_member" ".gitp/tags")
    all_ctags_output+="$ctags_output"$'\n'
done

# Remove duplicate ctags_output
unique_ctags_output=$(echo "$all_ctags_output" | sort | uniq)

# Print unique_ctags_output
echo "$unique_ctags_output"