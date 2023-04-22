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

# Support for C/C++
find . -iname "*.c"    > ./cscope.files
find . -iname "*.cpp" >> ./cscope.files
find . -iname "*.cxx" >> ./cscope.files
find . -iname "*.cc " >> ./cscope.files
find . -iname "*.h"   >> ./cscope.files
find . -iname "*.hpp" >> ./cscope.files
find . -iname "*.hxx" >> ./cscope.files
find . -iname "*.hh " >> ./cscope.files

cscope -cb
ctags --fields=+i -n -L ./.gitp/cscope.files
cqmakedb -s ./codequery.db -c ./.gitp/cscope.out -t ./.gitp/tags -p

# Support for Python
find . -iname "*.py"    > ./.gitp/cscope.files
python .gitp/pycscope/pycscope/__init__.py -i ./.gitp/cscope.files -f ./.gitp/cscope.out
ctags --fields=+i -n -L ./.gitp/cscope.files  --exclude=.git --exclude=.gitp -f .gitp/tags
cqmakedb -s ./.gitp/codequery.db -c ./.gitp/cscope.out -t ./.gitp/tags -p

# Support for Java
find . -iname "*.java" > ./.gitp/cscope.files
cscope -cb -i ./.gitp/cscope.files -f ./.gitp/cscope.out
ctags --fields=+i -n -L ./.gitp/cscope.files
cqmakedb -s ./codequery.db -c ./.gitp/cscope.out -t ./tags -p

# Support for Shell Script
find . -iname "*.sh" > ./.gitp/cscope.files
cscope -cb -i ./.gitp/cscope.files -f ./.gitp/cscope.out
ctags --fields=+i -n -L ./.gitp/cscope.files --exclude=.git --exclude=.gitp -f .gitp/tags
cqmakedb -s ./.gitp/codequery.db -c ./.gitp/cscope.out -t ./.gitp/tags -p


cqsearch -s ./.gitp/codequery.db -p 1 -t format
