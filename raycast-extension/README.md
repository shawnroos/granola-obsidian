# Granola to Obsidian Raycast Extension

Save Granola meeting notes to Obsidian via Raycast.

## Features

- Extracts meeting details from Granola notes
- Creates structured Obsidian notes with front matter
- Extracts attendees from emails and names
- Integrates meeting notes into daily notes
- Prevents duplicate meeting entries
- Intelligent meeting time extraction
- Auto-extracts topics from headings
- Includes personal notes in a separate callout

## Installation

### Development Installation

1. Clone this repository
2. Navigate to the extension directory:
   ```bash
   cd raycast-extension
   ```
3. Install dependencies:
   ```bash
   npm install
   ```
4. Start the development server:
   ```bash
   npm run dev
   ```

### Manual Installation

1. Build the extension:
   ```bash
   npm run build
   ```
2. Import the extension into Raycast

## Usage

1. Copy Granola meeting notes to your clipboard
2. Run the "Save Granola Notes" command from Raycast
3. Optionally add personal notes when prompted
4. Click "Save to Obsidian" to process the notes

## Configuration

The extension can be configured through Raycast preferences:

- **Obsidian Vault Path**: Path to your Obsidian vault
- **Granola Folder**: Folder within your vault where Granola notes will be saved
- **Daily Notes Folder**: Folder within your vault where daily notes are stored
- **Enable Debug Logging**: Enable detailed logging for troubleshooting
- **Log Level**: Set the verbosity of logging (debug, info, warning, error)
- **Include Transcript URL**: Include a link to the original Granola transcript in notes
- **Auto-Extract Topics**: Automatically extract topics from headings in notes
- **Include Personal Notes in Daily**: Include personal notes in the daily note entry

## Development

This extension is built using:
- TypeScript
- React
- Raycast API

### Project Structure

- `src/index.tsx`: Main component and entry point
- `src/utils/processGranolaNote.ts`: Core functionality for processing Granola notes
- `src/preferences.json`: Extension preferences schema

## Publishing

To publish the extension to the Raycast store:

1. Make sure you have an account on Raycast
2. Run:
   ```bash
   npm run publish
   ```
3. Follow the prompts to complete the publishing process

## License

MIT
