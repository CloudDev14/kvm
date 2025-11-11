#!/bin/bash
set -e

# Configuration
REMOTE_IP="10.1.1.104"
REMOTE_USER="root"
LOCAL_STATIC_DIR="/home/clouddev10/Desarrollo/kvm/static"
REMOTE_STATIC_DIR="/userdata/jetkvm/resource/static"

echo "=== Deploying UI to JetKVM Device ==="
echo "Target: $REMOTE_USER@$REMOTE_IP"
echo "Local UI: $LOCAL_STATIC_DIR"
echo "Remote path: $REMOTE_STATIC_DIR"
echo

# Check if static directory exists
if [ ! -d "$LOCAL_STATIC_DIR" ]; then
    echo "Error: Static directory not found at $LOCAL_STATIC_DIR"
    echo "Please run 'npm --prefix ui run build:device' first"
    exit 1
fi

# Function to transfer directory via tar+ssh
transfer_directory() {
    local local_dir="$1"
    local remote_dir="$2"
    
    echo "Transferring $local_dir to $remote_dir..."
    
    # Create remote directory and transfer files
    tar -czf - -C "$local_dir" . | ssh "$REMOTE_USER@$REMOTE_IP" "
        mkdir -p '$remote_dir' && \
        cd '$remote_dir' && \
        tar -xzf - && \
        echo 'Files extracted successfully'
    "
}

# Stop the jetkvm service
echo "Stopping jetkvm service..."
ssh "$REMOTE_USER@$REMOTE_IP" "pkill -9 jetkvm_app || true"
sleep 2

# Backup existing static directory
echo "Backing up existing static directory..."
ssh "$REMOTE_USER@$REMOTE_IP" "
    if [ -d '$REMOTE_STATIC_DIR' ]; then
        cp -r '$REMOTE_STATIC_DIR' '${REMOTE_STATIC_DIR}.backup.\$(date +%Y%m%d_%H%M%S)'
    fi
"

# Transfer new static files
transfer_directory "$LOCAL_STATIC_DIR" "$REMOTE_STATIC_DIR"

# Restart the jetkvm service
echo "Restarting jetkvm service..."
ssh "$REMOTE_USER@$REMOTE_IP" "
    cd /userdata/jetkvm && \
    nohup ./jetkvm_app > /dev/null 2>&1 &
"

sleep 3

echo
echo "=== Deployment Complete ==="
echo "The UI has been updated on the device"
echo "Access the device at: http://$REMOTE_IP"
