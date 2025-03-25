#!/bin/bash

# Main script for debugging Granola to Obsidian conversion

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Granola Notes (Debug)
# @raycast.mode silent
# @raycast.icon $HOME/projects/Granola Scraper/assets/icons/granola-debug.svg

# Optional parameters:
# @raycast.packageName Granola
# @raycast.subtitle Debug Granola notes conversion
# @raycast.shortcut cmd+shift+d

# Documentation:
# @raycast.description Process meeting notes with debug logging enabled
# @raycast.author Shawn Roos

# Inputs:
# @raycast.argument1 { "type": "text", "name": "notes", "placeholder": "Paste meeting notes here (or leave empty to use clipboard)", "optional": true }
# @raycast.argument2 { "type": "text", "name": "personal_notes", "placeholder": "Add personal notes (will appear in a callout)", "optional": true }

# This is a wrapper script that calls the main granola-to-obsidian.sh with debug mode enabled
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( dirname "$SCRIPT_DIR" )"

# Force debug mode to be enabled
export DEBUG_MODE=true
export ENABLE_DEBUG_LOGGING=true

# Call the main script with all arguments
"$SCRIPT_DIR/granola-to-obsidian.sh" "$@"

# After processing is complete, show the debug log
echo "Opening debug log..."
open -a Console "/tmp/granola-debug.log"
