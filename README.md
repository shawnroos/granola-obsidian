# Granola to Obsidian

Save Granola meeting notes to Obsidian via Raycast.

## Setup

```bash
mkdir -p ~/.raycast/scripts/
cp granola-to-obsidian.sh ~/.raycast/scripts/
chmod +x ~/.raycast/scripts/granola-to-obsidian.sh
```

## Usage

1. Copy text in Granola (⌘C)
2. Run "Granola Notes" from Raycast
3. Notes appear in Obsidian under Granola folder

## Project Structure

- `granola-to-obsidian.sh` - Main script for converting Granola notes to Obsidian
- `sync-to-raycast.sh` - Script to sync the project version with Raycast
- `.gitignore` - Excludes backups and logs from version control

## Features

- Automatically extracts meeting title, date, and attendees from Granola notes
- Creates properly formatted Obsidian markdown files with YAML front matter
- Adds links to meetings in daily notes
- Extracts topics from headings and bold text
- Handles various date formats
- Removes redundant content from notes
- Robust fallback mechanisms for date and attendee extraction
- Proper handling of daily note templates
- Clean formatting with Obsidian callout boxes
- Comprehensive error handling and debugging

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
