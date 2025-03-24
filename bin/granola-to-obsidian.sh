#!/bin/bash
# Main script for converting Granola notes to Obsidian

# @raycast.schemaVersion 1
# @raycast.title Granola Notes
# @raycast.mode silent

# Get the script directory
SCRIPT_DIR="$(dirname "$(dirname "$0")")"

# Source configuration and modules
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/date_utils.sh"
source "$SCRIPT_DIR/lib/attendee_parser.sh"
source "$SCRIPT_DIR/lib/note_formatter.sh"
source "$SCRIPT_DIR/lib/obsidian_integration.sh"
source "$SCRIPT_DIR/lib/duplicate_checker.sh"
source "$SCRIPT_DIR/lib/notification_utils.sh"

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

# Get input from clipboard or stdin
if [ -t 0 ]; then
    # If no input is piped, use clipboard
    NOTES=$(pbpaste)
else
    # If input is piped, use that
    NOTES=$(cat -)
fi

# Validate input
if [ -z "$NOTES" ]; then
    handle_error $ERROR_INVALID_INPUT "Clipboard is empty"
fi

debug_log "Raw notes:"
debug_log "$NOTES"
debug_log "---"

# Check if the clipboard content is from Granola
if ! is_granola_content "$NOTES"; then
    handle_error $ERROR_INVALID_INPUT "Copy meeting summary first"
fi

# Extract title
TITLE=$(extract_title "$NOTES")
if [ -z "$TITLE" ]; then
    handle_error $ERROR_INVALID_INPUT "Could not extract title from notes"
fi

# Extract date
DATE_LINE=$(echo "$NOTES" | grep -E -o '^[A-Za-z]+,?\s+[0-9]{1,2}\s+[A-Za-z]+\s+[0-9]{2,4}|^[A-Za-z]+,?\s+[A-Za-z]+\s+[0-9]{1,2},?\s+[0-9]{2,4}' | head -n 1)
debug_log "Date line found: $DATE_LINE"

# Extract date in DDMMYY format
DATE=$(extract_date "$NOTES")
if [ $? -ne 0 ] || [ -z "$DATE" ]; then
    handle_error $ERROR_DATE_EXTRACTION_FAILED "Could not extract date from notes"
fi

debug_log "Extracted date: $DATE"

# Only proceed if we have a valid date
if [ ${#DATE} -eq 6 ]; then
    # Format date for front matter
    FRONT_MATTER_DATE=$(format_date "$DATE" "front_matter")
    if [ $? -ne 0 ] || [ -z "$FRONT_MATTER_DATE" ]; then
        handle_error $ERROR_DATE_EXTRACTION_FAILED "Could not format date for front matter"
    fi
    debug_log "Front matter date: $FRONT_MATTER_DATE"

    # Clean title for filename
    CLEAN_TITLE=$(clean_title "$TITLE")
    FILENAME="${CLEAN_TITLE}_${DATE}.md"
    debug_log "Creating file: $FILENAME"

    # Extract transcript URL
    TRANSCRIPT_URL=$(extract_transcript_url "$NOTES")

    # Check for duplicate notes
    if check_duplicate "$NOTES" "$TITLE" "$DATE" "$TRANSCRIPT_URL"; then
        echo "Note already exists. Skipping creation."
        exit 0
    fi

    # Extract attendees
    ATTENDEES=$(extract_attendees "$NOTES")
    
    # Extract topics
    TOPICS=$(extract_topics "$NOTES")

    # Format the note content
    FORMATTED_CONTENT=$(format_notes "$NOTES" "$DATE_LINE" "$TITLE" "$ATTENDEES")
    
    # Create front matter
    FRONT_MATTER=$(create_front_matter "$TITLE" "$FRONT_MATTER_DATE" "$TRANSCRIPT_URL" "$ATTENDEES" "$TOPICS")
    
    # Combine front matter and content
    FULL_CONTENT="${FRONT_MATTER}

${FORMATTED_CONTENT}"

    # Save note to Obsidian
    if ! save_note "$FILENAME" "$FULL_CONTENT"; then
        handle_error $ERROR_FILE_CREATION_FAILED "Failed to save note to Obsidian"
    fi
    
    # Store hash of the newly created note
    store_note_hash "$FILENAME"

    # Extract meeting time
    MEETING_TIME=$(extract_meeting_time "$NOTES")
    
    # Update daily note
    if ! update_daily_note "$DATE" "$TITLE" "$FILENAME" "$MEETING_TIME"; then
        debug_log "Warning: Failed to update daily note, but note was saved"
    fi

    debug_log "Finished processing"
    show_success "Meeting summary saved to Obsidian"
else
    handle_error $ERROR_DATE_EXTRACTION_FAILED "Could not extract valid date from notes"
fi
