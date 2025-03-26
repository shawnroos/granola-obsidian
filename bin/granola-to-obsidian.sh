#!/bin/bash

# Main script for converting Granola notes to Obsidian

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Granola Notes
# @raycast.mode silent
# @raycast.icon $HOME/projects/Granola Scraper/assets/icons/granola-notes.svg

# Optional parameters:
# @raycast.packageName Granola
# @raycast.subtitle Convert Granola meeting notes to Obsidian
# @raycast.shortcut cmd+shift+g

# Documentation:
# @raycast.description Process meeting notes from Granola and save to Obsidian
# @raycast.author Shawn Roos

# Inputs:
# @raycast.argument1 { "type": "text", "name": "personal_notes", "placeholder": "Add personal notes (will appear in a callout)", "optional": true }

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( dirname "$SCRIPT_DIR" )"

# Source configuration and modules
source "$PROJECT_ROOT/config.sh"
source "$PROJECT_ROOT/lib/date_utils.sh"
source "$PROJECT_ROOT/lib/attendee_parser.sh"
source "$PROJECT_ROOT/lib/note_formatter.sh"
source "$PROJECT_ROOT/lib/duplicate_checker.sh"
source "$PROJECT_ROOT/lib/notification_utils.sh"
source "$PROJECT_ROOT/lib/obsidian_integration.sh"

# Parse command-line arguments when not in Raycast
if [[ "$IS_RAYCAST" != "true" ]]; then
    # Show help message
    show_help() {
        echo "Usage: $0 [options] [personal_notes]"
        echo "Options:"
        echo "  -h, --help              Show this help message"
        echo "  -d, --debug             Enable debug logging"
        echo "  -r, --raycast           Running from Raycast (affects output format)"
        echo "  -n, --no-notifications  Disable notifications"
        echo "  -t, --title <title>     Specify note title (overrides automatic detection)"
        echo "  -D, --date <date>       Specify note date (overrides automatic detection)"
        echo "  --no-daily              Don't update daily note"
        echo "  --no-duplicate-check    Don't check for duplicates"
        echo "  --no-open               Don't open note in Obsidian after creation"
        echo "  --no-personal-in-daily  Don't include personal notes in daily note"
        echo "  --personal-in-daily     Include personal notes in daily note (default)"
        echo ""
        echo "Notes:"
        echo "  - Meeting notes are always read from clipboard"
        echo "  - Personal notes can be provided as an argument and will appear in a callout"
        echo ""
        echo "Examples:"
        echo "  $0                      # Process notes from clipboard"
        echo "  $0 \"My personal notes\"  # Process notes from clipboard and add personal notes"
        echo "  $0 -d                   # Process notes with debug logging enabled"
        exit 0
    }

    # Parse command line options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                ;;
            -d|--debug)
                DEBUG_MODE="true"
                shift
                ;;
            -f|--force)
                FORCE_SAVE="true"
                shift
                ;;
            -p|--personal-notes)
                if [ -n "$2" ]; then
                    PERSONAL_NOTES_ARG="$2"
                    shift 2
                else
                    echo "Error: --personal-notes requires an argument."
                    exit 1
                fi
                ;;
            --no-personal-in-daily)
                INCLUDE_PERSONAL_NOTES_IN_DAILY="false"
                shift
                ;;
            --personal-in-daily)
                INCLUDE_PERSONAL_NOTES_IN_DAILY="true"
                shift
                ;;
            *)
                # If no explicit option is given, assume it's the personal notes
                if [ -z "$PERSONAL_NOTES_ARG" ]; then
                    PERSONAL_NOTES_ARG="$1"
                fi
                shift
                ;;
        esac
    done
else
    # In Raycast mode, get arguments from Raycast
    PERSONAL_NOTES_ARG="$1"
    
    # Log input source in Raycast mode
    if [ -n "$PERSONAL_NOTES_ARG" ]; then
        debug_log "Using personal notes from Raycast argument (length: ${#PERSONAL_NOTES_ARG})"
    fi
