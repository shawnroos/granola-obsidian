#!/bin/bash

# Granola Scraper Installation Script
# This script will guide you through the installation process for Granola Scraper

# Set text colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print banner
echo -e "${BLUE}"
echo "  _____                      _         _____                                "
echo " / ____|                    | |       / ____|                               "
echo "| |  __ _ __ __ _ _ __   ___| | __ _  | (___   ___ _ __ __ _ _ __   ___ _ __ "
echo "| | |_ | '__/ _\` | '_ \\ / _ \\ |/ _\` |  \\___ \\ / __| '__/ _\` | '_ \\ / _ \\ '__|"
echo "| |__| | | | (_| | | | | (_) | | (_| |  ____) | (__| | | (_| | |_) |  __/ |   "
echo " \\_____|_|  \\__,_|_| |_|\\___/|_|\\__,_| |_____/ \\___|_|  \\__,_| .__/ \\___|_|   "
echo "                                                             | |              "
echo "                                                             |_|              "
echo -e "${NC}"
echo -e "${GREEN}=== Granola Scraper Installation ===${NC}"
echo ""

# Check if script is run with sudo
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}Please do not run this script with sudo or as root.${NC}"
  exit 1
fi

# Detect script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check if Raycast is installed
if [ ! -d "$HOME/.raycast" ]; then
  echo -e "${RED}Raycast doesn't appear to be installed. Please install Raycast first.${NC}"
  echo "You can download it from https://raycast.com/"
  exit 1
fi

# Create Raycast scripts directory if it doesn't exist
if [ ! -d "$HOME/.raycast/scripts" ]; then
  echo -e "${BLUE}Creating Raycast scripts directory...${NC}"
  mkdir -p "$HOME/.raycast/scripts"
fi

# Function to prompt for directory path with validation
prompt_directory() {
  local prompt_text="$1"
  local default_value="$2"
  local var_name="$3"
  
  while true; do
    echo -e "${BLUE}$prompt_text${NC}"
    echo -e "${YELLOW}Default: $default_value${NC}"
    read -p "Enter path (or press Enter for default): " input_path
    
    # Use default if empty
    if [ -z "$input_path" ]; then
      input_path="$default_value"
    fi
    
    # Expand ~ to $HOME
    input_path="${input_path/#\~/$HOME}"
    
    # Check if directory exists
    if [ ! -d "$input_path" ]; then
      echo -e "${YELLOW}Directory doesn't exist. Create it? (y/n)${NC}"
      read -p "> " create_dir
      if [[ "$create_dir" =~ ^[Yy]$ ]]; then
        mkdir -p "$input_path"
        if [ $? -ne 0 ]; then
          echo -e "${RED}Failed to create directory. Please check permissions and try again.${NC}"
          continue
        fi
      else
        echo -e "${YELLOW}Please enter a valid directory path.${NC}"
        continue
      fi
    fi
    
    # Set the variable
    eval "$var_name=\"$input_path\""
    break
  done
}

# Function to prompt for yes/no with default
prompt_yes_no() {
  local prompt_text="$1"
  local default="$2"
  local var_name="$3"
  
  local default_text
  if [ "$default" = "true" ]; then
    default_text="Y/n"
  else
    default_text="y/N"
  fi
  
  while true; do
    echo -e "${BLUE}$prompt_text ${YELLOW}[$default_text]${NC}"
    read -p "> " input
    
    # Use default if empty
    if [ -z "$input" ]; then
      eval "$var_name=$default"
      break
    fi
    
    if [[ "$input" =~ ^[Yy]$ ]]; then
      eval "$var_name=true"
      break
    elif [[ "$input" =~ ^[Nn]$ ]]; then
      eval "$var_name=false"
      break
    else
      echo -e "${YELLOW}Please enter Y or N.${NC}"
    fi
  done
}

echo -e "${GREEN}Let's set up your Granola Scraper preferences:${NC}"
echo ""

