#!/bin/bash
# Note formatting functions for Granola to Obsidian script

# Source the configuration file
SCRIPT_DIR="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/config.sh"

# Check if content is from Granola
is_granola_content() {
    local notes="$1"
    local is_granola=false

    # Check for Granola transcript URL pattern
    if echo "$notes" | grep -q 'https://notes\.granola\.ai/p/'; then
        is_granola=true
        debug_log "Granola transcript URL found, content is from Granola"
    # Check for other Granola-specific patterns if URL not found
    elif echo "$notes" | grep -q -i 'granola'; then
        is_granola=true
        debug_log "Granola keyword found in content"
    # Check for typical Granola note structure (title followed by date and attendees)
    elif echo "$notes" | head -n 3 | grep -q -E '^# .*|^[A-Za-z]+,?\s+[A-Za-z]+\s+[0-9]{1,2}'; then
        is_granola=true
        debug_log "Content structure matches Granola format"
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
    
    # Clean up the title
    title=$(echo "$title" | sed 's/^# *//' | sed 's/[[:space:]]*$//')
    
    echo "$title"
}

# Clean title for filename
clean_title() {
    local title="$1"
    
    # Replace spaces with underscores and remove special characters
    local clean_title=$(echo "$title" | sed 's/[^a-zA-Z0-9 ]/_/g' | sed 's/[[:space:]]/_/g' | sed 's/__*/_/g')
    
    debug_log "Cleaned title for filename: $clean_title"
    echo "$clean_title"
}

# Extract transcript URL from notes
extract_transcript_url() {
    local notes="$1"
    local url=$(echo "$notes" | grep -o 'https://notes\.granola\.ai/p/[^[:space:]]*' | head -n 1)
    
    if [ -n "$url" ]; then
        debug_log "Extracted transcript URL: $url"
    else
        debug_log "No transcript URL found"
    fi
    
    echo "$url"
}

# Format notes for Obsidian
format_notes() {
    local notes="$1"
    local date_line="$2"
    local title="$3"
    local attendees="$4"
    
    # Remove the title line and date line from the notes
    local content=$(echo "$notes" | sed '1d' | sed "s/$date_line//")
    
    # Format the content based on configuration
    if [ "$USE_CALLOUTS" = true ]; then
        # Use Obsidian callouts for meeting info
        local formatted_content="# $title

> [!info] Meeting Information
> Date: $date_line
> Attendees: $attendees

$content"
    else
        # Use standard markdown formatting
        local formatted_content="# $title

**Date:** $date_line
**Attendees:** $attendees

$content"
    fi
    
    debug_log "Formatted notes for Obsidian"
    echo "$formatted_content"
}

# Create front matter for Obsidian
create_front_matter() {
    local title="$1"
    local date="$2"
    local url="$3"
    local attendees="$4"
    local topics="$5"
    
    # Start with basic front matter
    local front_matter="---
title: \"$title\"
date: $date
type: meeting"
    
    # Add transcript URL if available and configured
    if [ -n "$url" ] && [ "$INCLUDE_TRANSCRIPT_URL" = true ]; then
        front_matter="${front_matter}
transcript: \"$url\""
    fi
    
    # Add attendees as tags
    if [ -n "$attendees" ]; then
        front_matter="${front_matter}
attendees: 
$(echo "$attendees" | sed 's/,/\n/g' | sed 's/^/  - /')"
    fi
    
    # Add topics if available
    if [ -n "$topics" ]; then
        front_matter="${front_matter}
topics:
$(echo "$topics" | sed 's/,/\n/g' | sed 's/^/  - /')"
    fi
    
    # Close front matter
    front_matter="${front_matter}
---"
    
    debug_log "Created front matter for note"
    echo "$front_matter"
}
