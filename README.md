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

- `bin/granola-to-obsidian.sh` - Main script for converting Granola notes to Obsidian
- `lib/` - Directory containing modular script components:
  - `date_utils.sh` - Date formatting and extraction utilities
  - `attendee_parser.sh` - Functions for extracting attendees and topics
  - `note_formatter.sh` - Note formatting and content processing
  - `obsidian_integration.sh` - Obsidian-specific operations
- `config.sh` - Configuration settings for paths and options
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
- Duplicate detection:
  - Prevents creating duplicate notes from the same meeting
  - Checks by title and date, transcript URL, and content hash
  - Configurable detection methods in config.sh
- Enhanced notifications:
  - Emoji-based status messages (✅, ❌, ⚠️, ℹ️)
  - Special Raycast integration for better user feedback
  - Different notification types for success, errors, and warnings

## Daily Note Integration

The script automatically adds a link to each meeting note in the corresponding daily note. The integration:

- Creates the daily note if it doesn't exist
- Adds a configurable "Meetings" section if not present
- Inserts a link to the meeting note under the Meetings section
- Avoids creating duplicate links

You can customize the daily note integration in `config.sh`:

```bash
# Daily note settings
DAILY_NOTE_MEETINGS_HEADING="Meetings"  # Heading to use for meetings section
DAILY_NOTE_MEETINGS_EMOJI="📅"          # Emoji to use for meetings heading
DAILY_NOTE_HEADING_LEVEL=2              # Heading level (1 = #, 2 = ##, 3 = ###)
DAILY_NOTE_LINK_FORMAT="- {{EMOJI}} [[Granola/{{FILENAME}}|{{TITLE}}]]"  # Format for meeting links
DAILY_NOTE_TIME_FORMAT="- {{TIME}} - [[Granola/{{FILENAME}}|{{TITLE}}]]"  # Format when time is available
```

This allows you to:
- Change the heading level (e.g., `##` vs `###`)
- Customize the heading text and emoji
- Modify the format of meeting links

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

## Code Organization

The codebase has been modularized for better maintainability and extensibility:

1. **Configuration Management**: All configurable parameters are stored in `config.sh`
2. **Modular Structure**: Code is organized into logical modules in the `lib/` directory
3. **Error Handling**: Robust error codes and handling for reliable operation
4. **Performance Optimization**: Reduced redundancy and improved efficiency

This modular approach makes it easier to:
- Add new features
- Fix bugs in isolated components
- Test individual functions
- Understand the codebase

## Debugging

If you encounter issues, check the debug log at `/tmp/granola-debug.log` for detailed information about the processing steps.

## Best Practices

When making changes to the project version:
- Make incremental changes and test each change individually
- Use version control to track changes and collaborate with others
- Keep the project version organized and up-to-date
