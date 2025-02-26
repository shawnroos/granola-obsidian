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

- Extracts meeting date from various formats with fallback mechanisms
- Identifies attendees from complex name formats and email addresses
- Extracts meeting topics from headings and bold text
- Creates structured Obsidian notes with proper frontmatter
- Generates daily note entries with links to meeting notes
  - Adds timestamped links to meetings in the daily note
  - Prevents duplicate entries
- Formats notes with Obsidian callout boxes for metadata
- Properly handles daily note templates with date substitution
- Removes redundant content for cleaner notes
- Comprehensive debug logging for troubleshooting

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

If you encounter issues with date extraction or other features:
1. Check the debug log at `/tmp/granola-debug.log`
2. The log contains detailed information about date extraction, attendee detection, and file operations
3. Make changes to the project version first, then sync to Raycast

## Best Practices

When making changes to the project version:
- Make incremental changes and test each change individually
- Use version control to track changes and collaborate with others
- Keep the project version organized and up-to-date
