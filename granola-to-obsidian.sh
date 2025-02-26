#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Granola Notes
# @raycast.mode silent

debug_log() {
    printf "DEBUG: %s\n" "$1" >&2
}

# Format dates consistently
format_date() {
    local input_date="$1"  # Expected format: DDMMYY
    local format_type="$2" # Can be: daily_note_file, daily_note_header, front_matter, filename

    # Extract components
    local day=$(echo "$input_date" | cut -c1-2)
    local month_num=$(echo "$input_date" | cut -c3-4)
    local year=$(echo "$input_date" | cut -c5-6)
    
    # Convert month number to name
    local month_name
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
    esac

    # Get day of week using date command
    local dow=$(date -j -f "%d%m%y" "${day}${month_num}${year}" "+%A")
    
    case "$format_type" in
        daily_note_file)
            # Format: "26 February '25.md"
            printf "%d %s '%s.md" "$((10#$day))" "$month_name" "$year"
            ;;
        daily_note_header)
            # Format: "Wednesday, February 26"
            printf "%s, %s %d" "$dow" "$month_name" "$((10#$day))"
            ;;
        front_matter)
            # Format: "2025-02-26"
            printf "20%s-%s-%s" "$year" "$month_num" "$day"
            ;;
        filename)
            # Format: "20250226"
            printf "20%s%s%s" "$year" "$month_num" "$day"
            ;;
    esac
}

# Write note content to file
write_note() {
    local title="$1"
    local date="$2"
    local transcript_url="$3"
    local attendees="$4"
    local notes="$5"
    local output_file="$6"

    # Format date for front matter
    local front_matter_date=$(format_date "$date" "front_matter")
    
    # Create front matter
    cat > "$output_file" << EOL
---
title: $title
date: $front_matter_date
type: granola
transcript: $transcript_url
attendees: [$attendees]
---

$notes
EOL
}

# Get clipboard and save to Obsidian
LOG_FILE="/tmp/granola-debug.log"
echo "=== Starting new conversion $(date) ===" > "$LOG_FILE"

if [ -t 0 ]; then
    # If no input is piped, use clipboard
    NOTES=$(pbpaste)
else
    # If input is piped, use that
    NOTES=$(cat -)
fi

echo "DEBUG: Raw notes:" >> "$LOG_FILE"
echo "$NOTES" >> "$LOG_FILE"
echo "---" >> "$LOG_FILE"

TITLE=$(echo "$NOTES" | head -n 1 | sed 's/^# *//')  # Remove leading # and spaces
echo "DEBUG: Title: $TITLE" >> "$LOG_FILE"

# Enhanced date detection - try multiple patterns
# First try to find a line that looks like a date with various formats
DATE_LINE=$(echo "$NOTES" | grep -E -o '^[A-Za-z]+,?\s+[0-9]{1,2}\s+[A-Za-z]+\s+[0-9]{2,4}|^[A-Za-z]+,?\s+[A-Za-z]+\s+[0-9]{1,2},?\s+[0-9]{2,4}' | head -n 1)

# If that fails, try to find any line that contains day, month, year patterns
if [ -z "$DATE_LINE" ]; then
    echo "DEBUG: First date pattern failed, trying alternative patterns" >> "$LOG_FILE"
    DATE_LINE=$(echo "$NOTES" | grep -E -o '[A-Za-z]+day,?\s+[A-Za-z]+\s+[0-9]{1,2},?\s+[0-9]{2,4}|[A-Za-z]+,?\s+[0-9]{1,2}\s+[A-Za-z]+\s+[0-9]{2,4}' | head -n 1)
fi

# If still no date, try to find any line with month names and numbers
if [ -z "$DATE_LINE" ]; then
    echo "DEBUG: Second date pattern failed, trying looser patterns" >> "$LOG_FILE"
    DATE_LINE=$(echo "$NOTES" | grep -E -i "January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Oct|Nov|Dec" | grep -E "[0-9]{1,2}" | head -n 1)
fi

echo "DEBUG: Date line found: $DATE_LINE" >> "$LOG_FILE"