# Prompt for Obsidian vault path
DEFAULT_OBSIDIAN_PATH="/Users/shawnroos/Library/Mobile Documents/iCloud~md~obsidian/Documents/Rooshub/Notes/Granola"
prompt_directory "Where would you like to save your Granola meeting notes in Obsidian?" "$DEFAULT_OBSIDIAN_PATH" "OBSIDIAN_PATH"

# Prompt for Daily notes path
DEFAULT_DAILY_PATH="/Users/shawnroos/Library/Mobile Documents/iCloud~md~obsidian/Documents/Rooshub/Notes/Dailys"
prompt_directory "Where are your Daily notes stored in Obsidian?" "$DEFAULT_DAILY_PATH" "DAILY_PATH"

# Prompt for Template path
DEFAULT_TEMPLATE_PATH="/Users/shawnroos/Library/Mobile Documents/iCloud~md~obsidian/Documents/Rooshub/Templates/Daily Note.md"
while true; do
  echo -e "${BLUE}Where is your Daily Note template located?${NC}"
  echo -e "${YELLOW}Default: $DEFAULT_TEMPLATE_PATH${NC}"
  read -p "Enter path (or press Enter for default): " TEMPLATE_PATH
  
  # Use default if empty
  if [ -z "$TEMPLATE_PATH" ]; then
    TEMPLATE_PATH="$DEFAULT_TEMPLATE_PATH"
  fi
  
  # Expand ~ to $HOME
  TEMPLATE_PATH="${TEMPLATE_PATH/#\~/$HOME}"
  
  # Check if file exists
  if [ ! -f "$TEMPLATE_PATH" ]; then
    echo -e "${YELLOW}Template file doesn't exist. Continue anyway? (y/n)${NC}"
    read -p "> " continue_anyway
    if [[ "$continue_anyway" =~ ^[Yy]$ ]]; then
      break
    else
      continue
    fi
  else
    break
  fi
done

# Prompt for logging settings
echo ""
echo -e "${GREEN}Logging Settings:${NC}"
DEFAULT_LOG_FILE="/tmp/granola-debug.log"
echo -e "${BLUE}Where would you like to store debug logs?${NC}"
echo -e "${YELLOW}Default: $DEFAULT_LOG_FILE${NC}"
read -p "Enter path (or press Enter for default): " LOG_FILE
if [ -z "$LOG_FILE" ]; then
  LOG_FILE="$DEFAULT_LOG_FILE"
fi

# Prompt for duplicate detection
echo ""
echo -e "${GREEN}Duplicate Detection Settings:${NC}"
prompt_yes_no "Enable duplicate detection to prevent adding the same meeting notes twice?" "true" "ENABLE_DUPLICATE_DETECTION"
if [ "$ENABLE_DUPLICATE_DETECTION" = "true" ]; then
  prompt_yes_no "Check for duplicates by title and date?" "true" "CHECK_TITLE_DATE"
  prompt_yes_no "Check for duplicates by URL?" "true" "CHECK_URL"
  prompt_yes_no "Check for duplicates by content?" "true" "CHECK_CONTENT"
  
  # Hash storage directory
  DEFAULT_HASH_DIR="/tmp/granola_hashes"
  echo -e "${BLUE}Where would you like to store content hashes for duplicate detection?${NC}"
  echo -e "${YELLOW}Default: $DEFAULT_HASH_DIR${NC}"
  read -p "Enter path (or press Enter for default): " HASH_STORAGE_DIR
  if [ -z "$HASH_STORAGE_DIR" ]; then
    HASH_STORAGE_DIR="$DEFAULT_HASH_DIR"
  fi
  # Create hash directory
  mkdir -p "$HASH_STORAGE_DIR"
fi

# Prompt for validation settings
echo ""
echo -e "${GREEN}Validation Settings:${NC}"
prompt_yes_no "Enable lenient validation (allows processing non-standard content)?" "true" "LENIENT_VALIDATION"

# Prompt for notification settings
echo ""
echo -e "${GREEN}Notification Settings:${NC}"
prompt_yes_no "Enable notifications?" "true" "ENABLE_NOTIFICATIONS"
if [ "$ENABLE_NOTIFICATIONS" = "true" ]; then
  prompt_yes_no "Play sound for success notifications?" "true" "NOTIFICATION_SUCCESS_SOUND"
  prompt_yes_no "Play sound for error notifications?" "true" "NOTIFICATION_ERROR_SOUND"
