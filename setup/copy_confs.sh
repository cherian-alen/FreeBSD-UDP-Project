# #!/bin/bash

# set -x
# # Define IP addresses
# client1_ipaddr="192.168.11.130"
# client2_ipaddr="192.168.11.131"
# router_ipaddr="192.168.11.128"
# server_ipaddr="192.168.11.132"

# # Define SSH private key
# SSH_KEY="~/.ssh/mptcprootkey"

# # Function to copy config files
# copy_config_files() {
#   local ip=$1
#   local config_dir=$2

#   scp -p -i "$SSH_KEY" "$config_dir/rc.conf" root@"$ip":/etc/
#   scp -p -i "$SSH_KEY" "$config_dir/ipfw.rules" root@"$ip":/etc/
#   scp -p -i "$SSH_KEY" "$config_dir/loader.conf" root@"$ip":/boot/
# }

# # Copy config files for the server
# copy_config_files "$server_ipaddr" "confs/server"

# # Copy config files for client 1
# copy_config_files "$client1_ipaddr" "confs/client1"

# # Copy config files for router
# copy_config_files "$router_ipaddr" "confs/router"

# # Copy config files for client 2
# copy_config_files "$client2_ipaddr" "confs/client2"

# # Output completion message
# echo "Configuration files copied successfully."

# exit 0
# --------------------------------------------------------------------------

#!/usr/bin/env bash

# Stop when a command fails.
set -euo pipefail

# Uncomment for debugging.
# set -x

# Define internal IP addresses.
client1_ipaddr="192.168.11.130"
client2_ipaddr="192.168.11.131"
router_ipaddr="192.168.11.128"
server_ipaddr="192.168.11.132"

# Define VirtualBox NAT ports.
client1_port="3322"
client2_port="3323"
router_port="4422"
server_port="4423"

# Correct portable SSH private-key path.
SSH_KEY="$HOME/.ssh/mptcprootkey"

# Automatically select the connection method.
if [[ -z "${SSH_MODE:-}" ]]; then
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*|Darwin*)
            SSH_MODE="nat"
            ;;
        Linux*|FreeBSD*)
            SSH_MODE="direct"
            ;;
        *)
            SSH_MODE="nat"
            ;;
    esac
fi

echo "SSH connection mode: $SSH_MODE"

# Function to copy config files.
copy_config_files() {
    local ip="$1"
    local config_dir="$2"
    local nat_port="$3"

    local host="$ip"
    local port="22"

    # Windows Git Bash/macOS uses VirtualBox NAT forwarding.
    if [[ "$SSH_MODE" == "nat" ]]; then
        host="localhost"
        port="$nat_port"
    fi

    echo "Copying $config_dir to ${host}:${port}"

    scp -P "$port" -p -i "$SSH_KEY" \
        "$config_dir/rc.conf" \
        root@"$host":/etc/

    scp -P "$port" -p -i "$SSH_KEY" \
        "$config_dir/ipfw.rules" \
        root@"$host":/etc/

    scp -P "$port" -p -i "$SSH_KEY" \
        "$config_dir/loader.conf" \
        root@"$host":/boot/
}

if [[ ! -f "$SSH_KEY" ]]; then
    echo "ERROR: SSH key not found: $SSH_KEY"
    exit 1
fi

# Copy configuration files.
copy_config_files "$server_ipaddr"  "confs/server"  "$server_port"
copy_config_files "$client1_ipaddr" "confs/client1" "$client1_port"
copy_config_files "$router_ipaddr"  "confs/router"  "$router_port"
copy_config_files "$client2_ipaddr" "confs/client2" "$client2_port"

echo "Configuration files copied successfully."