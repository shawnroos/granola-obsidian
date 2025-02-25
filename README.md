# Granola to Obsidian

A simple script to save Granola meeting notes directly to Obsidian via Raycast.

## Features

- Save Granola notes to Obsidian with a single command
- Automatically formats notes with:
  - Clean filenames: `The [Meeting Title] _DDMMYYYY.md`
  - YAML frontmatter with title, date, and type
  - Title repeated as H1 heading
- Easy to use through Raycast

## Setup

1. Install the script in Raycast:
   ```bash
   mkdir -p ~/.raycast/scripts/
   cp granola-to-obsidian.sh ~/.raycast/scripts/
   chmod +x ~/.raycast/scripts/granola-to-obsidian.sh
   ```

2. Configure Raycast:
   - Open Raycast
   - Find "Granola Notes" command
   - Optional: Set a keyboard shortcut

## Usage

1. Copy text in Granola (⌘C)
2. Run "Granola Notes" from Raycast
3. Note is saved to Obsidian in your Granola folder
