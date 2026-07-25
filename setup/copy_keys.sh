# #!/bin/bash
# #
# # Copy the public and private keys across to all the testbed hosts using IP addresses.
# # Assumes that NAT forwarding has been configured and each of the VMs is running.
# #  
# # This _should_ be run on the controller host, but will work if run from elsewhere. 

# set -x

# # The user on the controller that will execute the test scripts
# controlleruser="deolubuntu"

# keypath="keys"

# client1_ipaddr="192.168.11.130"
# client2_ipaddr="192.168.11.131"
# router_ipaddr="192.168.11.128"
# server_ipaddr="192.168.11.132"

# # Function to configure SSH keys on the controller host
# # Arguments: controller IP address, controller username
# configure_controller_ssh_key() {
#     local controller=$1
#     local user=$2
#     local keypath=$3
#     echo "create .ssh folder"
#     ssh root@$controller 'mkdir .ssh/'
#     echo "Copying root public key to host at $controller"
#     scp -o StrictHostKeyChecking=no -p -i ~/.ssh/mptcprootkey $keypath/mptcprootkey.pub root@${controller}:/root/.ssh/authorized_keys
#     echo "set authorized keys permissions to 644"
#     ssh root@$controller 'chmod 644 .ssh/authorized_keys'    
#     echo "Copying root private key to host at $controller"
#     scp -p -i ~/.ssh/mptcprootkey ~/.ssh/mptcprootkey root@${controller}:/root/.ssh/
# }



# # Configure keys on router
# configure_controller_ssh_key "$router_ipaddr" "root" "$keypath"

# # Configure keys on client1
# configure_controller_ssh_key "$client1_ipaddr" "root" "$keypath"

# # Configure keys on client2
# configure_controller_ssh_key "$client2_ipaddr" "root" "$keypath"

# # Configure keys on server
# configure_controller_ssh_key "$server_ipaddr" "root" "$keypath"

# exit 0


# ------------------------------------------------------------------------

#!/usr/bin/env bash

# Stop when a command fails.
set -euo pipefail

# Uncomment for debugging.
# set -x

controlleruser="deolubuntu"
keypath="keys"

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

PRIVATE_KEY="$HOME/.ssh/mptcprootkey"

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

configure_controller_ssh_key() {
    local controller="$1"
    local user="$2"
    local keypath="$3"
    local nat_port="$4"

    local host="$controller"
    local port="22"

    # Windows Git Bash/macOS uses NAT forwarding.
    if [[ "$SSH_MODE" == "nat" ]]; then
        host="localhost"
        port="$nat_port"
    fi

    echo "Configuring keys on ${host}:${port}"

    echo "Creating .ssh folder"

    ssh -p "$port" \
        -o StrictHostKeyChecking=accept-new \
        "$user@$host" \
        'mkdir -p /root/.ssh && chmod 700 /root/.ssh'

    echo "Copying root public key"

    scp -P "$port" -p \
        -o StrictHostKeyChecking=accept-new \
        -i "$PRIVATE_KEY" \
        "$keypath/mptcprootkey.pub" \
        "$user@$host":/root/.ssh/authorized_keys

    echo "Setting authorized_keys permissions"

    ssh -p "$port" \
        -i "$PRIVATE_KEY" \
        "$user@$host" \
        'chmod 600 /root/.ssh/authorized_keys'

    echo "Copying root private key"

    scp -P "$port" -p \
        -i "$PRIVATE_KEY" \
        "$PRIVATE_KEY" \
        "$user@$host":/root/.ssh/mptcprootkey

    ssh -p "$port" \
        -i "$PRIVATE_KEY" \
        "$user@$host" \
        'chmod 600 /root/.ssh/mptcprootkey'
}

if [[ ! -f "$PRIVATE_KEY" ]]; then
    echo "ERROR: Private key not found: $PRIVATE_KEY"
    exit 1
fi

if [[ ! -f "$keypath/mptcprootkey.pub" ]]; then
    echo "ERROR: Public key not found: $keypath/mptcprootkey.pub"
    exit 1
fi

# Configure keys.
configure_controller_ssh_key \
    "$router_ipaddr" "root" "$keypath" "$router_port"

configure_controller_ssh_key \
    "$client1_ipaddr" "root" "$keypath" "$client1_port"

configure_controller_ssh_key \
    "$client2_ipaddr" "root" "$keypath" "$client2_port"

configure_controller_ssh_key \
    "$server_ipaddr" "root" "$keypath" "$server_port"

echo "SSH keys configured successfully."