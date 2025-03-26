#!/bin/bash

# Setup script for Granola to Obsidian Raycast extension
echo "Setting up Granola to Obsidian Raycast extension..."

# Install dependencies
echo "Installing dependencies..."
npm install

# Create assets directory if it doesn't exist
mkdir -p assets

# Download a placeholder icon if one doesn't exist
if [ ! -s "assets/command-icon.png" ]; then
  echo "Downloading placeholder icon..."
  curl -s "https://raw.githubusercontent.com/raycast/script-commands/master/commands/apps/obsidian/images/obsidian-logo.png" -o "assets/command-icon.png"
fi

# Create a .env file with development settings
echo "Creating development environment..."
cat > .env << EOF
# Development environment settings
NODE_ENV=development
EOF

echo "Setup complete! Run 'npm run dev' to start the development server."
