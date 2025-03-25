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
# @raycast.argument1 { "type": "text", "name": "notes", "placeholder": "Paste meeting notes here (or leave empty to use clipboard)", "optional": true }
# @raycast.argument2 { "type": "text", "name": "personal_notes", "placeholder": "Add personal notes (will appear in a callout)", "optional": true }

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
        echo "Usage: $(basename "$0") [OPTIONS] [NOTES]"
        echo "Process meeting notes from Granola and save to Obsidian."
        echo ""
        echo "Options:"
        echo "  -h, --help                  Show this help message and exit"
        echo "  -d, --debug                 Enable debug mode"
        echo "  -f, --force                 Force save even if duplicate is detected"
        echo "  -n, --notes TEXT            Meeting notes content"
        echo "  -p, --personal-notes TEXT   Personal notes to add as a callout"
        echo ""
        echo "If NOTES is not provided via arguments, the script will try to read from stdin or clipboard."
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
            -n|--notes)
                if [ -n "$2" ]; then
                    NOTES_ARG="$2"
                    shift 2
                else
                    echo "Error: --notes requires an argument."
                    exit 1
                fi
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
            *)
                # If no explicit option is given, assume it's the notes content
                if [ -z "$NOTES_ARG" ]; then
                    NOTES_ARG="$1"
                fi
                shift
                ;;
        esac
    done
else
    # In Raycast mode, get arguments from Raycast
    NOTES_ARG="$1"
    PERSONAL_NOTES_ARG="$2"
    
    # Log input source in Raycast mode
    if [ -n "$NOTES_ARG" ]; then
        debug_log "Using notes from Raycast argument (length: ${#NOTES_ARG})"
    else
        debug_log "No notes provided via Raycast argument, using clipboard"
        NOTES_ARG=$(pbpaste)
        debug_log "Clipboard content length: ${#NOTES_ARG}"
    fi
    
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
debug_log "  NOTES_ARG: ${NOTES_ARG:0:20}..."
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

# Get input from clipboard or stdin
debug_log "Starting input processing"

# First check if stdin has data (for piped input)
if [ ! -t 0 ]; then
    # Read from stdin into a variable
    STDIN_CONTENT=$(cat -)
    debug_log "Stdin is not a terminal, checking for piped content"
    
    if [ -n "$STDIN_CONTENT" ]; then
        NOTES="$STDIN_CONTENT"
        debug_log "Using notes from stdin (length: ${#NOTES} characters)"
        log_debug_to_raycast "Using notes from stdin (length: ${#NOTES} characters)"
    else
        debug_log "Stdin was detected but is empty"
        log_debug_to_raycast "Stdin was detected but is empty"
    fi
else
    debug_log "No stdin detected (not piped)"
    log_debug_to_raycast "No stdin detected (not piped)"
fi

# If we don't have notes from stdin, check command arguments
if [ -z "${NOTES:-}" ] && [ -n "$NOTES_ARG" ]; then
    NOTES="$NOTES_ARG"
    debug_log "Using notes from command argument (length: ${#NOTES} characters)"
    log_debug_to_raycast "Using notes from command argument (length: ${#NOTES} characters)"
fi

# If we still don't have notes, try clipboard as last resort
if [ -z "${NOTES:-}" ]; then
    CLIPBOARD_CONTENT=$(pbpaste)
    
    if [ -n "$CLIPBOARD_CONTENT" ]; then
        NOTES="$CLIPBOARD_CONTENT"
        debug_log "Using notes from clipboard (length: ${#NOTES} characters)"
        log_debug_to_raycast "Using notes from clipboard (length: ${#NOTES} characters)"
    else
        debug_log "Clipboard is empty"
        log_debug_to_raycast "Clipboard is empty"
    fi
fi

# Log first 100 characters of notes for debugging
if [ -n "${NOTES:-}" ]; then
    PREVIEW="${NOTES:0:100}"
    debug_log "Raw notes:"
    debug_log "$NOTES"
    debug_log "---"
    debug_log "First 100 characters of notes: $PREVIEW..."
    log_debug_to_raycast "First 100 characters of notes: $PREVIEW..."
fi

# Validate input
if [ -z "${NOTES:-}" ]; then
    debug_log "ERROR: No input detected from any source (stdin, arguments, or clipboard)"
    show_error "Error: No input detected. Please copy meeting notes to clipboard or pipe them to the script."
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