fi

# Prompt for daily note settings
echo ""
echo -e "${GREEN}Daily Note Settings:${NC}"
prompt_yes_no "Update daily notes with meeting links?" "true" "UPDATE_DAILY_NOTES"

if [ "$UPDATE_DAILY_NOTES" = "true" ]; then
  echo -e "${BLUE}What heading should be used for meetings in daily notes?${NC}"
  echo -e "${YELLOW}Default: Meetings${NC}"
  read -p "Enter heading (or press Enter for default): " DAILY_NOTE_MEETINGS_HEADING
  if [ -z "$DAILY_NOTE_MEETINGS_HEADING" ]; then
    DAILY_NOTE_MEETINGS_HEADING="Meetings"
  fi
  
  echo -e "${BLUE}What emoji should be used for meetings heading?${NC}"
  echo -e "${YELLOW}Default: 📅${NC}"
  read -p "Enter emoji (or press Enter for default): " DAILY_NOTE_MEETINGS_EMOJI
  if [ -z "$DAILY_NOTE_MEETINGS_EMOJI" ]; then
    DAILY_NOTE_MEETINGS_EMOJI="📅"
  fi
  
  prompt_yes_no "Include personal notes in daily note?" "true" "INCLUDE_PERSONAL_NOTES_IN_DAILY"
fi

# Generate config file
echo ""
echo -e "${GREEN}Generating configuration file...${NC}"

CONFIG_CONTENT="# Configuration file for Granola to Obsidian script
# Generated by installer on $(date)

#############################
# PATHS AND DIRECTORIES
#############################

# Obsidian vault paths
OBSIDIAN_PATH=\"$OBSIDIAN_PATH\"
DAILY_PATH=\"$DAILY_PATH\"
TEMPLATE_PATH=\"$TEMPLATE_PATH\"

#############################
# LOGGING CONFIGURATION
#############################

# Logging settings
LOG_FILE=\"$LOG_FILE\"
ENABLE_DEBUG_LOGGING=false  # Default to false, will be enabled by debug action
LOG_LEVEL=\"debug\"  # Options: debug, info, warning, error

#############################
# FORMATTING OPTIONS
#############################

# Date format options
DATE_FORMAT_FRONT_MATTER=\"YYYY-MM-DD\"  # ISO format for front matter
DATE_FORMAT_DAILY_NOTE=\"D MMMM 'YY\"    # Format for daily note filenames

# Note format options
USE_CALLOUTS=true                      # Use Obsidian callouts for meeting info
INCLUDE_TRANSCRIPT_URL=true            # Include transcript URL in notes
AUTO_EXTRACT_TOPICS=true               # Automatically extract topics from headings
INCLUDE_ATTENDEES_IN_FRONTMATTER=true  # Include attendees in front matter (prevents duplication in body)

#############################
# PATTERN MATCHING
#############################

# Common patterns to exclude from attendee detection
EXCLUDE_WORDS=\"Feature|Update|Updates|Sales|Status|Technical|Meeting|Notes|Agenda|Minutes|Discussion|Review|Planning|Sprint|Roadmap|Backlog|Standup|Retrospective|Demo|Presentation|Report|Summary|Overview|Analysis|Strategy|Implementation|Development|Design|Testing|QA|Release|Launch|Deployment|Integration|Maintenance|Support|Training|Workshop|Seminar|Conference|Webinar|Session|Call|Chat|Conversation|Briefing|Debrief|Feedback|Followup|Follow-up|Check-in|Check-out|Kickoff|Kick-off|Wrap-up|Wrapup|Closing|Opening|Introduction|Conclusion|Summary|Recap|Action|Items|Tasks|Todo|To-do|Milestone|Timeline|Schedule|Calendar|Project|Product|Service|Platform|System|Application|App|Website|Portal|Dashboard|Interface|Framework|Architecture|Infrastructure|Environment|Database|Server|Client|User|Customer|Partner|Vendor|Supplier|Provider|Stakeholder|Team|Group|Department|Division|Organization|Company|Business|Enterprise|Industry|Market|Segment|Sector|Vertical|Horizontal|Global|Local|Regional|National|International|Worldwide|Quarterly|Monthly|Weekly|Daily|Annual|Bi-weekly|Bi-monthly|Semi-annual\"

