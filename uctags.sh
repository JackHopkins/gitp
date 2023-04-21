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

# Set the GTAGSROOT environment variable to point to the .gitp directory
export GTAGSROOT=$(pwd)/.gitp

# Get a list of changed files
changed_files=$(git diff --name-only HEAD~1)

# Get a list of files referenced in the git diff
referenced_files=$(git diff HEAD~1 | grep -oP "(?<=\+\+\+ b\/)(.*)(?=\n)" | sort -u)

# Combine both lists of files and remove duplicates
all_files=$(echo "$changed_files\n$referenced_files" | sort -u)

echo "All files"
echo "$referenced_files"
echo "---"
echo "$all_files"

# Get the tags from the global command
tags=$(global .)
echo "$tags"

# Get the most recent changes
echo "Getting the most recent changes with 'git diff'..."
git_diff_output=$(git diff HEAD~1 --name-status)

# Extract the changed files
changed_files=$(echo "$git_diff_output" | awk '{if ($1 != "D") print $2}')
echo "Changed files:"
echo "$changed_files"

# Extract the methods and members that have been changed
echo "Extracting changed methods and members..."
changed_methods_and_members=""
for file in $changed_files; do
    git_diff_methods_and_members=$(git diff HEAD~1 -U0 -- "$file" | \
        awk '/^[\+\-]((public|private|protected|static)[[:space:]]+)*[a-zA-Z0-9_]+[[:space:]]+[a-zA-Z0-9_]+[[:space:]]*\(/ { gsub(/^[\+\-]/, "", $0); print $0} /^[\+\-](function[[:space:]]+)?[a-zA-Z0-9_]+[[:space:]]*\(\)/ { gsub(/^[\+\-]/, "", $0); print $0} /^[\+\-][a-zA-Z0-9_]+=/ { gsub(/^[\+\-]/, "", $0); print $0}' | \
        sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g')
    changed_methods_and_members+="$git_diff_methods_and_members"$'\n'
done

echo "Changed methods and members:"
echo "$changed_methods_and_members"
exit 1

# Ensure GNU Global tag files are updated
#gtags --gtagslabel=pygments -f .gitp

# Find references and declarations for the changed methods and members
echo "Finding references and declarations for the changed methods and members..."
for method_or_member in $changed_methods_and_members; do
    # Remove any trailing characters like parentheses or semicolons
    clean_method_or_member=$(echo "$method_or_member" | sed -r 's/[();]*$//')

    # Find references
    echo "References of '$clean_method_or_member':"
    global -f -r -x "$clean_method_or_member"

    # Find declarations
    echo "Declarations of '$clean_method_or_member':"
    global -f -d -x "$clean_method_or_member"
done