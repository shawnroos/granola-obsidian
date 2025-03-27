#!/bin/bash
# Common utility functions for Granola Scraper

# Source the configuration file
SCRIPT_DIR="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/config.sh"

# Enhanced debug logging with log levels
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Check if logging is enabled and log level is appropriate
    case "$level" in
        "debug")
            if [ "$ENABLE_DEBUG_LOGGING" = true ] && [[ "$LOG_LEVEL" == "debug" ]]; then
                echo "[$timestamp] [DEBUG] $message" >> "$LOG_FILE"
            fi
            ;;
        "info")
            if [ "$ENABLE_DEBUG_LOGGING" = true ] && [[ "$LOG_LEVEL" == "debug" || "$LOG_LEVEL" == "info" ]]; then
                echo "[$timestamp] [INFO] $message" >> "$LOG_FILE"
            fi
            ;;
        "warning")
            if [ "$ENABLE_DEBUG_LOGGING" = true ] && [[ "$LOG_LEVEL" == "debug" || "$LOG_LEVEL" == "info" || "$LOG_LEVEL" == "warning" ]]; then
                echo "[$timestamp] [WARNING] $message" >> "$LOG_FILE"
            fi
            ;;
        "error")
            if [ "$ENABLE_DEBUG_LOGGING" = true ]; then
                echo "[$timestamp] [ERROR] $message" >> "$LOG_FILE"
            fi
            ;;
    esac
}

# Backward compatibility for debug_log
debug_log() {
    log "debug" "$1"
}

# Check if a directory exists, create if it doesn't
ensure_directory_exists() {
    local dir_path="$1"
    
    if [ ! -d "$dir_path" ]; then
        log "info" "Creating directory: $dir_path"
        if ! mkdir -p "$dir_path"; then
            log "error" "Failed to create directory: $dir_path"
            return 1
        fi
    fi
    
    return 0
}

# Safely write content to a file
safe_write_to_file() {
    local file_path="$1"
    local content="$2"
    
    # Create parent directory if it doesn't exist
    local dir_path=$(dirname "$file_path")
    ensure_directory_exists "$dir_path"
    
    # Write to a temporary file first
    local temp_file=$(mktemp /tmp/granola_safe_write.XXXXXX)
    echo "$content" > "$temp_file"
    
    # Move the temporary file to the target location
    if ! mv "$temp_file" "$file_path"; then
        log "error" "Failed to write to file: $file_path"
        [ -f "$temp_file" ] && rm "$temp_file"
        return 1
    fi
    
    log "debug" "Successfully wrote to file: $file_path"
    return 0
}

# Generate a unique filename
generate_unique_filename() {
    local base_name="$1"
    local extension="$2"
    local dir_path="$3"
    local counter=1
    local filename="${base_name}.${extension}"
    
    while [ -f "${dir_path}/${filename}" ]; do
        filename="${base_name}_${counter}.${extension}"
        counter=$((counter + 1))
    done
    
    echo "$filename"
}

# Sanitize a string for use in filenames
sanitize_string() {
    local input="$1"
    local max_length="${2:-100}"
    
    # Replace spaces and special characters with underscores
    local sanitized=$(echo "$input" | sed 's/[^a-zA-Z0-9 ]/_/g' | sed 's/[[:space:]]/_/g' | sed 's/__*/_/g')
    
    # Truncate if too long
    if [ ${#sanitized} -gt "$max_length" ]; then
        sanitized="${sanitized:0:$max_length}"
    fi
    
    echo "$sanitized"
}

# Check if a string is empty or contains only whitespace
is_empty() {
    local string="$1"
    
    if [ -z "$string" ] || [[ "$string" =~ ^[[:space:]]*$ ]]; then
        return 0
    else
        return 1
    fi
}

# Extract text between markers
extract_between_markers() {
    local text="$1"
    local start_marker="$2"
    local end_marker="$3"
    
    echo "$text" | sed -n "/${start_marker}/,/${end_marker}/p" | sed "1d;$d"
}

# Trim whitespace from beginning and end of string
trim() {
    local var="$1"
    # Remove leading whitespace
    var="${var#"${var%%[![:space:]]*}"}"
    # Remove trailing whitespace
    var="${var%"${var##*[![:space:]]}"}"
    echo "$var"
}

# Add Raycast-specific logging and progress functions
log_debug_to_raycast() {
    if [ "$IS_RAYCAST" = true ]; then
        local message="$1"
        echo "DEBUG: $message" >&2
    fi
}

show_progress() {
    if [ "$IS_RAYCAST" = true ]; then
        local message="$1"
        echo "PROGRESS: $message" >&2
    fi
}
