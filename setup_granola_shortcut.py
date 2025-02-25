#!/usr/bin/env python3
import os
import subprocess
from pathlib import Path

def create_shortcut_script():
    """Creates an AppleScript that can be imported into Shortcuts"""
    script = '''
on run {input, parameters}
    -- Get the current clipboard content
    set meetingNotes to the clipboard
    
    -- Get current date for filename
    set currentDate to do shell script "date '+%Y-%m-%d'"
    
    -- Extract title from the notes (assuming it's the first line)
    set meetingTitle to paragraph 1 of meetingNotes
    -- Clean the title for filename
    set cleanTitle to do shell script "echo " & quoted form of meetingTitle & " | tr -cd '[:alnum:][:space:]-'"
    
    -- Create filename
    set fileName to currentDate & "-" & cleanTitle & ".md"
    
    -- Path to Obsidian vault
    set obsidianPath to (path to home folder as text) & "Documents/Obsidian/Granola Meetings/" & fileName
    
    -- Add YAML frontmatter
    set yamlContent to "---\\ntitle: " & meetingTitle & "\\ndate: " & currentDate & "\\nsource: Granola\\n---\\n\\n" & meetingNotes
    
    -- Write to file
    do shell script "mkdir -p \"$(dirname " & quoted form of POSIX path of obsidianPath & ")\""
    do shell script "echo " & quoted form of yamlContent & " > " & quoted form of POSIX path of obsidianPath
    
    return "Meeting notes saved to Obsidian: " & fileName
end run
'''
    
    script_path = Path.home() / "Desktop" / "GranolaToObsidian.scpt"
    with open(script_path, 'w') as f:
        f.write(script)
    
    print(f"\nCreated AppleScript at: {script_path}")
    print("\nTo set up the automation:")
    print("1. Open Shortcuts app")
    print("2. Click the + to create a new shortcut")
    print("3. Add 'Run AppleScript' action")
    print("4. Copy and paste the contents of GranolaToObsidian.scpt")
    print("5. Add a trigger:")
    print("   - Click the ⓘ icon in the shortcut's header")
    print("   - Choose 'Add Keyboard Shortcut'")
    print("   - Set a keyboard shortcut (e.g., ⌘⇧G)")
    print("\nNow when you have notes in Granola:")
    print("1. Select the text you want to save")
    print("2. Press ⌘C to copy")
    print("3. Press your keyboard shortcut")
    print("The notes will automatically appear in your Obsidian vault!")

if __name__ == "__main__":
    create_shortcut_script()
