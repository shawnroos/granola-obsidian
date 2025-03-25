#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Test Preferences
# @raycast.mode compact
# @raycast.icon 

# @raycast.preference.title Debug Mode
# @raycast.preference.description Enable debug logging
# @raycast.preference.type checkbox
# @raycast.preference.default false

# @raycast.preference.title Force Save
# @raycast.preference.description Force save even if duplicate is detected
# @raycast.preference.type checkbox
# @raycast.preference.default false

# @raycast.preference.title Enable Notifications
# @raycast.preference.description Show notifications for operations
# @raycast.preference.type checkbox
# @raycast.preference.default true

# @raycast.preference.title Update Daily Note
# @raycast.preference.description Add meeting link to daily note
# @raycast.preference.type checkbox
# @raycast.preference.default true

# @raycast.preference.title Check Duplicates
# @raycast.preference.description Check for duplicate notes before saving
# @raycast.preference.type checkbox
# @raycast.preference.default true

# @raycast.preference.title Open Note
# @raycast.preference.description Open note in Obsidian after creation
# @raycast.preference.type checkbox
# @raycast.preference.default true

# @raycast.preference.title Heading Level
# @raycast.preference.description Heading level for daily note meetings section
# @raycast.preference.type dropdown
# @raycast.preference.data [{"title": "Level 1 (#)", "value": "1"}, {"title": "Level 2 (##)", "value": "2"}, {"title": "Level 3 (###)", "value": "3"}]
# @raycast.preference.default 2

echo "Debug Mode: $RAYCAST_PREF_DEBUG_MODE"
echo "Force Save: $RAYCAST_PREF_FORCE_SAVE"
echo "Enable Notifications: $RAYCAST_PREF_ENABLE_NOTIFICATIONS"
echo "Update Daily Note: $RAYCAST_PREF_UPDATE_DAILY_NOTE"
echo "Check Duplicates: $RAYCAST_PREF_CHECK_DUPLICATES"
echo "Open Note: $RAYCAST_PREF_OPEN_NOTE"
echo "Heading Level: $RAYCAST_PREF_HEADING_LEVEL"
