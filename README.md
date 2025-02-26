# Granola to Obsidian

Save Granola meeting notes to Obsidian via Raycast.

## Setup

```bash
mkdir -p ~/.raycast/scripts/
cp granola-to-obsidian.sh ~/.raycast/scripts/
chmod +x ~/.raycast/scripts/granola-to-obsidian.sh
```

## Usage

1. Copy a Granola meeting note to your clipboard
2. Run the script from Raycast or terminal
3. The script will:
   - Create a new note in your Granola folder
   - Add the meeting to your daily note with the correct time format
   - Provide confirmation of successful processing

## Project Structure

- `granola-to-obsidian.sh` - Main script for converting Granola notes to Obsidian
- `sync-to-raycast.sh` - Script to sync the project version with Raycast
- `.gitignore` - Excludes backups and logs from version control

## Features

- Extracts meeting details from Granola notes
- Creates structured Obsidian notes with front matter
- Extracts attendees from emails and names
- Integrates meeting notes into daily notes
- Prevents duplicate meeting entries
- Intelligent meeting time extraction:
  - Detects times in various formats (10:30 AM, 2pm, etc.)
  - Recognizes time patterns following "at" keyword
  - Falls back to calendar emoji (📅) when no specific time is found
- Comprehensive debug logging

## Daily Note Integration

The script integrates with Obsidian daily notes by:

1. Creating daily notes if they don't exist
2. Using the daily note template if available
3. Adding a Meetings section if not present
4. Adding links to meetings with timestamps
5. Preventing duplicate entries
6. Using robust fallback mechanisms for date formatting

## Keeping Scripts in Sync

To ensure your Raycast script stays in sync with the project version, use the sync script:

```bash
# Run this after making changes to the project version
./sync-to-raycast.sh
```

⚠️ **Important**: Always run the sync script after making any changes to the project version. This ensures that the Raycast extension has the latest features and bug fixes.

This will:
- Create a backup of the current Raycast script
- Copy the project version to Raycast
- Make it executable
- Log the changes

## Debugging

If you encounter issues, check the debug log at `/tmp/granola-debug.log` for detailed information about the processing steps.

## Best Practices

When making changes to the project version:
- Make incremental changes and test each change individually
- Use version control to track changes and collaborate with others
- Keep the project version organized and up-to-date
