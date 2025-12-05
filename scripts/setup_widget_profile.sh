#!/bin/bash

# Script to prepare the Widget Provisioning Profile for CI
# Assumes the profile is in ~/Downloads

echo "🔍 Looking for mobileprovision files in ~/Downloads..."

# Find the most recent .mobileprovision file in Downloads
# We assume the user just downloaded it.
LATEST_PROFILE=$(ls -t ~/Downloads/*.mobileprovision 2>/dev/null | head -n 1)

if [ -z "$LATEST_PROFILE" ]; then
    echo "❌ No .mobileprovision files found in ~/Downloads."
    echo "   Please download the profile from Apple Developer Portal first."
    exit 1
fi

FILENAME=$(basename "$LATEST_PROFILE")
echo "📄 Found latest profile: $FILENAME"
echo "   Path: $LATEST_PROFILE"

# Ask for confirmation
read -p "Is this the correct profile for the Widget? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborting. Please specify the path manually:"
    read -p "Path to profile: " MANUAL_PATH
    LATEST_PROFILE=$MANUAL_PATH
fi

if [ ! -f "$LATEST_PROFILE" ]; then
    echo "❌ File not found: $LATEST_PROFILE"
    exit 1
fi

echo "🔄 Converting to Base64..."
# Strip newlines to ensure clean secret
BASE64_STR=$(base64 < "$LATEST_PROFILE" | tr -d '\n')

# Copy to clipboard
echo "$BASE64_STR" | pbcopy
echo "✅ Base64 string copied to clipboard!"

# Attempt to set via gh if available
if command -v gh &> /dev/null; then
    echo "🚀 Detected GitHub CLI. Attempting to set secret 'BUILD_WIDGET_PROVISION_PROFILE_BASE64'..."
    echo "   (You may need to authorize if not logged in)"
    
    echo "$BASE64_STR" | gh secret set BUILD_WIDGET_PROVISION_PROFILE_BASE64 --body -
    
    if [ $? -eq 0 ]; then
        echo "✅ Secret 'BUILD_WIDGET_PROVISION_PROFILE_BASE64' successfully updated on GitHub!"
    else
        echo "⚠️  Failed to set secret via gh. Please paste the clipboard content manually into GitHub Secrets."
    fi
else
    echo "ℹ️  GitHub CLI (gh) not found or not configured."
    echo "📋 Please manually add a secret named 'BUILD_WIDGET_PROVISION_PROFILE_BASE64' with the clipboard content."
fi
