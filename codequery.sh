#!/bin/bash

# Function to store find results in an array
find_to_array() {
  local _result_var="$1"
  shift
  local _find_args=("$@")
  local _files=()

  while IFS= read -r -d $'\0' file; do
    _files+=("$file")
  done < <(find "${_find_args[@]}" -print0)

  eval "$_result_var=(\"\${_files[@]}\")"
}

# Check if a .git directory exists in the local directory
if [ -d "./.git" ]; then
    # If so, create a .gitp directory if it doesn't already exist
    if [ ! -d "./.gitp" ]; then
        mkdir ./.gitp
    fi

    # If so, create a .gitp directory if it doesn't already exist
    if [ ! -d "./.gitp/pycscope" ]; then
        git clone https://github.com/portante/pycscope.git
        cp pycscope_init.py ./.gitp/pycscope/pycscope/__init__.py
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


# Create directories for each language
mkdir -p ./.gitp/c
mkdir -p ./.gitp/python
mkdir -p ./.gitp/java
mkdir -p ./.gitp/shell

# Function to perform indexing
index_files() {
  language=$1
  file_list=$2
  IFS='|' read -ra files <<< "$file_list"
  cscope_files="./.gitp/$language/cscope.files"
  cscope_out="./.gitp/$language/cscope.out"
  tags="./.gitp/$language/tags"
  omnitags="./.gitp/tags"
  codequery_db="./.gitp/$language/codequery.db"

  if [ ${#files[@]} -eq 0 ]; then
    echo "No .$language files found."
  else
    printf "%s\n" "${files[@]}" > "$cscope_files"
    if [ "$language" == "python" ]; then
      python .gitp/pycscope/pycscope/__init__.py -i "$cscope_files" -f "$cscope_out"
    else
      cscope -cb -i "$cscope_files" -f "$cscope_out"
    fi
    ctags --fields=+i -n -L "$cscope_files" --exclude=.git --exclude=.gitp -f "$tags"
    ctags --fields=+i -n -L "$cscope_files" --exclude=.git --exclude=.gitp -f "$omnitags"
    cqmakedb -s "$codequery_db" -c "$cscope_out" -t "$tags" -p
  fi
}

# Support for C/C++
c_files=$(find . \( -iname "*.c" -o -iname "*.cpp" -o -iname "*.cxx" -o -iname "*.cc" -o -iname "*.h" -o -iname "*.hpp" -o -iname "*.hxx" -o -iname "*.hh" \) | tr '\n' '|')
index_files "c" "$c_files"

# Support for Python
python_files=$(find . -iname "*.py" | tr '\n' '|')
index_files "python" "$python_files"

# Support for Java
java_files=$(find . -iname "*.java" | tr '\n' '|')
index_files "java" "$java_files"

# Support for Shell Script
shell_files=$(find . -iname "*.sh" | tr '\n' '|')
index_files "shell" "$shell_files"