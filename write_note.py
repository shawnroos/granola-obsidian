#!/usr/bin/env python3
import sys
import os

def write_note(title, date_str, transcript, attendees, notes, output_file):
    date = os.popen(f'date -j -f "%d%m%Y" "{date_str}" "+%Y-%m-%d"').read().strip()
    
    content = f"""---
title: {title}
date: {date}
type: granola
transcript: {transcript}
attendees: [{attendees}]
---

# {title}

{notes}
"""
    
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(content)

if __name__ == "__main__":
    if len(sys.argv) != 7:
        print("Usage: write_note.py <title> <date> <transcript> <attendees> <notes> <output_file>")
        sys.exit(1)
        
    write_note(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6])
