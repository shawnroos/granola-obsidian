#!/bin/bash
# Date utilities for Granola to Obsidian script

# Source the configuration file
SCRIPT_DIR="$(dirname "$(dirname "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/config.sh"

# Debug logging function
debug_log() {
    # Only log if debug mode is enabled via environment variable or config
    if [ "${DEBUG_MODE:-false}" = true ] || [ "$ENABLE_DEBUG_LOGGING" = true ]; then
        local message="$1"
        local level="${2:-debug}"
        
        # Check if we should log this level based on LOG_LEVEL setting
        case "$LOG_LEVEL" in
            "debug")
                # Debug level logs everything
                ;;
            "info")
                # Info level doesn't log debug messages
                if [ "$level" = "debug" ]; then
                    return
                fi
                ;;
            "warning")
                # Warning level only logs warnings and errors
                if [ "$level" = "debug" ] || [ "$level" = "info" ]; then
                    return
                fi
                ;;
            "error")
                # Error level only logs errors
                if [ "$level" != "error" ]; then
                    return
                fi
                ;;
        esac
        
        # Format the log message with the level
        echo "${level^^}: $message" >&2
        
        # Also log to file if specified
        if [ -n "$LOG_FILE" ]; then
            printf "[%s] [%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "${level^^}" "$message" >> "$LOG_FILE"
        fi
    fi
}

# Helper functions for different log levels
info_log() {
    debug_log "$1" "info"
}

warning_log() {
    debug_log "$1" "warning"
}

error_log() {
    debug_log "$1" "error"
}

# Format date according to the specified format type
format_date() {
    local input_date="$1"
    local format_type="$2"
    
    # Validate input
    if [ -z "$input_date" ] || [ ${#input_date} -ne 6 ]; then
        debug_log "Invalid date format for input: $input_date"
        return $ERROR_DATE_EXTRACTION_FAILED
    fi
    
    # Extract day, month, year from DDMMYY format
    local day=${input_date:0:2}
    local month=${input_date:2:2}
    local year=${input_date:4:2}
    
    # Remove leading zeros
    day=$(echo "$day" | sed 's/^0//')
    month=$(echo "$month" | sed 's/^0//')
    
    # Convert month number to name
    local month_names=("" "January" "February" "March" "April" "May" "June" "July" "August" "September" "October" "November" "December")
    local month_name="${month_names[$month]}"
    
    # Format based on type
    case "$format_type" in
        "front_matter")
            # Use the configured format from config.sh
            if [[ "$DATE_FORMAT_FRONT_MATTER" == "YYYY-MM-DD" ]]; then
                echo "20$year-$(printf "%02d" $month)-$(printf "%02d" $day)"
            else
                # Default fallback
                echo "20$year-$(printf "%02d" $month)-$(printf "%02d" $day)"
            fi
            ;;
        "filename")
            echo "${input_date}"
            ;;
        "daily_note")
            # Use the configured format from config.sh
            if [[ "$DATE_FORMAT_DAILY_NOTE" == "D MMMM 'YY" ]]; then
                echo "$day $month_name '$year"
            else
                # Default fallback
                echo "$day $month_name '$year"
            fi
            ;;
        "daily_note_header")
            # Get day of week
            local date_string="20$year-$(printf "%02d" $month)-$(printf "%02d" $day)"
            local day_of_week=$(date -j -f "%Y-%m-%d" "$date_string" "+%A")
            echo "$day_of_week, $month_name $day"
            ;;
        *)
            debug_log "Unknown format type: $format_type"
            return $ERROR_DATE_EXTRACTION_FAILED
            ;;
    esac
    
    return 0
}

