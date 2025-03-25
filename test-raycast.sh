#!/bin/bash

# Test script for Raycast integration
# This script helps diagnose issues with the Raycast integration

# Set environment variables for testing
export IS_RAYCAST=true
export ENABLE_DEBUG_LOGGING=true

# Display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS] [TEST_FILE]"
    echo ""
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  -d, --debug          Enable debug mode (default: true)"
    echo "  -f, --force          Force save even if duplicate (default: false)"
    echo "  -c, --clipboard      Use clipboard instead of test file"
    echo ""
    echo "If TEST_FILE is not provided and --clipboard is not specified,"
    echo "a sample meeting note will be used."
    exit 0
}

# Default values
DEBUG="true"
FORCE="false"
USE_CLIPBOARD="false"
TEST_FILE=""

# Parse command line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_usage
            ;;
        -d|--debug)
            DEBUG="true"
            shift
            ;;
        -f|--force)
            FORCE="true"
            shift
            ;;
        -c|--clipboard)
            USE_CLIPBOARD="true"
            shift
            ;;
        -*)
            echo "Unknown option: $1"
            show_usage
            ;;
        *)
            # If it's not an option, it's the test file
            TEST_FILE="$1"
            shift
            ;;
    esac
done

# Function to run the test with specified arguments
run_test() {
    local input="$1"
    local debug="$2"
    local force="$3"
    
    echo "Running Raycast script with arguments:"
    echo "  Input: ${input:0:20}... (${#input} characters)"
    echo "  Debug: $debug"
    echo "  Force: $force"
    
    echo "$input" | /Users/shawnroos/.raycast/scripts/granola-to-obsidian.sh "" "$debug" "$force"
}

# Determine the input source
if [ -n "$TEST_FILE" ]; then
    echo "Using test file: $TEST_FILE"
    
    if [ ! -f "$TEST_FILE" ]; then
        echo "❌ Test file not found: $TEST_FILE"
        exit 1
    fi
    
    # Run the Raycast script with the test file contents
    FILE_CONTENT=$(cat "$TEST_FILE")
    run_test "$FILE_CONTENT" "$DEBUG" "$FORCE"
    
elif [ "$USE_CLIPBOARD" = "true" ]; then
    echo "Using clipboard content..."
    CLIPBOARD_CONTENT=$(pbpaste)
    
    if [ -z "$CLIPBOARD_CONTENT" ]; then
        echo "❌ Clipboard is empty"
        exit 1
    fi
    
    run_test "$CLIPBOARD_CONTENT" "$DEBUG" "$FORCE"
    
else
    # No test file provided, use a sample meeting note
    echo "Using sample meeting note..."
    
    SAMPLE_NOTE="# Sample Meeting - Test User and Team

Mon, 24 Mar 25 · Test User

### Attendees
- Test User
- Team Member 1
- Team Member 2

### Topics
- Topic 1
- Topic 2
- Topic 3

### Action Items
- Action 1
- Action 2

https://notes.granola.ai/p/sample-meeting-$(date +%s)"

    run_test "$SAMPLE_NOTE" "$DEBUG" "$FORCE"
fi

# Check exit code
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Test completed successfully"
else
    echo "❌ Test failed with exit code: $EXIT_CODE"
fi

# Show debug log
echo "Debug log (last 20 lines):"
tail -n 20 /tmp/granola-debug.log