# Extract title
TITLE=$(extract_title "$NOTES")
if [ -z "$TITLE" ]; then
    log_debug_to_raycast "ERROR: Could not extract title from notes"
    handle_error $ERROR_INVALID_INPUT "Could not extract title from notes"
fi
log_debug_to_raycast "Extracted title: $TITLE"

# Extract date
DATE_LINE=$(echo "$NOTES" | grep -E -o '^[A-Za-z]+,?\s+[0-9]{1,2}\s+[A-Za-z]+\s+[0-9]{2,4}|^[A-Za-z]+,?\s+[A-Za-z]+\s+[0-9]{1,2},?\s+[0-9]{2,4}' | head -n 1)
debug_log "Date line found: $DATE_LINE"
log_debug_to_raycast "Date line found: $DATE_LINE"

# Update progress
if [[ "$IS_RAYCAST" == "true" ]]; then
    show_progress "30%"
fi

# Extract date in DDMMYY format
DATE=$(extract_date "$NOTES")
if [ $? -ne 0 ]; then
    log_debug_to_raycast "ERROR: Failed to extract date from notes"
    handle_error $ERROR_DATE_EXTRACTION_FAILED
fi
log_debug_to_raycast "Extracted date: $DATE"

# Format date for front matter
FRONT_MATTER_DATE=$(format_date "$DATE" "front_matter")
if [ $? -ne 0 ] || [ -z "$FRONT_MATTER_DATE" ]; then
    log_debug_to_raycast "ERROR: Could not format date for front matter"
    handle_error $ERROR_DATE_EXTRACTION_FAILED
fi
log_debug_to_raycast "Front matter date: $FRONT_MATTER_DATE"

# Extract meeting time if available
MEETING_TIME=$(extract_meeting_time "$NOTES")
if [ -n "$MEETING_TIME" ]; then
    debug_log "Meeting time found: $MEETING_TIME"
    log_debug_to_raycast "Meeting time found: $MEETING_TIME"
else
    debug_log "No meeting time found"
    log_debug_to_raycast "No meeting time found"
fi

# Extract attendees
ATTENDEES=$(extract_attendees "$NOTES")
log_debug_to_raycast "Extracted attendees: $ATTENDEES"

# Extract topics if enabled
TOPICS=""
if [ "$AUTO_EXTRACT_TOPICS" = true ]; then
    TOPICS=$(extract_topics "$NOTES")
    log_debug_to_raycast "Extracted topics: $TOPICS"
fi

# Extract transcript URL if available
TRANSCRIPT_URL=$(extract_transcript_url "$NOTES")
if [ -n "$TRANSCRIPT_URL" ]; then
    debug_log "Transcript URL found: $TRANSCRIPT_URL"
    log_debug_to_raycast "Transcript URL found: $TRANSCRIPT_URL"
else
    debug_log "No transcript URL found"
    log_debug_to_raycast "No transcript URL found"
fi

# Update progress
if [[ "$IS_RAYCAST" == "true" ]]; then
    show_progress "60%"
fi

# Format notes for Obsidian
FORMATTED_CONTENT=$(format_notes "$NOTES" "$DATE_LINE" "$TITLE" "$ATTENDEES")
log_debug_to_raycast "Notes formatted for Obsidian"

# Create front matter for Obsidian
FRONT_MATTER=$(create_front_matter "$TITLE" "$FRONT_MATTER_DATE" "$TRANSCRIPT_URL" "$ATTENDEES" "$TOPICS")
log_debug_to_raycast "Front matter created for Obsidian"

# Combine front matter and formatted content
FULL_CONTENT="${FRONT_MATTER}

${FORMATTED_CONTENT}"
log_debug_to_raycast "Combined front matter and formatted content"

# Add personal notes if provided
if [ -n "$PERSONAL_NOTES_ARG" ]; then
    PERSONAL_NOTES_CALLOUT="
> [!note] Personal Notes
> ${PERSONAL_NOTES_ARG//
/
> }"
    FULL_CONTENT+="

${PERSONAL_NOTES_CALLOUT}"
    log_debug_to_raycast "Added personal notes to the note"
fi

# Create filename
CLEAN_TITLE=$(clean_title "$TITLE")
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
    if ! update_daily_note "$DATE" "$TITLE" "$FILENAME" "$MEETING_TIME"; then
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
