#!/bin/bash

# Hardcoded paths
REMOTE_USER="ubuntu"
REMOTE_HOST="35.185.169.13"
REMOTE_PATH="/home/ubuntu/asdf"
LOCAL_PATH="/home/codezeros/Documents/RemoteStressTest/ssh" # Change this to your desired local path
IDENTITY_FILE="$HOME/.ssh/automation_registry"

mkdir -p "$LOCAL_PATH"

scp -r -i "$IDENTITY_FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH" "$LOCAL_PATH"

echo "Download complete! The folder has been copied to '$LOCAL_PATH'."
