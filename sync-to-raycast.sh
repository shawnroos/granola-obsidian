#!/bin/bash
# Script to sync the modular project version to Raycast

# Set paths
RAYCAST_SCRIPT_PATH="$HOME/.raycast/scripts/granola-to-obsidian.sh"
BACKUP_DIR="$(dirname "$0")/backups"
CONFIG_FILE="$(dirname "$0")/config.sh"
DATE_UTILS="$(dirname "$0")/lib/date_utils.sh"
ATTENDEE_PARSER="$(dirname "$0")/lib/attendee_parser.sh"
NOTE_FORMATTER="$(dirname "$0")/lib/note_formatter.sh"
OBSIDIAN_INTEGRATION="$(dirname "$0")/lib/obsidian_integration.sh"
DUPLICATE_CHECKER="$(dirname "$0")/lib/duplicate_checker.sh"
NOTIFICATION_UTILS="$(dirname "$0")/lib/notification_utils.sh"
MAIN_SCRIPT="$(dirname "$0")/bin/granola-to-obsidian.sh"

# Create timestamp for backup filename
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Create backup of current Raycast script if it exists
if [ -f "$RAYCAST_SCRIPT_PATH" ]; then
    BACKUP_FILE="$BACKUP_DIR/granola-to-obsidian_${TIMESTAMP}.sh.bak"
    cp "$RAYCAST_SCRIPT_PATH" "$BACKUP_FILE"
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Created backup of Raycast script at $BACKUP_FILE"
fi

# Start with shebang
echo '#!/bin/bash' > "$RAYCAST_SCRIPT_PATH"
echo '' >> "$RAYCAST_SCRIPT_PATH"

# Copy all Raycast metadata from the main script
grep "^# @raycast" "$MAIN_SCRIPT" >> "$RAYCAST_SCRIPT_PATH"
echo '' >> "$RAYCAST_SCRIPT_PATH"

# Add configuration variables
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Adding configuration variables"
grep -v "^#!/bin/bash" "$CONFIG_FILE" | grep -v "^#" | grep -v "^$" >> "$RAYCAST_SCRIPT_PATH"
echo "IS_RAYCAST=true" >> "$RAYCAST_SCRIPT_PATH"

# Fix paths for Raycast version
echo "HASH_STORAGE_DIR=\"\$HOME/.raycast/.note_hashes\"" >> "$RAYCAST_SCRIPT_PATH"

# Add code to ensure hash directory exists
cat >> "$RAYCAST_SCRIPT_PATH" << 'EOL'

# Ensure hash storage directory exists
mkdir -p "$HOME/.raycast/.note_hashes"
EOL

# Add utility functions from modules
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Adding utility functions from modules"

# Add debug log function
cat >> "$RAYCAST_SCRIPT_PATH" << 'EOL'

# Debug logging function
debug_log() {
    if [ "$ENABLE_DEBUG_LOGGING" = true ]; then
        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        echo "[$timestamp] $1" >> "$LOG_FILE"
    fi
}
EOL

# Add date utilities
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Adding date utilities"
grep -v "^#!/bin/bash" "$DATE_UTILS" | grep -v "^# Source the configuration file" | grep -v "SCRIPT_DIR=" | grep -v "source " >> "$RAYCAST_SCRIPT_PATH"

# Add attendee parser
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Adding attendee parser"
grep -v "^#!/bin/bash" "$ATTENDEE_PARSER" | grep -v "^# Source the configuration file" | grep -v "SCRIPT_DIR=" | grep -v "source " >> "$RAYCAST_SCRIPT_PATH"

# Add note formatter
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Adding note formatter"
grep -v "^#!/bin/bash" "$NOTE_FORMATTER" | grep -v "^# Source the configuration file" | grep -v "SCRIPT_DIR=" | grep -v "source " >> "$RAYCAST_SCRIPT_PATH"

# Add duplicate checker
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Adding duplicate checker"
grep -v "^#!/bin/bash" "$DUPLICATE_CHECKER" | grep -v "^# Source the configuration file" | grep -v "SCRIPT_DIR=" | grep -v "source " >> "$RAYCAST_SCRIPT_PATH"

# Add notification utilities
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Adding notification utilities"
grep -v "^#!/bin/bash" "$NOTIFICATION_UTILS" | grep -v "^# Source the configuration file" | grep -v "SCRIPT_DIR=" | grep -v "source " >> "$RAYCAST_SCRIPT_PATH"

# Add Obsidian integration
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Adding Obsidian integration"
grep -v "^#!/bin/bash" "$OBSIDIAN_INTEGRATION" | grep -v "^# Source the configuration file" | grep -v "SCRIPT_DIR=" | grep -v "source " >> "$RAYCAST_SCRIPT_PATH"

# Add main script logic
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Adding main script logic"
grep -v "^#!/bin/bash" "$MAIN_SCRIPT" | grep -v "^# @raycast" | grep -v "^# Get the script directory" | grep -v "SCRIPT_DIR=" | grep -v "^# Source configuration and modules" | grep -v "source " >> "$RAYCAST_SCRIPT_PATH"

# Update the icon path in the Raycast script to use the absolute path
sed -i '' "s|\$HOME/projects/Granola Scraper|$HOME/projects/Granola Scraper|g" "$RAYCAST_SCRIPT_PATH"

# Make the script executable
chmod +x "$RAYCAST_SCRIPT_PATH"
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Made Raycast script executable"

# Show diff of changes
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Changes made:"
diff -u "$BACKUP_FILE" "$RAYCAST_SCRIPT_PATH" | head -n 30

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Updated Raycast script with project version"
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Synchronization completed successfully"
echo " Raycast script synchronized with project version"
