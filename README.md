# GitParts (gitp)

GitParts is a command-line tool that enhances your Git workflow.

Leverage GPT to generate commit messages and branch names based on your intent and staged changes.

## Features
- Generate comprehensive commit messages (with subject and description) based on your staged changes.
- Automatically generate branch names from your intent and existing branch naming style.
- Display branch descriptions alongside branch names when listing branches.
- *Full drop-in replacement for Git*.

## Prerequisites
- OpenAI API key
- jq
- Git

## Get Started

```bash
# Clone the Git repository
git clone https://github.com/Noddybear/parts.git

# Change to the cloned directory:
cd parts

# Make the installation script executable:
chmod +x install-gitp.sh

# Run the installation script:
./install-gitp.sh
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
Improve branch naming message for better clarity

This commit improves the message used to generate a new branch name in the gitp.sh script. Previously, the message only stated the existing branches and intent, but the new message adds a description of the intended purpose of the new branch. This change makes the message more clear and comprehensive.
```

### Create a new branch
Use the -i flag followed by a description of the purpose of branch to autogenerate in the style of existing branch names:

```bash
git checkout -i "Implement new user authentication feature"
```

```stdout
Switched to a new branch 'feature/new-user-authentication'
```


## Uninstalling

```bash
#Change to the cloned directory:
cd parts

# Make the un-installation script executable:
chmod +x uninstall-gitp.sh

# Run the uninstallation script:
./uninstall-gitp.sh
```