# Duplicate detection settings
ENABLE_DUPLICATE_DETECTION=$ENABLE_DUPLICATE_DETECTION"

if [ "$ENABLE_DUPLICATE_DETECTION" = "true" ]; then
  CONFIG_CONTENT+="
CHECK_TITLE_DATE=$CHECK_TITLE_DATE
CHECK_URL=$CHECK_URL
CHECK_CONTENT=$CHECK_CONTENT
HASH_STORAGE_DIR=\"$HASH_STORAGE_DIR\""
fi

CONFIG_CONTENT+="

# Validation settings
LENIENT_VALIDATION=$LENIENT_VALIDATION

# Notification settings
IS_RAYCAST=false  # Will be set to true in the Raycast script
ENABLE_NOTIFICATIONS=$ENABLE_NOTIFICATIONS"

if [ "$ENABLE_NOTIFICATIONS" = "true" ]; then
  CONFIG_CONTENT+="
NOTIFICATION_SUCCESS_SOUND=$NOTIFICATION_SUCCESS_SOUND
NOTIFICATION_ERROR_SOUND=$NOTIFICATION_ERROR_SOUND"
fi

if [ "$UPDATE_DAILY_NOTES" = "true" ]; then
  CONFIG_CONTENT+="

# Daily note settings
DAILY_NOTE_MEETINGS_HEADING=\"$DAILY_NOTE_MEETINGS_HEADING\"  # Heading to use for meetings section
DAILY_NOTE_MEETINGS_EMOJI=\"$DAILY_NOTE_MEETINGS_EMOJI\"          # Emoji to use for meetings heading
DAILY_NOTE_HEADING_LEVEL=2              # Heading level (1 = #, 2 = ##, 3 = ###)
DAILY_NOTE_LINK_FORMAT=\"- {{EMOJI}} [[Granola/{{FILENAME}}|{{TITLE}}]]\"  # Format for meeting links
DAILY_NOTE_TIME_FORMAT=\"- {{TIME}} - [[Granola/{{FILENAME}}|{{TITLE}}]]\"  # Format when time is available"

  if [ "$INCLUDE_PERSONAL_NOTES_IN_DAILY" = "true" ]; then
    CONFIG_CONTENT+="
INCLUDE_PERSONAL_NOTES_IN_DAILY=true    # Include personal notes in daily note
DAILY_NOTE_PERSONAL_FORMAT=\"  - 📝 {{PERSONAL_NOTES}}\"  # Format for personal notes in daily note"
  else
    CONFIG_CONTENT+="
INCLUDE_PERSONAL_NOTES_IN_DAILY=false"
  fi
fi

CONFIG_CONTENT+="

#############################
# ERROR CODES
#############################

# Error codes for better error handling
ERROR_INVALID_INPUT=1
ERROR_DATE_EXTRACTION_FAILED=2
ERROR_FILE_CREATION_FAILED=3
ERROR_OBSIDIAN_PATH_NOT_FOUND=4
ERROR_TEMPLATE_NOT_FOUND=5
ERROR_DAILY_NOTE_UPDATE_FAILED=6
"

# Write config file
echo "$CONFIG_CONTENT" > "$SCRIPT_DIR/config.sh"

# Install Raycast scripts
echo ""
echo -e "${GREEN}Installing Raycast scripts...${NC}"

# Copy Raycast scripts
cp "$SCRIPT_DIR/assets/icons/granola-notes.svg" "$HOME/.raycast/commands/granola-notes.svg" 2>/dev/null || true
cp "$SCRIPT_DIR/assets/icons/granola-debug.svg" "$HOME/.raycast/commands/granola-debug.svg" 2>/dev/null || true

