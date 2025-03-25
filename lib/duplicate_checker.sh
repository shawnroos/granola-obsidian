#!/bin/bash
# Duplicate detection functions for Granola to Obsidian script

# Source the configuration file
SCRIPT_DIR="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/config.sh"

# Check if a note with the same content already exists
check_duplicate_content() {
    # Skip if disabled in config
    if [ "$CHECK_CONTENT" != "true" ]; then
        return 1
    fi

    local notes_content="$1"
    local content_hash=$(echo "$notes_content" | md5 | cut -d' ' -f1)
    
    # Create a hash directory if it doesn't exist
    mkdir -p "$HASH_STORAGE_DIR"
    
    # Create a hash file if it doesn't exist
    local hash_file="$HASH_STORAGE_DIR/content_hashes.txt"
    touch "$hash_file"
    
    # Check if hash exists in file
    if grep -q "$content_hash" "$hash_file"; then
        local existing_file=$(grep "$content_hash" "$hash_file" | cut -d':' -f2)
        debug_log "Duplicate note detected with hash: $content_hash"
        debug_log "Existing file: $existing_file"
        return 0  # Duplicate found
    else
        # We'll store the hash and filename after successfully creating the note
        debug_log "New note hash: $content_hash"
        # Store hash temporarily for later use
        echo "$content_hash" > "$HASH_STORAGE_DIR/temp_hash.txt"
        return 1  # No duplicate
    fi
}

# Store hash of newly created note
store_note_hash() {
    # Skip if content checking is disabled
    if [ "$CHECK_CONTENT" != "true" ]; then
        return 0
    fi

    local filename="$1"
    local temp_hash_file="$HASH_STORAGE_DIR/temp_hash.txt"
    
    if [ -f "$temp_hash_file" ]; then
        local content_hash=$(cat "$temp_hash_file")
        local hash_file="$HASH_STORAGE_DIR/content_hashes.txt"
        echo "$content_hash:$filename" >> "$hash_file"
        rm "$temp_hash_file"
        debug_log "Stored hash for new note: $filename"
    fi
}

# Check if a note with the same title and date already exists
check_duplicate_by_title_date() {
    # Skip if disabled in config
    if [ "$CHECK_TITLE_DATE" != "true" ]; then
        return 1
    fi

    local title="$1"
    local date="$2"
    
    # Clean title for filename
    local clean_title=$(clean_title_for_filename "$title")
    local filename="${clean_title}_${date}.md"
    local full_path="$OBSIDIAN_PATH/$filename"
    
    if [ -f "$full_path" ]; then
        debug_log "Note already exists: $filename"
        return 0  # Duplicate found
    else
        debug_log "No existing note found with title and date: $filename"
        return 1  # No duplicate
    fi
}

# Check if a note with the same transcript URL already exists
check_duplicate_by_url() {
    # Skip if disabled in config or no URL checking
    if [ "$CHECK_URL" != "true" ]; then
        return 1
    fi

    local url="$1"
    
    if [ -z "$url" ]; then
        return 1  # No URL provided, can't check
    fi
    
    # Search for URL in existing notes
    local existing_file=$(grep -l "$url" "$OBSIDIAN_PATH"/*.md 2>/dev/null | head -n 1)
    
    if [ -n "$existing_file" ]; then
        debug_log "Note with same URL already exists: $(basename "$existing_file")"
        return 0  # Duplicate found
    else
        debug_log "No existing note found with URL: $url"
        return 1  # No duplicate
    fi
}

# Comprehensive duplicate check using multiple methods
check_duplicate() {
    # Skip all checks if duplicate detection is disabled
    if [ "$ENABLE_DUPLICATE_DETECTION" != "true" ]; then
        return 1
    fi

    local notes_content="$1"
    local title="$2"
    local date="$3"
    local url="$4"
    
    # First check by title and date (fastest)
    if check_duplicate_by_title_date "$title" "$date"; then
        show_warning "A note with the same title and date already exists."
        return 0
    fi
    
    # Then check by URL if available
    if [ -n "$url" ] && check_duplicate_by_url "$url"; then
        show_warning "A note with the same transcript URL already exists."
        return 0
    fi
    
    # Finally check by content hash (most thorough)
    if check_duplicate_content "$notes_content"; then
        show_warning "A note with similar content already exists."
        return 0
    fi
    
    # No duplicates found
    return 1
}
