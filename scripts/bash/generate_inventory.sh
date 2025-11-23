#!/bin/bash
# Generate Ansible inventory from Vagrant SSH config

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INVENTORY_FILE="$PROJECT_ROOT/ansible/inventory/hosts.yml"
VAGRANT_DIR="$PROJECT_ROOT/vagrant"

echo "📝 Generating Ansible inventory: $INVENTORY_FILE"

cd "$VAGRANT_DIR"

# Get SSH key paths from Vagrant
ELK_KEY=$(vagrant ssh-config elk-server | grep IdentityFile | awk '{print $2}' | tr -d '"')
CLIENT_KEY=$(vagrant ssh-config ubuntu-client | grep IdentityFile | awk '{print $2}' | tr -d '"')
KALI_KEY=$(vagrant ssh-config kali-attacker | grep IdentityFile | awk '{print $2}' | tr -d '"')

cat > "$INVENTORY_FILE" << INVENTORY
---
all:
  vars:
    ansible_user: vagrant
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
    ansible_python_interpreter: /usr/bin/python3

  children:
    elk_servers:
      hosts:
        elk-server:
          ansible_host: 192.168.56.10
          ansible_port: 22
          ansible_ssh_private_key_file: $ELK_KEY

    clients:
      hosts:
        ubuntu-client:
          ansible_host: 192.168.56.20
          ansible_port: 22
          ansible_ssh_private_key_file: $CLIENT_KEY

    attackers:
      hosts:
        kali-attacker:
          ansible_host: 192.168.56.50
          ansible_port: 22
          ansible_ssh_private_key_file: $KALI_KEY
INVENTORY

echo "✅ Inventory generated successfully"
echo ""
echo "SSH Keys detected:"
echo "  elk-server: $ELK_KEY"
echo "  ubuntu-client: $CLIENT_KEY"
echo "  kali-attacker: $KALI_KEY"
