#!/bin/bash
# Attendee parsing functions for Granola to Obsidian script

# Source the configuration file
source "$(dirname "$(dirname "$0")")/config.sh"

# Extract attendees from text
# Usage: extract_attendees "text with attendee information"
extract_attendees() {
    local text="$1"
    local all_attendees=""
    
    # Check for explicit "Attendees:" format first
    if echo "$text" | grep -q -i "Attendees:"; then
        debug_log "Found explicit 'Attendees:' format"
        local attendees_line=$(echo "$text" | grep -i "Attendees:" | head -n 1)
        local explicit_attendees=$(echo "$attendees_line" | sed -E 's/.*Attendees:[ \t]*(.+)/\1/')
        debug_log "Extracted explicit attendees: $explicit_attendees"
        
        if [ -n "$explicit_attendees" ]; then
            echo "$explicit_attendees"
            return 0
        fi
    fi
    
    # Granola always has attendees in the first line of the body, not the title
    # Skip the title (first line) and any blank lines, then get the first content line
    local body_first_line=$(echo "$text" | sed '1d' | grep -v "^$" | head -n 1)
    debug_log "First line of body (attendees): $body_first_line"
    
    # Extract email addresses - these are the most reliable indicators
    local emails=$(echo "$body_first_line" | grep -E -o '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u)
    debug_log "Extracted emails from first line of body:"
    debug_log "$emails"
    
    # Look for proper names (First Last) and exclude common meeting topics
    local names=$(echo "$body_first_line" | grep -E -o '[A-Z][a-z]+ [A-Z][a-z]+' | grep -v -E "($EXCLUDE_WORDS)" | sort -u)
    
    # Also look for names with middle initials or multiple capital letters (e.g., "John D. Smith" or "John McDonald")
    local names_complex=$(echo "$body_first_line" | grep -E -o '[A-Z][a-z]+ ([A-Z]\. )?[A-Z][a-zA-Z]+' | grep -v -E '^(Mon|Tue|Wed|Thu|Fri|Sat|Sun)' | grep -v -E "($EXCLUDE_WORDS)" | sort -u)
    
    debug_log "Extracted names from first line of body:"
    debug_log "$names"
    debug_log "Extracted complex names from first line of body:"
    debug_log "$names_complex"
    
    # Combine all attendees (emails and names)
    all_attendees=$(echo "$emails
$names
$names_complex" | grep -v '^$' | sort -u | tr '\n' ',' | sed 's/,$//')
    
    debug_log "Combined all attendees (emails and names): $all_attendees"
    
    # If we have attendees, use them
    if [ -n "$all_attendees" ]; then
        echo "$all_attendees"
        return 0
    else
        # If still no attendees found, check if there are any email-like strings in the entire notes
        debug_log "No attendees found in first line of body, checking for emails in entire notes"
        local emails_fallback=$(echo "$text" | grep -E -o '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u)
        if [ -n "$emails_fallback" ]; then
            echo "$(echo "$emails_fallback" | tr '\n' ',' | sed 's/,$//')"
            return 0
        fi
    fi
    
    # Return empty string if no attendees found
    echo ""
    return 0
}

# Extract topics from meeting notes
# Usage: extract_topics "meeting notes text"
extract_topics() {
    local text="$1"
    local topics_list=""
    
    # Look for headings (lines starting with #) or bold text (**text**)
    local topics=$(echo "$text" | grep -E '^\s*#+\s+|^\s*\*\*.*\*\*$' | sed -E 's/^\s*#+\s+//g; s/^\s*\*\*//g; s/\*\*$//g' | grep -v "^$" | sort -u)
    debug_log "Extracted topics:"
    debug_log "$topics"
    
    # Format topics for front matter - remove any remaining markdown formatting
    if [ -n "$topics" ]; then
        topics_list=$(echo "$topics" | sed -E 's/^#+\s*//g; s/^###\s*//g; s/^##\s*//g; s/^#\s*//g' | tr '\n' ',' | sed 's/,$//')
        debug_log "Topics list: $topics_list"
    fi
    
    echo "$topics_list"
    return 0
}

# Clean up attendees list
# Usage: clean_attendees "attendees_string"
clean_attendees() {
    local attendees="$1"
    
    # Clean up attendees list - remove any empty entries
    echo "$attendees" | sed 's/^,//g; s/,,/,/g'
}
