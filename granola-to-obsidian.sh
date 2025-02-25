#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Granola Notes
# @raycast.mode silent

# Get clipboard and save to Obsidian
NOTES=$(pbpaste)
TITLE=$(echo "$NOTES" | head -n 1)
DATE=$(date +%d%m%Y)
CLEAN_TITLE=$(echo "$TITLE" | tr -cd '[:alnum:][:space:]-')
FILENAME="The $CLEAN_TITLE _$DATE.md"
OBSIDIAN_PATH="/Users/shawnroos/Library/Mobile Documents/iCloud~md~obsidian/Documents/Rooshub/Notes/Granola"
DAILY_PATH="/Users/shawnroos/Library/Mobile Documents/iCloud~md~obsidian/Documents/Rooshub/Notes/Dailys"
TEMPLATE_PATH="/Users/shawnroos/Library/Mobile Documents/iCloud~md~obsidian/Documents/Rooshub/Notes/Templates/Daily.md"

# Format today's date for daily note (25 February '25)
DAILY_NOTE_NAME="$(date "+%-d %B '%y").md"

# Save Granola note
mkdir -p "$OBSIDIAN_PATH"
echo "---
title: $TITLE
date: $(date +%Y-%m-%d)
type: granola
---

# $TITLE

$NOTES" > "$OBSIDIAN_PATH/$FILENAME"

# Handle daily note
DAILY_NOTE="$DAILY_PATH/$DAILY_NOTE_NAME"

# Create daily note if it doesn't exist
if [ ! -f "$DAILY_NOTE" ]; then
    cp "$TEMPLATE_PATH" "$DAILY_NOTE"
else
    # Check if Meetings section exists, if not add it
    if ! grep -q "^## 📅 Meetings" "$DAILY_NOTE"; then
        echo "
## 📅 Meetings
---" >> "$DAILY_NOTE"
    fi
fi

# Add link under Meetings section - look for the line after "## 📅 Meetings" and "---"
awk -v link="- [[Granola/The $CLEAN_TITLE _$DATE|$TITLE]]" '
    /^## 📅 Meetings/{p=1}
    p&&/^---/{print;print link;p=0;next}
    {print}
' "$DAILY_NOTE" > "$DAILY_NOTE.tmp" && mv "$DAILY_NOTE.tmp" "$DAILY_NOTE"

echo "✓ Saved to Obsidian and added to daily note: $TITLE"