# Extract date from text in DDMMYY format
extract_date() {
    local text="$1"
    
    # Try to find a date line first
    local date_line=$(echo "$text" | grep -E -o '^[A-Za-z]+,?\s+[0-9]{1,2}\s+[A-Za-z]+\s+[0-9]{2,4}|^[A-Za-z]+,?\s+[A-Za-z]+\s+[0-9]{1,2},?\s+[0-9]{2,4}' | head -n 1)
    
    if [ -n "$date_line" ]; then
        debug_log "Found date line: $date_line"
        
        # Extract day, month, year from various formats
        local day month year
        
        # Try format: "Day, Month DD YYYY" or "Day, DD Month YYYY"
        if [[ $date_line =~ ([A-Za-z]+),?\ +([0-9]{1,2})\ +([A-Za-z]+)\ +([0-9]{2,4}) ]]; then
            day=${BASH_REMATCH[2]}
            month=${BASH_REMATCH[3]}
            year=${BASH_REMATCH[4]}
        elif [[ $date_line =~ ([A-Za-z]+),?\ +([A-Za-z]+)\ +([0-9]{1,2}),?\ +([0-9]{2,4}) ]]; then
            day=${BASH_REMATCH[3]}
            month=${BASH_REMATCH[2]}
            year=${BASH_REMATCH[4]}
        else
            debug_log "Could not parse date from line: $date_line"
            return $ERROR_DATE_EXTRACTION_FAILED
        fi
        
        # Pad day with leading zero if needed
        day=$(printf "%02d" $day)
        
        # Convert month name to number
        case $(echo "$month" | tr '[:upper:]' '[:lower:]') in
            "january"|"jan") month="01" ;;
            "february"|"feb") month="02" ;;
            "march"|"mar") month="03" ;;
            "april"|"apr") month="04" ;;
            "may") month="05" ;;
            "june"|"jun") month="06" ;;
            "july"|"jul") month="07" ;;
            "august"|"aug") month="08" ;;
            "september"|"sep") month="09" ;;
            "october"|"oct") month="10" ;;
            "november"|"nov") month="11" ;;
            "december"|"dec") month="12" ;;
            *)
                debug_log "Unknown month: $month"
                return $ERROR_DATE_EXTRACTION_FAILED
                ;;
        esac
        
        # Use last 2 digits of year
        if [ ${#year} -eq 4 ]; then
            year=${year:2:2}
        fi
        
        # Return date in DDMMYY format
        echo "${day}${month}${year}"
        return 0
    else
        # If no date line found, try to extract from URL or other patterns
        local url=$(echo "$text" | grep -o 'https://notes\.granola\.ai/p/[^[:space:]]*' | head -n 1)
        
        if [ -n "$url" ]; then
            debug_log "Trying to extract date from URL: $url"
            
            # Extract date from URL if possible (format varies)
            # This is a simplified approach and may need adjustment
            local today=$(date +"%d%m%y")
            echo "$today"
            return 0
        else
            # Last resort: use today's date
            debug_log "No date found, using today's date"
            local today=$(date +"%d%m%y")
            echo "$today"
            return 0
        fi
    fi
    
    debug_log "Failed to extract date"
    return $ERROR_DATE_EXTRACTION_FAILED
}

# Extract the date line from text (for display in notes)
extract_date_line() {
    local text="$1"
    
    # Try to find a date line first
    local date_line=$(echo "$text" | grep -E -o '^[A-Za-z]+,?\s+[0-9]{1,2}\s+[A-Za-z]+\s+[0-9]{2,4}|^[A-Za-z]+,?\s+[A-Za-z]+\s+[0-9]{1,2},?\s+[0-9]{2,4}' | head -n 1)
    
    if [ -n "$date_line" ]; then
        debug_log "Found date line: $date_line"
        echo "$date_line"
        return 0
    else
        # If no date line found, format today's date in a readable format
        debug_log "No date line found, using today's date"
        local today=$(date "+%A, %B %d %Y")
        echo "$today"
        return 0
    fi
}

# Extract time from text
extract_meeting_time() {
    local text="$1"
    local meeting_time=""
    
    # Try to extract meeting time from the text
    # Look for time patterns like "10:30 AM" or "2pm" or following "at"
    if [[ "$text" =~ at[[:space:]]+([0-9]{1,2}:[0-9]{2}[[:space:]]*[AP]M) ]]; then
        meeting_time="${BASH_REMATCH[1]}"
        debug_log "Extracted meeting time from 'at' pattern: $meeting_time"
    else
        meeting_time=$(echo "$text" | grep -E -o '[0-9]{1,2}:[0-9]{2}[[:space:]]*[AP]M' | head -n 1)
        
        # If no specific time format found, try more general pattern
        if [ -z "$meeting_time" ]; then
            meeting_time=$(echo "$text" | grep -E -o '[0-9]{1,2}:[0-9]{2}' | head -n 1)
        fi
    fi
    
    echo "$meeting_time"
}

# Check if a string is a valid date in DDMMYY format
is_valid_date() {
    local date_str="$1"
    
    # Check length
    if [ ${#date_str} -ne 6 ]; then
        return 1
    fi
    
    # Extract components
    local day=${date_str:0:2}
    local month=${date_str:2:2}
    local year=${date_str:4:2}
    
    # Check if components are numbers
    if ! [[ $day =~ ^[0-9]+$ ]] || ! [[ $month =~ ^[0-9]+$ ]] || ! [[ $year =~ ^[0-9]+$ ]]; then
        return 1
    fi
    
    # Check ranges
    if [ "$month" -lt 1 ] || [ "$month" -gt 12 ]; then
        return 1
    fi
    
    # Check days in month (simplified)
    local days_in_month=(0 31 29 31 30 31 30 31 31 30 31 30 31)
    if [ "$day" -lt 1 ] || [ "$day" -gt ${days_in_month[$month]} ]; then
        return 1
    fi
    
    return 0
}
