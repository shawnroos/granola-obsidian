#!/bin/bash
# Script to sync the debug version to Raycast

# Set paths
RAYCAST_SCRIPT_PATH="$HOME/.raycast/scripts/granola-debug.sh"
BACKUP_DIR="$(dirname "$0")/backups"
DEBUG_SCRIPT="$(dirname "$0")/bin/granola-debug.sh"

# Create timestamp for backup filename
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Create backup of current Raycast script if it exists
if [ -f "$RAYCAST_SCRIPT_PATH" ]; then
    BACKUP_FILE="$BACKUP_DIR/granola-debug_${TIMESTAMP}.sh.bak"
    cp "$RAYCAST_SCRIPT_PATH" "$BACKUP_FILE"
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Created backup of Raycast debug script at $BACKUP_FILE"
fi

# Copy the debug script to Raycast
cp "$DEBUG_SCRIPT" "$RAYCAST_SCRIPT_PATH"

# Update the icon path in the Raycast script to use the absolute path
sed -i '' "s|\$HOME/projects/Granola Scraper|$HOME/projects/Granola Scraper|g" "$RAYCAST_SCRIPT_PATH"

# Make it executable
chmod +x "$RAYCAST_SCRIPT_PATH"

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Synchronized debug script to Raycast"
echo "Debug script synchronized with project version"
