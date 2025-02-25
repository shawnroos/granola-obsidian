#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Granola Notes
# @raycast.mode silent

# Get clipboard and save to Obsidian
NOTES=$(pbpaste)
TITLE=$(echo "$NOTES" | head -n 1)
# Format date as DDMMYYYY
DATE=$(date +%d%m%Y)
# Clean title but keep spaces
CLEAN_TITLE=$(echo "$TITLE" | tr -cd '[:alnum:][:space:]-')
FILENAME="The $CLEAN_TITLE _$DATE.md"
OBSIDIAN_PATH="/Users/shawnroos/Library/Mobile Documents/iCloud~md~obsidian/Documents/Rooshub/Notes/Granola"

echo "---
title: $TITLE
date: $(date +%Y-%m-%d)
type: granola
---

# $TITLE

$NOTES" > "$OBSIDIAN_PATH/$FILENAME"

echo "✓ Saved to Obsidian: $TITLE"
