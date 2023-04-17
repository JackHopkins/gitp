# GitParts (gitp)

GitParts is a suite of drop-in Git automation tools designed to accelerate your development workflow.

## Features
- [ `git commit` ]: Auto-generate comprehensive commit messages (with subject and description) based on your staged changes. Never commit 'asdkjldgq' again.
- [ `git checkout -i` ]: Automatically generate branch names from your intent and existing branch naming style.
- [ `git branch` ]: Display branch descriptions alongside branch names when listing branches.
- [ `git log --backfill` ]: Back-fill your logs to enhance the quality of commit messages in your git tree.
- [ `git *` ]: Full drop-in replacement for Git.

## Prerequisites
- OpenAI API key
- Bash

## Get Started

```bash
# Clone the Git repository
git clone https://github.com/JackHopkins/parts.git

# Change to the cloned directory:
cd gitp

# Make the installation script executable:
chmod +x install.gitp.sh

# Run the installation script:
./install.gitp.sh
```

The script will install any necessary dependencies (such as jq), copy the gitp script to /usr/local/bin, set up your GPT API key as an environment variable, and create an alias for the git command to call gitp instead.

After completing these steps, the installation is complete, and gitp will now intercept all Git commands.

## Examples

### Commit changes

Auto-generate best-practice git commit messages from your staged commits.
```bash
git add .
git commit
```

```stdout
Add instructions for installing and using GitParts

Added detailed instructions for installing and using GitParts. The README now includes a list of prerequisites, step-by-step installation guide, a comprehensive list of features, and examples of how to use GitParts for committing changes and creating new branches. Additionally, the README now includes a section on how to uninstall GitParts, adding a complete guide for users who want to remove the tool.
```

Optionally use the '--intent' (or '-i') flag when committing, to better include information relevant to the reader.

### Create a new branch
Use the -i flag followed by a description of the purpose of branch to autogenerate in the style of existing branch names:

```bash
git checkout -i "Implement new user authentication feature"
```

```stdout
Switched to a new branch 'feature/new-user-authentication'
```


## Uninstall

```bash
#Change to the cloned directory:
cd parts

# Make the un-installation script executable:
chmod +x uninstall.gitp.sh

# Run the uninstallation script:
./uninstall.gitp.sh
```