# Create Raycast scripts
RAYCAST_SCRIPT="#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Granola Notes
# @raycast.mode silent
# @raycast.icon $HOME/.raycast/commands/granola-notes.svg
# @raycast.packageName Granola
# @raycast.subtitle Convert Granola meeting notes to Obsidian
# @raycast.shortcut cmd+shift+g
# @raycast.description Process meeting notes from Granola and save to Obsidian
# @raycast.author $(whoami)
# @raycast.argument1 { \"type\": \"text\", \"name\": \"personal_notes\", \"placeholder\": \"Add personal notes (will appear in a callout)\", \"optional\": true }

# Set Raycast environment flag
export IS_RAYCAST=true
export ENABLE_DEBUG_LOGGING=false

# Raycast-specific logging and progress functions
log_debug_to_raycast() {
    local message=\"\$1\"
    echo \"DEBUG: \$message\" >&2
}

show_progress() {
    local message=\"\$1\"
    echo \"PROGRESS: \$message\" >&2
}

# Get clipboard content
NOTES=\$(pbpaste)

# Check if clipboard has content
if [ -z \"\$NOTES\" ]; then
    echo \"❌ Error: Clipboard is empty. Please copy meeting notes to clipboard.\"
    exit 1
fi

# Pass clipboard content to the main script via stdin
echo \"\$NOTES\" | \"$SCRIPT_DIR/granola-to-obsidian.sh\" \"\$@\"
"

RAYCAST_DEBUG_SCRIPT="#!/bin/bash

# Main script for debugging Granola to Obsidian conversion

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Granola Notes (Debug)
# @raycast.mode silent
# @raycast.icon $HOME/.raycast/commands/granola-debug.svg

# Optional parameters:
# @raycast.packageName Granola
# @raycast.subtitle Debug Granola notes conversion
# @raycast.shortcut cmd+shift+d

# Documentation:
# @raycast.description Process meeting notes with debug logging enabled
# @raycast.author $(whoami)

# Inputs:
# @raycast.argument1 { \"type\": \"text\", \"name\": \"personal_notes\", \"placeholder\": \"Add personal notes (will appear in a callout)\", \"optional\": true }

# Set environment variables for debug mode
export DEBUG_MODE=true
export ENABLE_DEBUG_LOGGING=true
export IS_RAYCAST=true

# Raycast-specific logging functions
log_debug_to_raycast() {
    local message=\"\$1\"
    echo \"DEBUG: \$message\" >&2
}

show_progress() {
    local message=\"\$1\"
    echo \"PROGRESS: \$message\" >&2
}

# Get clipboard content
NOTES=\$(pbpaste)

# Check if clipboard has content
if [ -z \"\$NOTES\" ]; then
    echo \"❌ Error: Clipboard is empty. Please copy meeting notes to clipboard.\"
    exit 1
fi

# Pass clipboard content to the main script via stdin
echo \"\$NOTES\" | \"$SCRIPT_DIR/granola-to-obsidian.sh\" \"\$@\"

# After processing is complete, show the debug log
echo \"Opening debug log...\"
open -a Console \"$LOG_FILE\"
"

# Write Raycast scripts
echo "$RAYCAST_SCRIPT" > "$HOME/.raycast/scripts/granola-to-obsidian.sh"
echo "$RAYCAST_DEBUG_SCRIPT" > "$HOME/.raycast/scripts/granola-debug.sh"

# Make scripts executable
chmod +x "$HOME/.raycast/scripts/granola-to-obsidian.sh"
chmod +x "$HOME/.raycast/scripts/granola-debug.sh"

# Success message
echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo -e "Your Granola Scraper has been successfully installed and configured."
echo -e "You can now use it in Raycast by pressing ${BLUE}Cmd+Shift+G${NC} or by searching for ${BLUE}Granola Notes${NC}."
echo -e "For debugging, use ${BLUE}Cmd+Shift+D${NC} or search for ${BLUE}Granola Notes (Debug)${NC}."
echo ""
echo -e "${YELLOW}Note: You may need to restart Raycast for the new commands to appear.${NC}"
echo ""
