# Granola to Obsidian

Save Granola meeting notes to Obsidian via Raycast.

## Setup

```bash
mkdir -p ~/.raycast/scripts/
cp granola-to-obsidian.sh ~/.raycast/scripts/
chmod +x ~/.raycast/scripts/granola-to-obsidian.sh
```

For easier updates, you can use the included sync scripts:
```bash
./sync-to-raycast.sh      # Syncs the main script to Raycast
./sync-debug-to-raycast.sh # Syncs the debug version to Raycast
```

## Usage

1. Copy a Granola meeting note to your clipboard
2. Run the script from Raycast
3. Optionally add personal notes when prompted (these will appear in a callout)
4. The script will:
   - Create a new note in your Granola folder
   - Add the meeting to your daily note with the correct time format
   - Provide confirmation of successful processing

### Command Line Options

```
Usage: ./granola-to-obsidian.sh [options] [personal_notes]
Options:
  -h, --help              Show this help message
  -d, --debug             Enable debug logging
  -r, --raycast           Running from Raycast (affects output format)
  -n, --no-notifications  Disable notifications
  -t, --title <title>     Specify note title (overrides automatic detection)
  -D, --date <date>       Specify note date (overrides automatic detection)
  --no-daily              Don't update daily note
  --no-duplicate-check    Don't check for duplicates
  --no-open               Don't open note in Obsidian after creation
```

## Project Structure

- `bin/granola-to-obsidian.sh` - Main script for converting Granola notes to Obsidian
- `bin/granola-debug.sh` - Debug version of the script with enhanced logging
- `lib/` - Directory containing modular script components:
  - `date_utils.sh` - Date formatting and extraction utilities
  - `attendee_parser.sh` - Functions for extracting attendees and topics
  - `note_formatter.sh` - Note formatting and content processing
  - `obsidian_integration.sh` - Obsidian-specific operations
  - `duplicate_checker.sh` - Duplicate detection functionality
  - `notification_utils.sh` - Notification handling utilities
  - `utils.sh` - Common utility functions
- `config.sh` - Configuration settings for paths and options
- `sync-to-raycast.sh` - Script to sync the project version with Raycast
- `sync-debug-to-raycast.sh` - Script to sync the debug version with Raycast
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
  - Integration with Raycast for better user experience
  - Sound options for success and error notifications
- Simplified input handling:
  - Always reads meeting notes from clipboard
  - Accepts personal notes as an optional argument
  - Adds personal notes in a separate callout

## Input Handling

The script has been designed with a streamlined input approach:

1. **Meeting Notes**: Always read from clipboard
   - Simplifies the user experience
   - Avoids issues with long content in command arguments
   - Handles special characters and formatting better

2. **Personal Notes**: Provided as an optional argument
   - Added to the note in a dedicated callout
   - Preserves line breaks and formatting

This approach ensures consistent behavior across different usage scenarios and provides a more reliable experience.

## Configuration

The script can be customized through the `config.sh` file:

- **Paths and Directories**: Set Obsidian vault paths
- **Logging Configuration**: Control debug logging and log levels
- **Formatting Options**: Customize date formats and note appearance
- **Pattern Matching**: Configure attendee detection and exclusions
- **Notification Settings**: Enable/disable notifications and sounds
- **Daily Note Settings**: Customize how meetings appear in daily notes

### Key Configuration Options

```bash
# Logging configuration
ENABLE_DEBUG_LOGGING=false  # Enable or disable debug logging
LOG_LEVEL="debug"           # Options: debug, info, warning, error

# Note format options
USE_CALLOUTS=true                      # Use Obsidian callouts for meeting info
INCLUDE_TRANSCRIPT_URL=true            # Include transcript URL in notes
AUTO_EXTRACT_TOPICS=true               # Automatically extract topics from headings
INCLUDE_ATTENDEES_IN_FRONTMATTER=true  # Include attendees in front matter

# Validation settings
LENIENT_VALIDATION=true  # Allow non-standard content formats

# Daily note settings
INCLUDE_PERSONAL_NOTES_IN_DAILY=true    # Include personal notes in daily note
DAILY_NOTE_PERSONAL_FORMAT="  - 📝 {{PERSONAL_NOTES}}"  # Format for personal notes
```

#### Log Levels

The script supports four log levels:
- **debug**: Most verbose, logs everything
- **info**: Logs informational messages, warnings, and errors
- **warning**: Logs only warnings and errors
- **error**: Logs only errors

#### Auto-Extract Topics

When `AUTO_EXTRACT_TOPICS` is enabled, the script automatically extracts topics from level 2 and 3 headings (## and ###) in your meeting notes and adds them to the front matter. This makes it easier to organize and find related meetings.

#### Transcript URL

When `INCLUDE_TRANSCRIPT_URL` is enabled, the script will include a link to the original Granola transcript in the meeting information callout, making it easy to access the original source.

#### Personal Notes in Daily Notes

The `INCLUDE_PERSONAL_NOTES_IN_DAILY` option controls whether personal notes are included in the daily note. When enabled, personal notes will appear under the meeting entry using the format specified in `DAILY_NOTE_PERSONAL_FORMAT`.

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
