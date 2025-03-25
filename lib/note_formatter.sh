#!/bin/bash
# Note formatting functions for Granola to Obsidian script

# Source the configuration file
SCRIPT_DIR="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/config.sh"

# Debug logging function
debug_log() {
    # Only log if debug mode is enabled via environment variable or config
    if [ "${DEBUG_MODE:-false}" = true ] || [ "$ENABLE_DEBUG_LOGGING" = true ]; then
        local message="$1"
        echo "DEBUG: $message" >&2
        
        # Also log to file if specified
        if [ -n "$LOG_FILE" ]; then
            printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$message" >> "$LOG_FILE"
        fi
    fi
}

# Check if content is from Granola
is_granola_content() {
    local notes="$1"
    local is_granola=false

    # Check for Granola transcript URL pattern
    if echo "$notes" | grep -q 'https://notes\.granola\.ai/p/'; then
        is_granola=true
        debug_log "Granola transcript URL found, content is from Granola"
    # Check for Slack URL pattern (common for shared meeting notes)
    elif echo "$notes" | grep -q 'https://.*slack\.com/'; then
        is_granola=true
        debug_log "Slack URL found, treating as valid content"
    # Check for other Granola-specific patterns if URL not found
    elif echo "$notes" | grep -q -i 'granola'; then
        is_granola=true
        debug_log "Granola keyword found in content"
    # Check for typical Granola note structure (title followed by date and attendees)
    elif echo "$notes" | head -n 3 | grep -q -E '^# .*|^[A-Za-z]+,?\s+[A-Za-z]+\s+[0-9]{1,2}'; then
        is_granola=true
        debug_log "Content structure matches Granola format"
    # Check for any URL pattern if lenient validation is enabled
    elif [ "$LENIENT_VALIDATION" = true ] && echo "$notes" | grep -q -E 'https?://[^ ]+'; then
        is_granola=true
        debug_log "URL found and lenient validation enabled, treating as valid content"
    # If lenient validation is enabled and content is not empty, accept it
    elif [ "$LENIENT_VALIDATION" = true ] && [ -n "$notes" ] && [ "$notes" != " " ]; then
        is_granola=true
        debug_log "Lenient validation enabled, accepting non-empty content"
        show_warning "Content doesn't match Granola format but processing anyway (lenient mode)"
    fi

    if [ "$is_granola" = true ]; then
        return 0
    else
        debug_log "Content does not appear to be from Granola"
        return 1
    fi
}

