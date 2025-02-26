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

## Keeping Scripts in Sync

To ensure your Raycast script stays in sync with the project version, use the sync script:

```bash
# Run this after making changes to the project version
./sync-to-raycast.sh
```

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
