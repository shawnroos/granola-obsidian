import { execSync } from "child_process";
import * as fs from "fs";
import * as path from "path";
import * as os from "os";

/**
 * Result of processing a Granola note
 */
interface ProcessResult {
  success: boolean;
  message: string;
}

/**
 * Configuration for the Granola note processor
 */
interface GranolaConfig {
  OBSIDIAN_VAULT_PATH: string;
  GRANOLA_FOLDER: string;
  DAILY_NOTES_FOLDER: string;
  ENABLE_DEBUG_LOGGING: boolean;
  LOG_LEVEL: string;
  INCLUDE_TRANSCRIPT_URL: boolean;
  AUTO_EXTRACT_TOPICS: boolean;
  INCLUDE_PERSONAL_NOTES_IN_DAILY: boolean;
  LENIENT_VALIDATION: boolean;
}

/**
 * Process a Granola note and save it to Obsidian
 * @param content The content of the Granola note
 * @param personalNotes Optional personal notes to include
 * @param config Configuration for processing the note
 * @returns An object with the result of the processing
 */
export function processGranolaNote(
  content: string,
  personalNotes: string = "",
  config: GranolaConfig
): ProcessResult {
  try {
    // Validate the content
    if (!isGranolaContent(content, config)) {
      return {
        success: false,
        message: config.LENIENT_VALIDATION 
          ? "Content doesn't appear to be a valid note (even with lenient validation)."
          : "Content doesn't appear to be a valid Granola note. Try enabling lenient validation in preferences."
      };
    }

    // Extract meeting title
    const titleMatch = content.match(/^# (.+)$/m);
    const title = titleMatch ? titleMatch[1].trim() : "Meeting Notes";

    // Extract date and time
    const dateTimeMatch = content.match(/(\d{1,2}\/\d{1,2}\/\d{4}),?\s+(\d{1,2}:\d{2}\s*[AP]M)/i);
    let date = new Date();
    let time = "";
    
    if (dateTimeMatch) {
      const [_, dateStr, timeStr] = dateTimeMatch;
      const [month, day, year] = dateStr.split('/').map(Number);
      date = new Date(year, month - 1, day);
      time = timeStr.trim();
    }

    // Format date for filename
    const formattedDate = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
    
    // Extract attendees
    const attendeesMatch = content.match(/Attendees:(.*?)(?=\n\n|\n#)/s);
    let attendees: string[] = [];
    
    if (attendeesMatch) {
      attendees = attendeesMatch[1]
        .split('\n')
        .filter(line => line.trim() !== '')
        .map(line => {
          // Extract name from email format "Name <email>"
          const emailMatch = line.match(/(.*?)\s*<.*?>/);
          if (emailMatch) {
            return emailMatch[1].trim();
          }
          return line.trim();
        });
    }

    // Extract topics if enabled
    let topics: string[] = [];
    if (config.AUTO_EXTRACT_TOPICS) {
      topics = extractTopics(content);
    }

    // Extract transcript URL if enabled
    let transcriptUrl = "";
    if (config.INCLUDE_TRANSCRIPT_URL) {
      const urlMatch = content.match(/Transcript:\s*(https?:\/\/[^\s]+)/i);
      if (urlMatch) {
        transcriptUrl = urlMatch[1];
      }
    }

    // Format the note
    const formattedNote = formatNote(
      title,
      formattedDate,
      time,
      attendees,
      topics,
      transcriptUrl,
      content,
      personalNotes
    );

    // Save the note to Obsidian
    const obsidianVaultPath = config.OBSIDIAN_VAULT_PATH.replace(/^~/, os.homedir());
    const granolaFolderPath = path.join(obsidianVaultPath, config.GRANOLA_FOLDER);
    
    // Create Granola folder if it doesn't exist
    if (!fs.existsSync(granolaFolderPath)) {
      fs.mkdirSync(granolaFolderPath, { recursive: true });
    }

    // Create filename
    const sanitizedTitle = title.replace(/[\\/:*?"<>|]/g, '-');
    const filename = `${formattedDate} ${sanitizedTitle}.md`;
    const filePath = path.join(granolaFolderPath, filename);

    // Save the note
    fs.writeFileSync(filePath, formattedNote);

    // Update daily note if needed
    if (config.INCLUDE_PERSONAL_NOTES_IN_DAILY) {
      updateDailyNote(
        obsidianVaultPath,
        config.DAILY_NOTES_FOLDER,
        formattedDate,
        title,
        personalNotes
      );
    }

    return {
      success: true,
      message: `Note saved to ${filePath}`
    };
  } catch (error) {
    console.log("Error processing note:", error);
    return {
      success: false,
      message: `Error processing note: ${error}`
    };
  }
}

/**
 * Checks if the content is valid Granola content
 * @param content The content to check
 * @param config The Granola configuration
 * @returns True if the content is valid Granola content, false otherwise
 */
function isGranolaContent(content: string, config: GranolaConfig): boolean {
  // If content is empty, it's not valid
  if (!content || content.trim() === '') {
    return false;
  }

  // Check for Granola patterns
  const hasGranolaPattern = content.includes('Granola') || 
                            content.includes('Meeting Notes') || 
                            content.includes('Transcript:');
  
  // Check for Slack URLs
  const hasSlackUrl = content.includes('slack.com') || content.includes('Slack URL:');
  
  // Check for any URLs (as a fallback)
  const hasUrl = content.includes('http://') || content.includes('https://');
  
  // In lenient mode, accept any non-empty content with URLs or Granola patterns
  if (config.LENIENT_VALIDATION) {
    if (hasGranolaPattern || hasSlackUrl || hasUrl) {
      // Show a warning if we're using lenient validation for non-standard content
      if (!hasGranolaPattern && (hasSlackUrl || hasUrl)) {
        console.log("Warning: Processing non-standard content in lenient mode.");
      }
      return true;
    }
    // Even in lenient mode, we need some minimum content
    return content.trim().length > 50;
  }
  
  // In strict mode, only accept content with Granola patterns
  return hasGranolaPattern;
}

/**
 * Format note with front matter and content
 */
function formatNote(
  title: string,
  date: string,
  time: string,
  attendees: string[],
  topics: string[],
  transcriptUrl: string,
  content: string,
  personalNotes: string
): string {
  // Create front matter
  let frontMatter = `---
title: ${title}
date: ${date}
time: ${time}
attendees: [${attendees.map(a => `"${a}"`).join(', ')}]
`;

  if (topics.length > 0) {
    frontMatter += `topics: [${topics.map(t => `"${t}"`).join(', ')}]
`;
  }

  if (transcriptUrl) {
    frontMatter += `transcript: ${transcriptUrl}
`;
  }

  frontMatter += `---

`;

  // Add personal notes if provided
  let notesContent = content;
  if (personalNotes && personalNotes.trim() !== '') {
    notesContent += `\n\n> [!note] Personal Notes\n> ${personalNotes.replace(/\n/g, '\n> ')}`;
  }

  return frontMatter + notesContent;
}

/**
 * Extract topics from headings in the content
 */
function extractTopics(content: string): string[] {
  const topics: string[] = [];
  const headingMatches = content.matchAll(/^##\s+(.+)$/gm);
  
  for (const match of headingMatches) {
    const topic = match[1].trim();
    if (topic && !topics.includes(topic)) {
      topics.push(topic);
    }
  }
  
  return topics;
}

/**
 * Update the daily note with the meeting information
 */
function updateDailyNote(
  obsidianVaultPath: string,
  dailyNotesFolder: string,
  date: string,
  title: string,
  personalNotes: string
): void {
  try {
    const dailyNotesPath = path.join(obsidianVaultPath, dailyNotesFolder);
    
    // Create daily notes folder if it doesn't exist
    if (!fs.existsSync(dailyNotesPath)) {
      fs.mkdirSync(dailyNotesPath, { recursive: true });
    }
    
    // Format daily note filename
    const dailyNoteFilename = `${date}.md`;
    const dailyNotePath = path.join(dailyNotesPath, dailyNoteFilename);
    
    // Create daily note if it doesn't exist
    if (!fs.existsSync(dailyNotePath)) {
      fs.writeFileSync(dailyNotePath, `# ${date}\n\n## Meetings\n\n`);
    }
    
    // Read daily note content
    let dailyNoteContent = fs.readFileSync(dailyNotePath, 'utf8');
    
    // Check if meeting is already in daily note
    if (dailyNoteContent.includes(title)) {
      console.log(`Meeting "${title}" already in daily note`);
      return;
    }
    
    // Add meeting to daily note
    let meetingEntry = `- [[${date} ${title}|${title}]]`;
    
    // Add personal notes if provided
    if (personalNotes && personalNotes.trim() !== '') {
      // Truncate long personal notes
      let truncatedNotes = personalNotes;
      if (truncatedNotes.length > 100) {
        truncatedNotes = truncatedNotes.substring(0, 97) + '...';
      }
      meetingEntry += `\n  - 📝 ${truncatedNotes}`;
    }
    
    // Find the Meetings section
    const meetingsSectionMatch = dailyNoteContent.match(/## Meetings\s*\n/);
    if (meetingsSectionMatch) {
      const meetingsSectionIndex = meetingsSectionMatch.index! + meetingsSectionMatch[0].length;
      dailyNoteContent = 
        dailyNoteContent.substring(0, meetingsSectionIndex) + 
        meetingEntry + '\n\n' + 
        dailyNoteContent.substring(meetingsSectionIndex);
    } else {
      // If no Meetings section, add it
      dailyNoteContent += `\n## Meetings\n\n${meetingEntry}\n`;
    }
    
    // Write updated content
    fs.writeFileSync(dailyNotePath, dailyNoteContent);
    
    console.log(`Updated daily note with meeting "${title}"`);
  } catch (error) {
    console.log(`Error updating daily note: ${error}`);
  }
}
