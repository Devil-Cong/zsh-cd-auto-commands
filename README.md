# zsh-cd-auto-commands

Automatically execute configured commands when `cd` into specific directories. By placing a `.cd-auto-commands` configuration file in the project root, you can automatically run specified commands when entering that directory.

## Features

- Auto-detect directory changes and execute preset commands
- Support both local and global configuration modes
- Global configuration supports path matching (wildcard `*`)
- Avoid duplicate execution (won't trigger repeatedly in the same directory)
- Support comments and blank lines
- Flexible configuration for auto-activating virtual environments, switching Node versions, etc.
- Only works in interactive shell, doesn't affect script execution

## Installation

* [Oh My Zsh](#oh-my-zsh)
* [Manual](#manual-git-clone)

### Oh My Zsh

1. Clone this repository into `$ZSH_CUSTOM/plugins` (by default `~/.oh-my-zsh/custom/plugins`)

    ```sh
    git clone https://github.com/Devil-Cong/zsh-cd-auto-commands ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-cd-auto-commands
    ```

2. Add the plugin to the list of plugins for Oh My Zsh to load (inside `~/.zshrc`):

    ```sh
    plugins=(zsh-cd-auto-commands)
    ```

3. Start a new terminal session.

### Manual (Git Clone)

1. Clone this repository somewhere on your machine. This guide will assume `~/.zsh/zsh-cd-auto-commands`.

    ```sh
    git clone https://github.com/Devil-Cong/zsh-cd-auto-commands ~/.zsh/zsh-cd-auto-commands
    ```

2. Add the following to your `.zshrc`:

    ```sh
    source ~/.zsh/zsh-cd-auto-commands/zsh-cd-auto-commands.plugin.zsh
    ```

3. Start a new terminal session.

## Usage

### 1️⃣ Local Configuration (Project Level)

Create a `.cd-auto-commands` file in your project directory, **must start with `[.]`**:

```bash
# project-directory/.cd-auto-commands

[.]
# Example: Auto-switch Node version
nvm use

# Example: Activate Python virtual environment
source venv/bin/activate

# Example: Set environment variables
export PROJECT_ENV=development

# Example: Display welcome message
echo "Welcome to the project!"
```

**Important:** `[.]` represents the current directory with highest priority. Local configuration must start with it.

### 2️⃣ Global Configuration (Cross-Project)

Create a `~/.cd-auto-commands` file in your home directory, using `[path]` syntax to match directories:

```bash
# ~/.cd-auto-commands

# Match all Node.js projects
[~/projects/node-*]
nvm use
echo "Node environment ready"

# Match all Python projects
[~/projects/python-*]
source .venv/bin/activate
echo "Python virtual environment activated"

# Match work directories
[~/work/*]
export WORK_ENV=true
echo "Work environment loaded"

# Execute when entering HOME directory
[~]
echo "Welcome back home"

# Note: [.] can also be used in global config to match specific directories
```

**Path Matching Rules:**
- Supports `*` to match any characters
- Supports `~` auto-expansion to home directory
- `[.]` represents current directory
  - In local config: Must use `[.]` as the starting section, highest priority
  - In global config: Can use `[.]` to match specific directories (e.g., when entering HOME)
- Executes immediately after matching the first rule, no further matching

### 3️⃣ Custom Global Configuration Path

If you want to use a different location for the global configuration file, set the environment variable:

```bash
# Add to ~/.zshrc
export CD_AUTO_COMMANDS_GLOBAL="$HOME/.config/cd-auto-commands"
```

## Configuration Examples

### Local Configuration Examples

**Node.js Project:**
```bash
# project-directory/.cd-auto-commands
[.]
nvm use
npm install  # Auto-install dependencies
echo "Node environment ready"
```

**Python Project:**
```bash
# project-directory/.cd-auto-commands
[.]
source .venv/bin/activate
echo "Python virtual environment activated"
```

### Global Configuration Examples

**Unified Management of Multiple Projects:**
```bash
# ~/.cd-auto-commands

# Personal projects
[~/personal/*]
export PROJECT_TYPE=personal
echo "Personal project"

# Company projects - Node.js
[~/company/*/frontend]
nvm use
echo "Company frontend project"

# Company projects - Python
[~/company/*/backend]
source .venv/bin/activate
echo "Company backend project"

# Temporary projects
[/tmp/test-*]
export TEST_MODE=true
echo "Test environment"
```

## How It Works

### Execution Priority

1. **Local config first**: Prioritize checking `.cd-auto-commands` in current directory
2. **Global config fallback**: If no local config found, search for global config
3. **Must use `[path]` syntax**:
   - Local config: Must start with `[.]`
   - Global config: Use `[path]` to match directories

### Configuration File Locations

- **Local config**: `current-directory/.cd-auto-commands`
- **Global config**: `~/.cd-auto-commands` (default) or `$CD_AUTO_COMMANDS_GLOBAL`

## Troubleshooting

### Enable Debug Mode

If the plugin is not working as expected, you can enable debug mode to see detailed execution logs:

```bash
# Enable debug mode
export CD_AUTO_COMMANDS_DEBUG=1

# Reload the plugin
source ~/.oh-my-zsh/custom/plugins/zsh-cd-auto-commands/zsh-cd-auto-commands.plugin.zsh

# Or restart your terminal
```

**Disable debug mode:**
```bash
# Method 1: Unset the variable
unset CD_AUTO_COMMANDS_DEBUG

# Method 2: Set to 0
export CD_AUTO_COMMANDS_DEBUG=0
```

**Persist debug mode:**

Add to your `~/.zshrc` before loading Oh My Zsh:
```bash
export CD_AUTO_COMMANDS_DEBUG=1
```

## Notes

- Configuration file name is uniformly `.cd-auto-commands`
- Local config must start with `[.]`, otherwise an error will be raised
- Global config must use `[path]` syntax, otherwise an error will be raised
- In local config, `[.]` has the highest priority
- Lines starting with `#` are treated as comments
- Blank lines are automatically skipped
- Commands execute when entering a directory, supports all shell commands
- Only works in interactive shell, doesn't affect script execution