#!/bin/bash
# Notification utilities for Granola to Obsidian script

# Source the configuration file
SCRIPT_DIR="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/config.sh"

# Function to show a notification
show_notification() {
    local message="$1"
    local type="${2:-info}"  # Default to info type
    
    debug_log "Showing notification: $message (type: $type)"
    
    # Check if we're running in Raycast
    if [[ "$IS_RAYCAST" == "true" ]]; then
        case "$type" in
            success)
                echo "✅ $message"
                ;;
            error)
                echo "❌ $message"
                ;;
            warning)
                echo "⚠️ $message"
                ;;
            info|*)
                echo "ℹ️ $message"
                ;;
        esac
    else
        # Standard terminal output
        case "$type" in
            success)
                echo "✅ $message"
                ;;
            error)
                echo "❌ $message"
                ;;
            warning)
                echo "⚠️ $message"
                ;;
            info|*)
                echo "ℹ️ $message"
                ;;
        esac
    fi
}

# Function to show a success notification
show_success() {
    local message="$1"
    show_notification "$message" "success"
}

# Function to show an error notification
show_error() {
    local message="$1"
    show_notification "$message" "error"
}

# Function to show a warning notification
show_warning() {
    local message="$1"
    show_notification "$message" "warning"
}

# Function to show an info notification
show_info() {
    local message="$1"
    show_notification "$message" "info"
}
