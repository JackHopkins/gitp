# GitParts (gitp)

GitParts is a drop-in replacement for Git which aims to improve the _clarity_ and _consistency_ of your repos.
GitParts auto-generates commit messages and branch names by leveraging the power of GPT, a family of advanced language models developed by OpenAI, to autogenerate commit messages and branch names.

No more `asdasdg` commit messages. Make each commit description count.

## Features
- Autogenerate detailed and relevant commit messages with subject and description based on your staged changes. Optionally prompt additional context with the --intent flag.
- Autogenerate branch names from your intent and existing branch naming style.
- Display branch descriptions alongside branch names when listing branches.
- Backfill (and revert) your historic git commits with additional detail.
- *Full drop-in replacement for Git*.

## Prerequisites
- OpenAI API key
- jq
- Git

## Get Started

```bash
# Clone the Git repository
git clone https://github.com/JackHopkins/parts.git

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
Author: Jack Hopkins <jack.hopkins@me.com>
Date:   Sun Apr 16 22:51:48 2023 -0400

    Add instructions for installing and using GitParts

    Added detailed instructions for installing and using GitParts. The README now includes a list of prerequisites, step-by-step installation guide, a comprehensive list of features, and examples of how to use GitParts for committing changes and creating new branches. Additionally, the README now includes a section on how to uninstall GitParts, adding a complete guide for users who want to remove the tool.
```

To check and edit your message before it is committed, optionally use the new '--edit' (or '-e') flag to edit in you Git editor of choice (usually Vi).

```bash
git add .
git commit -e
```

To better include information relevant to the reader, optionally use the '--intent' (or '-i') flag when committing to prompt GPT.


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

## Experimental Features

- Backfilling Git Log to include auto-generated subject and descriptions about the commit.
