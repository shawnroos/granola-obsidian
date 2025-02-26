#!/bin/bash

set -e  # Exit on error

GRANOLA_PATH="/Users/shawnroos/Library/Mobile Documents/iCloud~md~obsidian/Documents/Rooshub/Notes/Granola"
BACKUP_DIR="/tmp/granola_backup_$(date +%Y%m%d_%H%M%S)"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to backup a file before modifying
backup_file() {
    local file="$1"
    local backup_path="$BACKUP_DIR/$(basename "$file")"
    cp "$file" "$backup_path"
    echo "Backed up $file to $backup_path"
}

# Function to extract clean title from content
get_clean_title() {
    local content="$1"
    # Try to get title from content after frontmatter
    echo "$content" | awk '
        BEGIN { in_front=0; found=0 }
        /^---$/ { in_front=!in_front; next }
        !in_front && /^# / && !found { print substr($0, 3); found=1; exit }
    ' | sed 's/[[:space:]]*$//'
}

# Function to extract transcript URL
get_transcript_url() {
    local content="$1"
    echo "$content" | grep -o 'https://notes\.granola\.ai/p/[a-zA-Z0-9-]*' | head -n 1
}

# Function to extract attendees
get_attendees() {
    local content="$1"
    local attendees_line
    # Look for date line with attendees
    attendees_line=$(echo "$content" | awk '
        BEGIN { in_front=0; found=0 }
        /^---$/ { in_front=!in_front; next }
        !in_front && !found && /^[A-Z][a-z][a-z], [0-9]{1,2} [A-Z][a-z]{2} [0-9]{2}.*·/ {
            sub(/^[^·]*·[ ]*/, "")
            gsub(/[[:space:]]*$/, "")
            print
            found=1
            exit
        }
    ')
    
    if [ -n "$attendees_line" ]; then
        # Extract and format emails
        echo "$attendees_line" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -E '[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}' | sort -u | tr '\n' ',' | sed 's/,$//'
    fi
}

# Function to get content without frontmatter and duplicates
get_clean_content() {
    local content="$1"
    local title="$2"
    echo "$content" | awk -v title="$title" '
        BEGIN { 
            in_front=0       # Are we in frontmatter
            found_title=0    # Have we found the main title
            found_content=0  # Have we found any real content
            empty_lines=0    # Count of consecutive empty lines
            first_front=1    # Is this the first frontmatter block
        }
        
        # Handle frontmatter blocks
        /^---$/ { 
            if (first_front) {
                in_front=1
                first_front=0
                next
            }
            in_front=!in_front
            next
        }
        
        # Skip content in frontmatter
        in_front { next }
        
        # Count empty lines
        /^[[:space:]]*$/ {
            empty_lines++
            if (found_content && empty_lines <= 2) print
            next
        }
        
        # Reset empty lines counter for non-empty lines
        /[^[:space:]]/ { empty_lines=0 }
        
        # Skip attendees line and the date line before it
        /^[A-Z][a-z][a-z], [0-9]{1,2} [A-Z][a-z]{2} [0-9]{2}.*·.*@/ { next }
        # Skip date line without attendees
        /^[A-Z][a-z][a-z], [0-9]{1,2} [A-Z][a-z]{2} [0-9]{2}$/ { next }
        
        # Handle title line
        /^# / {
            gsub(/^# /, "")
            if ($0 == title) {
                if (!found_title) {
                    found_title=1
                    found_content=1
                    print "# " title
                }
                next
            }
            # Keep other headings that are not the title
            found_content=1
            print "# " $0
            next
        }
        
        # Skip frontmatter-like lines
        /^(title|date|type|transcript|attendees):/ { next }
        
        # Print content after finding title
        { 
            found_content=1
            print 
        }
    '
}

# Function to fix a note's metadata
fix_note() {
    local file="$1"
    local content
    local title
    local transcript
    local attendees
    local date
    local temp_file
    local clean_content

    echo "Processing $file..."
    
    # Backup the file first
    backup_file "$file"
    
    # Read file content
    content=$(cat "$file")
    
    # Get base filename without date suffix
    base_name=$(basename "$file" | sed 's/_[0-9]\{8\}\.md$//' | sed 's/\.md$//' | sed 's/^The *//' | sed 's/[[:space:]]*$//')
    
    # Try to get title from content, fallback to filename
    title=$(get_clean_title "$content")
    if [[ -z "$title" ]]; then
        title="$base_name"
    fi
    
    # Extract all metadata before cleaning content
    transcript=$(get_transcript_url "$content")
    attendees=$(get_attendees "$content")
    
    # Extract date from filename or content
    if [[ $file =~ [0-9]{8} ]]; then
        date=$(echo "$file" | grep -o '[0-9]\{8\}')
        date=$(date -j -f "%d%m%Y" "$date" "+%Y-%m-%d" 2>/dev/null)
    else
        date=$(date -j -f "- %b %d, %Y" "- $(echo "$file" | grep -o "[A-Z][a-z]\+ [0-9]\+, [0-9]\{4\}")" "+%Y-%m-%d" 2>/dev/null)
    fi
    
    # If date extraction failed, use file modification time
    if [ -z "$date" ]; then
        date=$(date -r "$file" "+%Y-%m-%d")
    fi

    # Get clean content without frontmatter duplicates
    clean_content=$(get_clean_content "$content" "$title")
    
    # Create new content with fixed metadata
    temp_file=$(mktemp)
    echo "---
title: $title
date: $date
type: granola
transcript: ${transcript:-}
attendees: [${attendees:-}]
---

$clean_content" > "$temp_file"

    # Verify the temp file exists and has content
    if [ ! -s "$temp_file" ]; then
        echo "Error: Generated file is empty for $file"
        rm -f "$temp_file"
        return 1
    fi

    # Only update if content changed and verification passed
    if ! cmp -s "$temp_file" "$file"; then
        cp "$temp_file" "$file"  # Use cp instead of mv for safer file handling
        echo "Updated metadata for $file"
    else
        echo "No changes needed for $file"
    fi
    
    rm -f "$temp_file"
}

echo "Creating backup in $BACKUP_DIR..."

# First pass: collect all transcript URLs
echo "Collecting transcript URLs..."
transcript_file=$(mktemp)
find "$GRANOLA_PATH" -type f -name "*.md" -print0 | while IFS= read -r -d '' file; do
    transcript=$(get_transcript_url "$(cat "$file")")
    if [[ -n "$transcript" ]]; then
        echo "$transcript|$file" >> "$transcript_file"
    fi
done

# Second pass: find and remove duplicates
echo "Checking for duplicates..."
sort "$transcript_file" | while IFS='|' read -r transcript file; do
    if [[ -n "$transcript" ]]; then
        count=$(grep -c "^$transcript|" "$transcript_file")
        if [[ $count -gt 1 ]]; then
            # Get all files with this transcript URL
            grep "^$transcript|" "$transcript_file" | cut -d'|' -f2 | while read -r duplicate_file; do
                if [[ "$file" != "$duplicate_file" ]]; then
                    echo "Found duplicate: $file and $duplicate_file share transcript $transcript"
                    # Keep the newer file
                    if [[ "$file" -nt "$duplicate_file" && -f "$duplicate_file" ]]; then
                        echo "Keeping $file, removing $duplicate_file"
                        mv "$duplicate_file" "$BACKUP_DIR/$(basename "$duplicate_file").duplicate"
                    elif [[ -f "$file" ]]; then
                        echo "Keeping $duplicate_file, removing $file"
                        mv "$file" "$BACKUP_DIR/$(basename "$file").duplicate"
                        break
                    fi
                fi
            done
        fi
    fi
done

# Clean up temporary file
rm -f "$transcript_file"

# Fix metadata in all remaining notes
echo -e "\nFixing metadata in notes..."
find "$GRANOLA_PATH" -type f -name "*.md" -print0 | while IFS= read -r -d '' file; do
    if ! fix_note "$file"; then
        echo "Error processing $file - skipping"
        # Restore from backup if needed
        cp "$BACKUP_DIR/$(basename "$file")" "$file"
    fi
done

echo -e "\nDone! Backup files are in $BACKUP_DIR"