fi

# Enable debug logging if debug mode is enabled
if [[ "$DEBUG_MODE" == "true" ]]; then
    export ENABLE_DEBUG_LOGGING="true"
    debug_log "Debug mode enabled via configuration"
    log_debug_to_raycast "Debug mode enabled via configuration"
fi

# Log configuration settings
debug_log "Configuration settings:"
debug_log "  FORCE_SAVE: $FORCE_SAVE"
debug_log "  DEBUG_MODE: $DEBUG_MODE"
debug_log "  PERSONAL_NOTES_ARG: ${PERSONAL_NOTES_ARG:0:20}..."

# Error handling function
handle_error() {
    local error_code=$1
    local error_message=$2
    
    debug_log "Error $error_code: $error_message"
    
    case $error_code in
        $ERROR_INVALID_INPUT)
            show_error "Error: $error_message"
            ;;
        $ERROR_DATE_EXTRACTION_FAILED)
            show_error "Error: Could not extract date from meeting notes."
            ;;
        $ERROR_FILE_CREATION_FAILED)
            show_error "Error: Failed to create or write to file."
            ;;
        $ERROR_OBSIDIAN_PATH_NOT_FOUND)
            show_error "Error: Obsidian path not found or inaccessible."
            ;;
        *)
            show_error "Error: An unknown error occurred."
            ;;
    esac
    
    exit $error_code
}

# Initialize log file
echo "=== Starting new conversion $(date) ===" > "$LOG_FILE"

# Show initial progress
if [[ "$IS_RAYCAST" == "true" ]]; then
    show_progress "10%"
fi

# Get input from clipboard
debug_log "Starting input processing"

# Use clipboard content directly
NOTES=$(pbpaste)
debug_log "Using notes from clipboard (length: ${#NOTES} characters)"

# Log first 100 characters of notes for debugging
if [ -n "${NOTES:-}" ]; then
    debug_log "First 100 chars of notes: ${NOTES:0:100}"
else
    debug_log "Notes is empty"
fi

# Validate input
if [ -z "${NOTES:-}" ]; then
    show_error "Error: No input detected. Please copy meeting notes to clipboard."
    exit 1
fi

# Update progress
if [[ "$IS_RAYCAST" == "true" ]]; then
    show_progress "20%"
fi

# Check if the clipboard content is from Granola
if ! is_granola_content "$NOTES"; then
    log_debug_to_raycast "ERROR: Content failed Granola validation"
    handle_error $ERROR_INVALID_INPUT "Copy meeting summary first"
fi
log_debug_to_raycast "Content passed Granola validation"

# Extract information from notes
debug_log "Extracting information from notes"

# Extract title
TITLE=$(extract_title "$NOTES")
debug_log "Extracted title: $TITLE"

# Extract date
DATE=$(extract_date "$NOTES")
debug_log "Extracted date: $DATE"

# Extract date line for inclusion in note
DATE_LINE=$(extract_date_line "$NOTES")
debug_log "Extracted date line: $DATE_LINE"

# Extract transcript URL if enabled
TRANSCRIPT_URL=""
if [ "$INCLUDE_TRANSCRIPT_URL" = true ]; then
    TRANSCRIPT_URL=$(extract_transcript_url "$NOTES")
    info_log "Extracted transcript URL: $TRANSCRIPT_URL"
fi

# Extract attendees
ATTENDEES=$(extract_attendees "$NOTES")
debug_log "Extracted attendees: $ATTENDEES"

# Extract topics if auto-extraction is enabled
TOPICS=""
if [ "$AUTO_EXTRACT_TOPICS" = true ]; then
    TOPICS=$(extract_topics "$NOTES")
    if [ -n "$TOPICS" ]; then
        info_log "Auto-extracted topics: $TOPICS"
    else
        debug_log "No topics auto-extracted"
    fi
