#!/bin/bash

# Hardcoded paths
REMOTE_USER="ubuntu"
REMOTE_HOST="35.185.169.13"
REMOTE_FILE="/home/ubuntu/smr_node_logs/metrics.log"
LOCAL_PATH="./remote_files"
IDENTITY_FILE="$HOME/.ssh/automation_registry"

# Ensure local directory exists
mkdir -p "$LOCAL_PATH"


scp -i "$IDENTITY_FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_FILE" "$LOCAL_PATH/"

echo "Download complete! metrics.log has been copied to '$LOCAL_PATH'."
