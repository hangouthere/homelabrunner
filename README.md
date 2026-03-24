# HomeLab Runner (HLRunner)

A CLI tool for managing multiple Docker Compose stacks with isolated networks and smart upgrade detection.

## Features

- **Per-stack isolation** - Each stack in its own directory with isolated networks, but can be joined to multiple networks through standard compose networking.
- **Smart upgrades** - Automatically detects build contexts vs image-only stacks
- **Template support** - Quick scaffolding for new stacks
- **Batch operations** - Upgrade all stacks at once

## Installation

HLRunner follows XDG Base Directory specification. The executable can be installed separately from its data files (`lib/` and `templates/`).

> Protip: Regardless of your install method, an alias can make usage easier:
> ```sh
> alias hlr='hlrunner'
> alias hlrup='hlrunner up'
> # etc
> ```

### Recommended: User installation (local)

This installs the executable to your PATH and data files to `~/.local/share/hlrunner`:

```bash
# Create local bin directory (if it doesn't exist)
mkdir -p ~/.local/bin

# Copy the executable
cp hlrunner ~/.local/bin/
chmod +x ~/.local/bin/hlrunner

# Copy data files to XDG data directory
mkdir -p ~/.local/share/hlrunner
cp -r lib templates ~/.local/share/hlrunner/

# Add to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### System-wide installation

For multi-user systems, install to `/opt` or `/usr/local`:

```bash
# System-wide (requires sudo for /opt)
sudo cp -r . /opt/hlrunner
sudo ln -s /opt/hlrunner/hlrunner /usr/local/bin/hlrunner

# Or install data files to /usr/local/share and keep executable elsewhere
sudo cp -r lib templates /usr/local/share/hlrunner/
```

### Portable / Development

To run directly from the source directory (useful for development):

```bash
cd /path/to/hlrunner
./hlrunner list
```

Or symlink the entire directory:

```bash
ln -s /path/to/hlrunner ~/.local/share/hlrunner
ln -s ~/.local/share/hlrunner/hlrunner ~/.local/bin/hlrunner
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `HLR_STACKS_PATH` | Path to stacks directory | Current directory |
| `HLR_DATA_DIR` | Path to lib/templates | `$HLR_STACKS_PATH` |

Use `HLR_DATA_DIR` if you want to store data in a non-standard location.

## Directory Structure

```
stacks/
  web/
    compose.yaml
    .env
    .env-example
  sync/
    compose.yaml
    .env
  vpn/
    compose.yaml
    .env
```

Each stack is a directory containing:
- `compose.yaml` (or `compose.yml`, `docker-compose.yaml`, `docker-compose.yml` for compatibility)
- `.env` (environment variables)
- `.env-example` (template for new deployments)

## Usage

```bash
hlrunner <command> [arguments]
```

### Commands

| Command | Description |
|---------|-------------|
| `hlrunner` | Show help/commands |
| `hlrunner list` | List all stacks |
| `hlrunner up <stack>` | Start a stack |
| `hlrunner down <stack>` | Stop a stack |
| `hlrunner build <stack>` | Build stack images (with --pull) |
| `hlrunner logs <stack>` | View logs |
| `hlrunner pull <stack>` | Pull latest images |
| `hlrunner upgrade <stack>` | Smart upgrade (build or pull, then restart) |
| `hlrunner ps` | Show running containers |
| `hlrunner psp` | Show running containers, with port routing |
| `hlrunner upall` | Start all stacks |
| `hlrunner downall` | Stop all stacks |
| `hlrunner pullall` | Pull all stacks |
| `hlrunner upgradeall` | Upgrade all stacks |
| `hlrunner init <name>` | Create new stack from template |

## Smart Upgrade

The `upgrade` and `upgradeall` commands automatically detect stack type:

- **Image-only stacks** - Uses `docker compose pull` to fetch latest images
- **Build stacks** (with `build:` in compose) - Uses `docker compose build --pull` to rebuild and pull base images

This handles both upstream image updates and custom Dockerfile changes automatically.

## Examples

```bash
# List all stacks
hlrunner list

# Start a stack
hlrunner up web

# Upgrade all stacks
hlrunner upgradeall

# Use custom stacks path
HLR_STACKS_PATH=~/mystacks hlrunner list

# Create new stack
hlrunner init mynewstack
```