fi

# Format the notes with the extracted information
debug_log "Formatting notes"
FORMATTED_CONTENT=$(format_notes "$NOTES" "$DATE_LINE" "$TITLE" "$ATTENDEES" "$PERSONAL_NOTES_ARG")
log_debug_to_raycast "Formatted content"

# Create front matter
debug_log "Creating front matter"
FRONT_MATTER=$(create_front_matter "$TITLE" "$(format_date "$DATE" "front_matter")" "$TRANSCRIPT_URL" "$ATTENDEES" "$TOPICS")
log_debug_to_raycast "Created front matter"

# Combine front matter and formatted content
debug_log "Combining front matter and formatted content"
FULL_CONTENT="${FRONT_MATTER}

${FORMATTED_CONTENT}"
log_debug_to_raycast "Combined front matter and formatted content"

# Update progress
if [[ "$IS_RAYCAST" == "true" ]]; then
    show_progress "60%"
fi

# Generate filename from title
debug_log "Generating filename from title: $TITLE"
CLEAN_TITLE=$(clean_title_for_filename "$TITLE")
FILENAME="${CLEAN_TITLE}.md"
log_debug_to_raycast "Generated filename: $FILENAME"

# Check if Obsidian path exists
if [ ! -d "$OBSIDIAN_PATH" ]; then
    log_debug_to_raycast "ERROR: Obsidian path not found: $OBSIDIAN_PATH"
    handle_error $ERROR_OBSIDIAN_PATH_NOT_FOUND
fi
log_debug_to_raycast "Obsidian path verified: $OBSIDIAN_PATH"

# Update progress
if [[ "$IS_RAYCAST" == "true" ]]; then
    show_progress "80%"
fi

# Check for duplicates
if [ "$FORCE_SAVE" = "false" ] && check_duplicate "$FULL_CONTENT" "$TITLE" "$DATE" "$TRANSCRIPT_URL"; then
    log_debug_to_raycast "Duplicate detected, skipping save"
    exit 0
fi
log_debug_to_raycast "No duplicates found, proceeding with save"

# Save note to Obsidian
if ! save_note "$FILENAME" "$FULL_CONTENT"; then
    log_debug_to_raycast "ERROR: Failed to save note to Obsidian"
    handle_error $ERROR_FILE_CREATION_FAILED
fi
log_debug_to_raycast "Note saved successfully to: $OBSIDIAN_PATH/$FILENAME"

# Store hash of the newly created note
store_note_hash "$FILENAME"
log_debug_to_raycast "Note hash stored for duplicate detection"

# Update daily note if configured
if [ "$UPDATE_DAILY_NOTE" = true ]; then
    if [ "$INCLUDE_PERSONAL_NOTES_IN_DAILY" = true ]; then
        PERSONAL_NOTES_FOR_DAILY="$PERSONAL_NOTES_ARG"
    else
        PERSONAL_NOTES_FOR_DAILY=""
    fi
    if ! update_daily_note "$DATE" "$TITLE" "$FILENAME" "$MEETING_TIME" "$PERSONAL_NOTES_FOR_DAILY"; then
        log_debug_to_raycast "ERROR: Failed to update daily note"
        handle_error $ERROR_DAILY_NOTE_UPDATE_FAILED
    fi
    log_debug_to_raycast "Daily note updated successfully"
fi

# Update progress
if [[ "$IS_RAYCAST" == "true" ]]; then
    show_progress "100%"
fi

# Show success notification
if [[ "$DEBUG_MODE" == "true" ]]; then
    show_success "Meeting summary saved to Obsidian (debug mode)"
    debug_log "Note saved with debug mode enabled"
else
    show_success "Meeting summary saved to Obsidian"
fi

if [[ "$FORCE_SAVE" == "true" ]]; then
    debug_log "Note saved with force mode enabled (bypassed duplicate check)"
fi

log_debug_to_raycast "Process completed successfully"

exit 0
