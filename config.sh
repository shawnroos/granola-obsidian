#!/bin/bash
# Configuration file for Granola to Obsidian script

#############################
# PATHS AND DIRECTORIES
#############################

# Obsidian vault paths
OBSIDIAN_PATH="/Users/shawnroos/Library/Mobile Documents/iCloud~md~obsidian/Documents/Rooshub/Notes/Granola"
DAILY_PATH="/Users/shawnroos/Library/Mobile Documents/iCloud~md~obsidian/Documents/Rooshub/Notes/Dailys"
TEMPLATE_PATH="/Users/shawnroos/Library/Mobile Documents/iCloud~md~obsidian/Documents/Rooshub/Templates/Daily Note.md"

#############################
# LOGGING CONFIGURATION
#############################

# Logging settings
LOG_FILE="/tmp/granola-debug.log"
ENABLE_DEBUG_LOGGING=true
LOG_LEVEL="debug"  # Options: debug, info, warning, error

#############################
# FORMATTING OPTIONS
#############################

# Date format options
DATE_FORMAT_FRONT_MATTER="YYYY-MM-DD"  # ISO format for front matter
DATE_FORMAT_DAILY_NOTE="D MMMM 'YY"    # Format for daily note filenames

# Note format options
USE_CALLOUTS=true                      # Use Obsidian callouts for meeting info
INCLUDE_TRANSCRIPT_URL=true            # Include transcript URL in notes
AUTO_EXTRACT_TOPICS=true               # Automatically extract topics from headings

#############################
# PATTERN MATCHING
#############################

# Common patterns to exclude from attendee detection
EXCLUDE_WORDS="Feature|Update|Updates|Sales|Status|Technical|Meeting|Notes|Agenda|Minutes|Discussion|Review|Planning|Sprint|Roadmap|Backlog|Standup|Retrospective|Demo|Presentation|Report|Summary|Overview|Analysis|Strategy|Implementation|Development|Design|Testing|QA|Release|Launch|Deployment|Integration|Maintenance|Support|Training|Workshop|Seminar|Conference|Webinar|Session|Call|Chat|Conversation|Briefing|Debrief|Feedback|Followup|Follow-up|Check-in|Check-out|Kickoff|Kick-off|Wrap-up|Wrapup|Closing|Opening|Introduction|Conclusion|Summary|Recap|Action|Items|Tasks|Todo|To-do|Milestone|Timeline|Schedule|Calendar|Project|Product|Service|Platform|System|Application|App|Website|Portal|Dashboard|Interface|Framework|Architecture|Infrastructure|Environment|Database|Server|Client|User|Customer|Partner|Vendor|Supplier|Provider|Stakeholder|Team|Group|Department|Division|Organization|Company|Business|Enterprise|Industry|Market|Segment|Sector|Vertical|Horizontal|Global|Local|Regional|National|International|Worldwide|Quarterly|Monthly|Weekly|Daily|Annual|Bi-weekly|Bi-monthly|Semi-annual"

# Duplicate detection settings
ENABLE_DUPLICATE_DETECTION=true
HASH_STORAGE_DIR="$SCRIPT_DIR/.note_hashes"
CHECK_TITLE_DATE=true
CHECK_URL=true
CHECK_CONTENT=true

# Notification settings
IS_RAYCAST=false  # Will be set to true in the Raycast script
ENABLE_NOTIFICATIONS=true
NOTIFICATION_SUCCESS_SOUND=true
NOTIFICATION_ERROR_SOUND=true

# Daily note settings
DAILY_NOTE_MEETINGS_HEADING="Meetings"  # Heading to use for meetings section
DAILY_NOTE_MEETINGS_EMOJI="📅"          # Emoji to use for meetings heading
DAILY_NOTE_HEADING_LEVEL=2              # Heading level (1 = #, 2 = ##, 3 = ###)
DAILY_NOTE_LINK_FORMAT="- {{EMOJI}} [[Granola/{{FILENAME}}|{{TITLE}}]]"  # Format for meeting links
DAILY_NOTE_TIME_FORMAT="- {{TIME}} - [[Granola/{{FILENAME}}|{{TITLE}}]]"  # Format when time is available

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