# Extract title from notes
extract_title() {
    local notes="$1"
    local title=""
    
    # Try to extract from first line if it's a markdown heading
    if [[ "$(echo "$notes" | head -n 1)" =~ ^#[[:space:]]+(.*) ]]; then
        title="${BASH_REMATCH[1]}"
        debug_log "Extracted title from heading: $title"
    else
        # Try to find the first line that looks like a title
        title=$(echo "$notes" | grep -v '^$' | head -n 1)
        debug_log "Extracted title from first non-empty line: $title"
    fi
    
    # Clean up the title - remove any leading # characters and whitespace
    title=$(echo "$title" | sed 's/^#*[[:space:]]*//' | sed 's/[[:space:]]*$//')
    
    echo "$title"
}

# Clean title for use in filename
clean_title_for_filename() {
    local title="$1"
    
    # Add DEBUG_ prefix to filename if in debug mode and not already added
    if [ "${DEBUG_MODE:-false}" = true ] && [ -n "${DEBUG_PREFIX:-}" ]; then
        # Only add prefix if it's not already there
        if [[ "$title" != "${DEBUG_PREFIX}"* ]]; then
            title="${DEBUG_PREFIX}${title}"
            debug_log "Added debug prefix to filename: $title"
        fi
    fi
    
    # Remove any special characters that aren't allowed in filenames
    local clean_title=$(echo "$title" | sed 's/[^a-zA-Z0-9 ]/_/g' | sed 's/__*/_/g' | sed 's/^_//' | sed 's/_$//')
    
    # Replace spaces with underscores
    clean_title=$(echo "$clean_title" | sed 's/ /_/g')
    
    debug_log "Cleaned title for filename: $clean_title"
    echo "$clean_title"
}

# Extract transcript URL from notes
extract_transcript_url() {
    local notes="$1"
    
    # First try to extract a plain URL with the full ID
    local url=$(echo "$notes" | grep -o 'https://notes\.granola\.ai/p/[a-zA-Z0-9_-]*' | head -n 1)
    
    # If not found, try to extract from markdown link format
    if [ -z "$url" ]; then
        # Extract from markdown link format [text](url)
        url=$(echo "$notes" | grep -o '\[.*\](https://notes\.granola\.ai/p/[a-zA-Z0-9_-]*)' | grep -o 'https://notes\.granola\.ai/p/[a-zA-Z0-9_-]*' | head -n 1)
        if [ -n "$url" ]; then
            debug_log "Extracted transcript URL from markdown link: $url"
        fi
    fi
    
    if [ -n "$url" ]; then
        debug_log "Extracted transcript URL: $url"
    else
        debug_log "No transcript URL found"
    fi
    
    # Clean the URL to remove any trailing characters that aren't part of the URL
    url=$(echo "$url" | sed 's/[]\)].*$//')
    
    echo "$url"
}

# Format notes for Obsidian
format_notes() {
    local notes="$1"
    local date_line="$2"
    local title="$3"
    local attendees="$4"
    local personal_notes="$5"
    
    # Add DEBUG_ prefix to title if in debug mode
    if [ "${DEBUG_MODE:-false}" = true ] && [ -n "${DEBUG_PREFIX:-}" ]; then
        title="${DEBUG_PREFIX}${title}"
        debug_log "Added debug prefix to title: $title"
    fi
    
    # Remove the title line and date line from the notes
    local content=$(echo "$notes" | sed '1d' | sed "s/$date_line//")
    
    # Use standard markdown formatting
    local formatted_content="# $title

> [!info] Meeting Information
> Date: $date_line"
    
    # Always include attendees in the callout if they exist
    if [ -n "$attendees" ]; then
        formatted_content="${formatted_content}
> Attendees: $attendees"
    fi

    # Add personal notes callout if provided
    if [ -n "$personal_notes" ]; then
        formatted_content="${formatted_content}

> [!note] Personal Notes
> ${personal_notes//
/
> }"
        debug_log "Added personal notes callout"
    fi

    # If attendees are in the content, remove them to prevent duplication
    if [ -n "$attendees" ]; then
        # Remove any line that starts with "Attendees:" from the content
        content=$(echo "$content" | sed '/^Attendees:/d')
    fi

    formatted_content="${formatted_content}

$content"
    
    echo "$formatted_content"
}

# Create front matter for Obsidian
create_front_matter() {
    local title="$1"
    local date="$2"
    local url="$3"
    local attendees="$4"
    local topics="$5"
    
    # Add DEBUG_ prefix to front matter title if in debug mode
    local display_title="$title"
    if [ "${DEBUG_MODE:-false}" = true ] && [ -n "${DEBUG_PREFIX:-}" ]; then
        # Only add prefix if it's not already there
        if [[ "$display_title" != "${DEBUG_PREFIX}"* ]]; then
            display_title="${DEBUG_PREFIX}${display_title}"
            debug_log "Added debug prefix to front matter title: $display_title"
        fi
    fi
    
    # Clean up the title again to ensure no hash symbols
    display_title=$(echo "$display_title" | sed 's/^#*[[:space:]]*//' | sed 's/[[:space:]]*$//')
    
    # Start with basic front matter
    local front_matter="---
title: \"$display_title\"
date: $date
type: meeting"
    
    # Add transcript URL if available
    if [ -n "$url" ]; then
        # Clean the URL to ensure no markdown formatting
        url=$(echo "$url" | sed 's/[]\[]//g' | sed 's/[()]//g')
        front_matter="${front_matter}
transcript: \"$url\""
    fi
    
    # Add attendees as tags
    if [ -n "$attendees" ]; then
        # Clean up attendees to remove leading/trailing spaces
        attendees=$(echo "$attendees" | sed 's/^ *//' | sed 's/ *$//')
        front_matter="${front_matter}
attendees: 
$(echo "$attendees" | sed 's/,[[:space:]]*/,/g' | sed 's/,/\n/g' | sed 's/^/  - /')"
    fi
    
    # Add topics if available
    if [ -n "$topics" ]; then
        # Clean up topics to remove leading/trailing spaces
        topics=$(echo "$topics" | sed 's/^ *//' | sed 's/ *$//')
        front_matter="${front_matter}
topics:
$(echo "$topics" | sed 's/,[[:space:]]*/,/g' | sed 's/,/\n/g' | sed 's/^/  - /')"
    fi
    
    # Close front matter
    front_matter="${front_matter}
---"
    
    debug_log "Created front matter for note"
    echo "$front_matter"
}
