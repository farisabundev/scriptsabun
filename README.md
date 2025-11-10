# Scripts Toolkit

This directory contains a set of utility scripts for common Git operations and setup automation. The scripts are written in Zsh and designed for quick use from the terminal.

## Structure
````
scripts/
├── _colors.zsh   # Shared color definitions
├── _init         # Initializes permissions for all scripts
├── gfpl          # Git fetch and pull rebase
├── gpush         # Git commit and push helper
├── ms            # Safe merge script for merging feature branches

````

## Setup

1. Ensure this directory is in your PATH. Add the following line to your `.zshrc`:

   ```bash
   export PATH="$HOME/path/to/scripts:$PATH"
   ```

Replace `path/to/scripts` with the actual path of this folder.

2. Run the initialization script to set proper permissions:

   ```bash
   ./_init
   ```

   This will make all listed scripts executable.

## Scripts Overview

### `_colors.zsh`

Defines reusable ANSI color codes and helper functions for consistent, readable terminal output.

### `_init`

Sets execution permissions for scripts inside this directory. It automatically detects its own directory, so it can be run from anywhere.

### `gfpl`

Fetch and pull the latest changes from the current branch using `--rebase`.

Usage:

```bash
gfpl
```

Process:

1. Runs `git fetch` to retrieve the latest updates.
2. Runs `git pull --rebase` to apply changes.
3. Displays colorized output for success or failure.

### `gpush`

A simplified Git commit and push helper.

Usage:

```bash
gpush "commit message"
```

Options:

* `-na` or `--no-add`: Skip automatic `git add .`. The script will prevent committing if there are no staged changes.

### `ms`

Merge the current branch into a target branch safely.

Usage:

```bash
ms <target-branch> [--force]
```

Options:

* `--force`: Skip the confirmation prompt and merge immediately.

Process:

1. Detects the current branch.
2. Stashes any uncommitted changes.
3. Checks out the target branch.
4. Fetches and pulls updates.
5. Merges the current branch into the target branch.
6. If successful, pushes to origin and returns to the previous branch.
7. If there is a conflict, aborts the merge and restores the previous branch.

## Notes

* The scripts assume Zsh as the default shell.
* `_colors.zsh` must remain in the same directory, as other scripts source it.
* `_init` can be extended to auto-detect scripts dynamically.
