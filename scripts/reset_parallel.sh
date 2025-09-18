#!/bin/bash

# === Configuration ===
REMOTE_USER="ubuntu"
SSH_KEY_PATH="$HOME/.ssh/automation_registry"    

# List of remote hosts
REMOTE_HOSTS_VALIDATOR="104.199.143.64 34.146.238.44 34.47.214.94 34.93.67.69 34.143.206.81 34.76.140.195 35.234.142.159"
REMOTE_HOSTS_RPC="34.14.214.232 34.14.220.53"


# === Step 1: Stop all validators ===
echo ">>> Stopping all validators..."
for HOST in $REMOTE_HOSTS_VALIDATOR; do
  ssh -i "$SSH_KEY_PATH" "${REMOTE_USER}@${HOST}" "sudo systemctl stop supra-smr"
done

# === Step 1b: Stop all RPCs ===
echo ">>> Stopping all RPC nodes..."
for HOST in $REMOTE_HOSTS_RPC; do
  ssh -i "$SSH_KEY_PATH" "${REMOTE_USER}@${HOST}" "sudo systemctl stop supra-rpc"
done


# === Step 2: Cleanup all validators ===
echo ">>> Cleaning validator nodes..."
for HOST in $REMOTE_HOSTS_VALIDATOR; do
  ssh -i "$SSH_KEY_PATH" "${REMOTE_USER}@${HOST}" "sudo rm -rf supra_node_logs/ ledger_storage/ smr_storage/ smr_node_logs/"
done

# === Step 2b: Cleanup all RPCs ===
echo ">>> Cleaning RPC nodes..."
for HOST in $REMOTE_HOSTS_RPC; do
  ssh -i "$SSH_KEY_PATH" "${REMOTE_USER}@${HOST}" "sudo rm -rf rpc_ledger/ rpc_store_pruned/ snapshot/ rpc_archive_pruned/ smr_node_logs/"
done


# === Step 3: Start all validators ===
echo ">>> Starting all validators..."
for HOST in $REMOTE_HOSTS_VALIDATOR; do
  ssh -i "$SSH_KEY_PATH" "${REMOTE_USER}@${HOST}" "sudo systemctl start supra-smr"
done

# === Step 3b: Start all RPCs ===
echo ">>> Starting all RPC nodes..."
for HOST in $REMOTE_HOSTS_RPC; do
  ssh -i "$SSH_KEY_PATH" "${REMOTE_USER}@${HOST}" "sudo systemctl start supra-rpc"
done

echo ">>> Done!"

