#!/bin/bash
# sync-to-raycast.sh - Keep Raycast script in sync with project version

# Define paths
PROJECT_SCRIPT="/Users/shawnroos/projects/Granola Scraper/granola-to-obsidian.sh"
RAYCAST_SCRIPT="/Users/shawnroos/.raycast/scripts/granola-to-obsidian.sh"
BACKUP_DIR="/Users/shawnroos/projects/Granola Scraper/backups"
LOG_FILE="/Users/shawnroos/projects/Granola Scraper/sync.log"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if files exist
if [ ! -f "$PROJECT_SCRIPT" ]; then
    log "ERROR: Project script not found at $PROJECT_SCRIPT"
    exit 1
fi

if [ ! -f "$RAYCAST_SCRIPT" ]; then
    log "ERROR: Raycast script not found at $RAYCAST_SCRIPT"
    exit 1
fi

# Create a backup of the Raycast script
BACKUP_FILE="$BACKUP_DIR/granola-to-obsidian_$(date '+%Y%m%d_%H%M%S').sh.bak"
cp "$RAYCAST_SCRIPT" "$BACKUP_FILE"
log "Created backup of Raycast script at $BACKUP_FILE"

# Extract Raycast headers from the current Raycast script
RAYCAST_HEADERS=$(grep -E "^# @raycast\." "$RAYCAST_SCRIPT")

# Create a temporary file for the new Raycast script
TEMP_FILE=$(mktemp)

# Add Raycast headers to the new script
echo "#!/bin/bash" > "$TEMP_FILE"
echo "" >> "$TEMP_FILE"
echo "$RAYCAST_HEADERS" >> "$TEMP_FILE"
echo "" >> "$TEMP_FILE"

# Extract the main code from the project script (skip any functions at the top)
# This assumes the main code starts with "# Get clipboard and save to Obsidian"
sed -n '/# Get clipboard and save to Obsidian/,$p' "$PROJECT_SCRIPT" >> "$TEMP_FILE"

# Make sure we're using the correct emoji for Meetings section
sed -i '' 's/## Meetings/## 📅 Meetings/g' "$TEMP_FILE"

# Make sure we're using pbpaste directly (not handling piped input)
sed -i '' 's/if \[ -t 0 \]; then/# Always use clipboard in Raycast/g' "$TEMP_FILE"
sed -i '' '/# Always use clipboard in Raycast/,/fi/c\
NOTES=$(pbpaste)' "$TEMP_FILE"

# Make sure we have the correct success message
sed -i '' 's/echo " Saved to Obsidian/echo "✓ Saved to Obsidian/g' "$TEMP_FILE"

# Compare the modified file with the current Raycast script
if diff -q "$TEMP_FILE" "$RAYCAST_SCRIPT" >/dev/null; then
    log "Scripts are already in sync. No changes needed."
    rm "$TEMP_FILE"
else
    # Copy the modified file to Raycast
    cp "$TEMP_FILE" "$RAYCAST_SCRIPT"
    rm "$TEMP_FILE"
    
    # Make the Raycast script executable
    chmod +x "$RAYCAST_SCRIPT"
    log "Made Raycast script executable"
    
    # Show diff of what changed
    log "Changes made:"
    diff -u "$BACKUP_FILE" "$RAYCAST_SCRIPT" | grep -E "^[\+\-]" | tee -a "$LOG_FILE"
    
    log "Updated Raycast script with project version"
fi

log "Synchronization completed successfully"
echo "✅ Raycast script synchronized with project version"
