import { showHUD, getPreferenceValues, showToast, Toast, Clipboard, open } from "@raycast/api";
import * as fs from "fs";
import * as path from "path";
import * as os from "os";

interface Preferences {
  obsidianVaultPath: string;
  granolaFolder: string;
  dailyNotesFolder: string;
}

export default async function command() {
  try {
    // Get preferences
    const preferences = getPreferenceValues<Preferences>();
    
    // Get clipboard content
    const clipboardText = await Clipboard.readText();
    
    if (!clipboardText) {
      await showToast({
        style: Toast.Style.Failure,
        title: "No content in clipboard",
        message: "Please copy Granola meeting notes to your clipboard first"
      });
      return;
    }
    
    // Process the note
    await showHUD("Processing Granola note...");
    
    // Prepare paths
    const vaultPath = preferences.obsidianVaultPath.replace(/^~/, os.homedir());
    const granolaFolder = path.join(vaultPath, preferences.granolaFolder);
    
    // Create folders if they don't exist
    if (!fs.existsSync(granolaFolder)) {
      fs.mkdirSync(granolaFolder, { recursive: true });
    }
    
    // Extract basic info from the content
    const titleMatch = clipboardText.match(/^(.+?)(?:\n|$)/);
    const title = titleMatch ? titleMatch[1].trim() : "Untitled Meeting";
    
    // Create a simple filename
    const date = new Date();
    const dateString = date.toISOString().split('T')[0];
    const fileName = `${dateString} - ${title.replace(/[\\/:*?"<>|]/g, "-")}.md`;
    const filePath = path.join(granolaFolder, fileName);
    
    // Create the note content
    const noteContent = `---
title: "${title}"
date: ${dateString}
---

# ${title}

${clipboardText}
`;
    
    // Save the file
    fs.writeFileSync(filePath, noteContent);
    
    // Show success message
    await showToast({
      style: Toast.Style.Success,
      title: "Note saved successfully",
      message: `Saved to ${fileName}`
    });
    
    // Open the file in Obsidian
    await open(`obsidian://open?vault=${encodeURIComponent(path.basename(vaultPath))}&file=${encodeURIComponent(path.join(preferences.granolaFolder, fileName))}`);
    
  } catch (error) {
    console.error("Error:", error);
    await showToast({
      style: Toast.Style.Failure,
      title: "Error saving note",
      message: String(error)
    });
  }
}
