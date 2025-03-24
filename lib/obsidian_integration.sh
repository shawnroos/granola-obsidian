#!/bin/bash
# Obsidian integration functions for Granola to Obsidian script

# Source the configuration file
SCRIPT_DIR="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/config.sh"

# Save note to Obsidian
# Usage: save_note "filename" "content"
save_note() {
    local filename="$1"
    local content="$2"
    
    # Create directory if it doesn't exist
    if [ ! -d "$OBSIDIAN_PATH" ]; then
        debug_log "Creating Obsidian directory: $OBSIDIAN_PATH"
        if ! mkdir -p "$OBSIDIAN_PATH"; then
            debug_log "Failed to create Obsidian directory: $OBSIDIAN_PATH"
            return $ERROR_OBSIDIAN_PATH_NOT_FOUND
        fi
    fi
    
    # Save note to file
    debug_log "Saving note to $OBSIDIAN_PATH/$filename"
    if ! echo "$content" > "$OBSIDIAN_PATH/$filename"; then
        debug_log "Failed to save note to $OBSIDIAN_PATH/$filename"
        return $ERROR_FILE_CREATION_FAILED
    fi
    
    return 0
}

# Create or update daily note
# Usage: update_daily_note "date" "title" "filename" "meeting_time"
update_daily_note() {
    local date="$1"
    local title="$2"
    local filename="$3"
    local meeting_time="$4"
    
    debug_log "Formatting date for daily note: $date"
    
    # First try to use the format_date function
    local daily_note_name="$(format_date "$date" "daily_note_file")"
    
    # Fallback if format_date fails or returns empty string
    if [ -z "$daily_note_name" ]; then
        debug_log "format_date failed or returned empty, using fallback method"
        
        # Extract components manually
        local day=$(echo "$date" | cut -c1-2)
        local month_num=$(echo "$date" | cut -c3-4)
        local year=$(echo "$date" | cut -c5-6)
        
        # Remove leading zeros
        day=$((10#$day))
        
        # Convert month number to name
        case "$month_num" in
            01) month_name="January" ;;
            02) month_name="February" ;;
            03) month_name="March" ;;
            04) month_name="April" ;;
            05) month_name="May" ;;
            06) month_name="June" ;;
            07) month_name="July" ;;
            08) month_name="August" ;;
            09) month_name="September" ;;
            10) month_name="October" ;;
            11) month_name="November" ;;
            12) month_name="December" ;;
            *) month_name="Unknown" ;;
        esac
        
        daily_note_name="${day} ${month_name} '${year}.md"
        debug_log "Fallback daily note name: $daily_note_name"
    fi

    debug_log "Daily note name: $daily_note_name"
    local daily_note="$DAILY_PATH/$daily_note_name"

    # Generate heading based on configuration
    local heading_prefix=""
    for ((i=1; i<=$DAILY_NOTE_HEADING_LEVEL; i++)); do
        heading_prefix="${heading_prefix}#"
    done
    
    # Create the meetings heading
    local meetings_heading="${heading_prefix} ${DAILY_NOTE_MEETINGS_EMOJI} ${DAILY_NOTE_MEETINGS_HEADING}"
    debug_log "Using meetings heading: $meetings_heading"
    
    # Create daily note if it doesn't exist
    if [ ! -f "$daily_note" ]; then
        debug_log "Creating daily note: $daily_note"
        
        # Create directory if it doesn't exist
        if [ ! -d "$DAILY_PATH" ]; then
            debug_log "Creating daily notes directory: $DAILY_PATH"
            if ! mkdir -p "$DAILY_PATH"; then
                debug_log "Failed to create daily notes directory: $DAILY_PATH"
                return $ERROR_FILE_CREATION_FAILED
            fi
        fi
        
        # Copy template and replace date placeholder
        if [ -f "$TEMPLATE_PATH" ]; then
            # Get formatted date for the header (e.g., "Tuesday, February 25")
            local formatted_date=$(format_date "$date" "daily_note_header")
            
            # Copy template and replace date placeholder
            cat "$TEMPLATE_PATH" | sed "s/{{date:dddd, MMMM D}}/$formatted_date/g" > "$daily_note"
            
            # Check if Meetings section exists, if not add it
            if ! grep -q "^${heading_prefix} .*${DAILY_NOTE_MEETINGS_HEADING}" "$daily_note"; then
                debug_log "Adding Meetings section to daily note template"
                echo "
${meetings_heading}
---" >> "$daily_note"
            fi
            
            debug_log "Added Meetings section to new daily note"
        else
            # Create a basic daily note if template doesn't exist
            echo "# $(format_date "$date" "daily_note_header")

${heading_prefix} ✅ Tasks
---

${heading_prefix} 📝 Notes
---

${meetings_heading}
---
" > "$daily_note"
        fi
    else
        debug_log "Daily note already exists: $daily_note"
        
        # Check if any meetings heading exists (with different emoji or format)
        if ! grep -q "^${heading_prefix} .*${DAILY_NOTE_MEETINGS_HEADING}" "$daily_note"; then
            debug_log "Adding Meetings section to daily note: $daily_note"
            echo "
${meetings_heading}
---" >> "$daily_note"
        fi
    fi

    # Format the meeting link based on time availability
    local meeting_link
    if [ -z "$meeting_time" ]; then
        # Format the meeting link with a generic time indicator
        meeting_link=$(echo "$DAILY_NOTE_LINK_FORMAT" | 
            sed "s|{{EMOJI}}|${DAILY_NOTE_MEETINGS_EMOJI}|g" | 
            sed "s|{{FILENAME}}|${filename}|g" | 
            sed "s|{{TITLE}}|${title}|g")
    else
        # Format the meeting link with the actual time
        meeting_link=$(echo "$DAILY_NOTE_TIME_FORMAT" | 
            sed "s|{{TIME}}|${meeting_time}|g" | 
            sed "s|{{FILENAME}}|${filename}|g" | 
            sed "s|{{TITLE}}|${title}|g")
    fi
    
    debug_log "Adding new meeting link: $meeting_link"
    
    # Check if the link already exists to avoid duplicates
    if grep -q "${filename}" "$daily_note"; then
        debug_log "Link already exists in daily note, skipping"
        return 0
    fi
    
    # Create a temporary file
    local temp_file=$(mktemp /tmp/granola_daily_note.XXXXXX)
    
    # Try to find any meetings heading pattern
    local meetings_pattern="^${heading_prefix} .*${DAILY_NOTE_MEETINGS_HEADING}"
    
    # Add link under Meetings section
    awk -v pattern="$meetings_pattern" -v link="$meeting_link" '
        $0 ~ pattern {p=1}
        p && /^---/ {print; print link; p=0; next}
        {print}
    ' "$daily_note" > "$temp_file"
    
    # If the link wasn't added (no meetings section found), append it to the end
    if ! grep -q "${filename}" "$temp_file"; then
        debug_log "No meetings section with separator found, adding to end of file"
        echo "
${meetings_heading}
---
${meeting_link}" >> "$temp_file"
    fi
    
    # Move the temp file to the daily note
    mv "$temp_file" "$daily_note"
    
    # Clean up temp file if it still exists
    [ -f "$temp_file" ] && rm "$temp_file"
    
    return 0
}