# Convert date to DDMMYY format
DATE=$(echo "$DATE_LINE" | awk '
    BEGIN {
        split("January February March April May June July August September October November December", months)
        split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", month_abbrev)
        for (i=1; i<=12; i++) {
            month_num[tolower(months[i])] = sprintf("%02d", i)
            month_num[tolower(month_abbrev[i])] = sprintf("%02d", i)
        }
    }
    {
        day = ""
        month = ""
        year = ""
        
        # First pass - find components
        for (i=1; i<=NF; i++) {
            # Remove any commas and single quotes
            gsub(/[,'']/, "", $i)
            printf "DEBUG: Processing word: %s\n", $i >> "'$LOG_FILE'"
            
            # Day number (only if we havent found a day yet)
            if ($i ~ /^[0-9]{1,2}$/ && day == "") {
                day = sprintf("%02d", $i)
                printf "DEBUG: Found day: %s\n", day >> "'$LOG_FILE'"
            }
            # Month name (full or abbreviated) - case insensitive
            else if (tolower($i) in month_num) {
                month = month_num[tolower($i)]
                printf "DEBUG: Found month: %s\n", month >> "'$LOG_FILE'"
            }
            # Year - handle both 2 and 4 digit years (take the last number as year)
            else if ($i ~ /^[0-9]{2,4}$/) {
                if (length($i) == 4) {
                    year = substr($i, 3, 2)  # Take last 2 digits
                } else {
                    year = $i
                }
                printf "DEBUG: Found year: %s\n", year >> "'$LOG_FILE'"
            }
        }
        
        if (length(day) == 2 && length(month) == 2 && length(year) == 2) {
            # Output in DDMMYY format
            printf "%s%s%s", day, month, year
        } else {
            printf "ERROR: Invalid date components (day=%s, month=%s, year=%s)\n", day, month, year >> "'$LOG_FILE'"
            exit 1
        }
    }
')

echo "DEBUG: Extracted date: $DATE" >> "$LOG_FILE"

# Only proceed if we have a valid date
if [ ${#DATE} -eq 6 ]; then
    FRONT_MATTER_DATE="20${DATE:4:2}-${DATE:2:2}-${DATE:0:2}"
    echo "DEBUG: Front matter date: $FRONT_MATTER_DATE" >> "$LOG_FILE"

    CLEAN_TITLE=$(echo "$TITLE" | tr -cd '[:alnum:][:space:]-')
    FILENAME="The $CLEAN_TITLE_$DATE.md"
    echo "DEBUG: Creating file: $FILENAME" >> "$LOG_FILE"

    # Extract transcript URL
    TRANSCRIPT_URL=$(echo "$NOTES" | grep -o 'https://notes\.granola\.ai/p/[a-zA-Z0-9-]*' | head -n 1)
    echo "DEBUG: Transcript URL: $TRANSCRIPT_URL" >> "$LOG_FILE"

    # Enhanced attendees detection
    # First look for lines near the date line
    ATTENDEES_SECTION=$(echo "$NOTES" | grep -A 10 -E "^[A-Za-z]{3,}, [0-9]{1,2} [A-Za-z]{3,} [0-9]{2,4}|^[A-Za-z]{3,}, [A-Za-z]{3,} [0-9]{1,2}, [0-9]{2,4}")
    echo "DEBUG: Attendees section:" >> "$LOG_FILE"
    echo "$ATTENDEES_SECTION" >> "$LOG_FILE"
    
    # Extract names and emails with improved patterns
    # Look for proper names (First Last) and email addresses
    NAMES=$(echo "$ATTENDEES_SECTION" | grep -E -o '[A-Z][a-z]+ [A-Z][a-z]+' | sort -u)
    # Also look for names with middle initials or multiple capital letters (e.g., "John D. Smith" or "John McDonald")
    NAMES_COMPLEX=$(echo "$ATTENDEES_SECTION" | grep -E -o '[A-Z][a-z]+ ([A-Z]\. )?[A-Z][a-zA-Z]+' | grep -v -E '^(Mon|Tue|Wed|Thu|Fri|Sat|Sun)' | sort -u)
    EMAILS=$(echo "$ATTENDEES_SECTION" | grep -E -o '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u)
    
    echo "DEBUG: Extracted names:" >> "$LOG_FILE"
    echo "$NAMES" >> "$LOG_FILE"
    echo "DEBUG: Extracted complex names:" >> "$LOG_FILE"
    echo "$NAMES_COMPLEX" >> "$LOG_FILE"
    echo "DEBUG: Extracted emails:" >> "$LOG_FILE"
    echo "$EMAILS" >> "$LOG_FILE"
    
    # Combine names and emails
    ATTENDEES=$(echo "$NAMES
$NAMES_COMPLEX
$EMAILS" | sort -u | tr '\n' ',' | sed 's/,$//')
    
    echo "DEBUG: Combined attendees: $ATTENDEES" >> "$LOG_FILE"
    
    # If no attendees found, try a broader search
    if [ -z "$ATTENDEES" ]; then
        echo "DEBUG: No attendees found, trying broader search" >> "$LOG_FILE"
        ATTENDEES=$(echo "$NOTES" | grep -E -o '[A-Z][a-z]+ [A-Z][a-z]+|[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u | tr '\n' ',' | sed 's/,$//')
        echo "DEBUG: Broader search attendees: $ATTENDEES" >> "$LOG_FILE"
    fi

    OBSIDIAN_PATH="/Users/shawnroos/Library/Mobile Documents/iCloud~md~obsidian/Documents/Rooshub/Notes/Granola"
    DAILY_PATH="/Users/shawnroos/Library/Mobile Documents/iCloud~md~obsidian/Documents/Rooshub/Notes/Dailys"
    TEMPLATE_PATH="/Users/shawnroos/Library/Mobile Documents/iCloud~md~obsidian/Documents/Rooshub/Templates/Daily Note.md"

    # Save Granola note
    mkdir -p "$OBSIDIAN_PATH"
    echo "DEBUG: Saving Granola note to $OBSIDIAN_PATH/$FILENAME" >> "$LOG_FILE"
    
    # Create front matter with attendees
    FRONT_MATTER="---
title: $TITLE
date: $FRONT_MATTER_DATE
type: granola
transcript: $TRANSCRIPT_URL"

    # Only add attendees if we found some
    if [ -n "$ATTENDEES" ]; then
        FRONT_MATTER="$FRONT_MATTER
attendees: [$ATTENDEES]"
    fi
    
    FRONT_MATTER="$FRONT_MATTER
---

# $TITLE

$NOTES"

    echo "$FRONT_MATTER" > "$OBSIDIAN_PATH/$FILENAME"

    # Handle daily note
    # Format date for daily note (25 February '25)
    DAILY_NOTE_NAME="$(printf "%d %s '%s" "$((10#${DATE:0:2}))" "$(echo "$DATE_LINE" | awk '
        BEGIN {
            split("January February March April May June July August September October November December", months)
            split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", month_abbrev)
            for (i=1; i<=12; i++) {
                month_long[tolower(month_abbrev[i])] = months[i]
                month_long[tolower(months[i])] = months[i]
            }
        }
        {
            for (i=1; i<=NF; i++) {
                gsub(/[,'']/, "", $i)
                if (tolower($i) in month_long) {
                    print month_long[tolower($i)]
                    exit
                }
            }
        }
    ')" "${DATE:4:2}").md"

    echo "DEBUG: Daily note name: $DAILY_NOTE_NAME" >> "$LOG_FILE"
    DAILY_NOTE="$DAILY_PATH/$DAILY_NOTE_NAME"

    # Create daily note if it doesn't exist
    if [ ! -f "$DAILY_NOTE" ]; then
        echo "DEBUG: Creating daily note: $DAILY_NOTE" >> "$LOG_FILE"
        cp "$TEMPLATE_PATH" "$DAILY_NOTE"
        
        # Add Meetings section to the new daily note
        echo "
# 📅 Meetings
---" >> "$DAILY_NOTE"
        echo "DEBUG: Added Meetings section to new daily note" >> "$LOG_FILE"
    else
        echo "DEBUG: Daily note already exists: $DAILY_NOTE" >> "$LOG_FILE"
        # Check if Meetings section exists, if not add it
        if ! grep -q "^# 📅 Meetings" "$DAILY_NOTE"; then
            echo "DEBUG: Adding Meetings section to daily note: $DAILY_NOTE" >> "$LOG_FILE"
            echo "
# 📅 Meetings
---" >> "$DAILY_NOTE"
        fi
    fi

    # Add link under Meetings section - look for the line after "## Meetings" and "---"
    echo "DEBUG: Adding link to daily note: $DAILY_NOTE" >> "$LOG_FILE"
    TEMP_FILE=$(mktemp)
    
    # Format the current time for the meeting entry
    CURRENT_TIME=$(date "+%H:%M")
    
    # Create a nicely formatted link with time
    MEETING_LINK="- $CURRENT_TIME - [[Granola/The $CLEAN_TITLE_$DATE|$TITLE]]"
    
    # Check if the link already exists to avoid duplicates
    if grep -q "$CLEAN_TITLE_$DATE" "$DAILY_NOTE"; then
        echo "DEBUG: Link already exists in daily note, skipping" >> "$LOG_FILE"
    else
        echo "DEBUG: Adding new meeting link: $MEETING_LINK" >> "$LOG_FILE"
        awk -v link="$MEETING_LINK" '
            /^# 📅 Meetings/{p=1}
            p&&/^---/{print;print link;p=0;next}
            {print}
        ' "$DAILY_NOTE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$DAILY_NOTE"
    fi

    # Clean up temp file if it still exists
    [ -f "$TEMP_FILE" ] && rm "$TEMP_FILE"

    echo "DEBUG: Finished processing" >> "$LOG_FILE"
    # Format the daily note date for the success message
    DAILY_DATE=$(format_date "$DATE" "daily_note_header")
    echo "✓ Saved to Obsidian and added to daily note: $DAILY_DATE"
else
    echo "ERROR: Could not extract valid date from notes" >> "$LOG_FILE"
    exit 1
fi
