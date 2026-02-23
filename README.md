# Pending Setups

Pending Setups is a Bash-based utility designed to manage and execute setup scripts for Zextras products (particularly Carbonio). It provides an interactive menu system to track and run pending configuration scripts, ensuring that system setups are performed in a controlled and logged manner.

The utility monitors a dedicated directory (`/etc/zextras/pending-setups.d/`) for setup scripts and provides both interactive and automated execution modes. All operations are logged for audit purposes, with automatic log rotation to maintain system health.

## Quick Start

### Prerequisites

- Docker or Podman installed
- Make

### Building Packages

```bash
# Build packages for Ubuntu 22.04
make build TARGET=ubuntu-jammy

# Build packages for Rocky Linux 9
make build TARGET=rocky-9

# Build packages for Ubuntu 24.04
make build TARGET=ubuntu-noble
```

### Supported Targets

- `ubuntu-jammy` - Ubuntu 22.04 LTS
- `ubuntu-noble` - Ubuntu 24.04 LTS
- `rocky-8` - Rocky Linux 8
- `rocky-9` - Rocky Linux 9

### Configuration

You can customize the build by setting environment variables:

```bash
# Use a specific container runtime
make build TARGET=ubuntu-jammy CONTAINER_RUNTIME=docker

# Use a different output directory
make build TARGET=rocky-9 OUTPUT_DIR=./my-packages
```

## Installation

This package is distributed as part of the [Carbonio platform](https://zextras.com/carbonio). To install:

### Ubuntu (Jammy/Noble)

```bash
sudo apt-get install ./artifacts/pending-setups*.deb
```

### Rocky Linux (8/9)

```bash
sudo yum install ./artifacts/pending-setups*.rpm
```

## Usage

The `pending-setups` command must be run as root. It provides both interactive and non-interactive modes.

### Interactive Mode (Default)

Simply run the command without arguments to launch the interactive menu:

```bash
sudo pending-setups
```

This will display a menu showing all pending setup scripts. You can:

- Select individual scripts to execute by entering their number
- Press `a` to execute all pending setups
- Press `q` to quit

### Non-Interactive Mode

Execute all pending setups without user interaction (useful for automation):

```bash
sudo pending-setups --execute-all
# or
sudo pending-setups -a
```

### Show Help

```bash
pending-setups --help
# or
pending-setups -h
```

## How It Works

### Directory Structure

The utility manages setup scripts in the following locations:

- **`/etc/zextras/pending-setups.d/`** - Place new setup scripts here (must be `.sh` files)
- **`/etc/zextras/pending-setups.d/done/`** - Successfully executed scripts are moved here
- **`/var/log/pending-setups/`** - Log files are stored here

### Setup Script Requirements

Setup scripts placed in `/etc/zextras/pending-setups.d/` must:

- Have a `.sh` file extension
- Be executable
- Return exit code `0` on success (script will be moved to `done/`)
- Return non-zero exit code on failure (script will be kept for retry)

### Authentication

The utility can work with Consul token authentication for Zextras products:

- Set the `SETUP_CONSUL_TOKEN` environment variable before running
- Or let the utility prompt for credentials and retrieve the token automatically

### Logging

All executions are logged to `/var/log/pending-setups/` with ISO 8601 timestamps. The utility automatically maintains the 100 most recent log files, deleting older ones.

## Example

```bash
# Place a setup script in the pending directory
sudo cp my-setup-script.sh /etc/zextras/pending-setups.d/

# Run pending-setups
sudo pending-setups

# You'll see:
# You have 1 pending setups to run
# 0) my-setup-script.sh
#
# a) execute all
# q) quit
#
# Please input your selection:
# >

# Enter 0 to execute the script, or 'a' to execute all
```

### Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for information on how to contribute to this project.

## License

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE.md](LICENSE.md) file for details.
