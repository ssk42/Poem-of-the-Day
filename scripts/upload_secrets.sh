#!/bin/bash
set -e

echo "🚀 Uploading iOS Signing Secrets to GitHub..."
echo "Make sure you are logged in to gh cli (run 'gh auth login' if not)."

# 1. Get P12 File
echo ""
echo "👉 Step 1/3: Certificate"
read -p "Drag and drop your .p12 certificate file here (from Downloads): " P12_PATH
# Remove surrounding quotes if present (common when dragging files in terminal)
P12_PATH="${P12_PATH%\"}"
P12_PATH="${P12_PATH#\"}"
# Trim whitespace
P12_PATH=$(echo "$P12_PATH" | xargs)

if [ ! -f "$P12_PATH" ]; then
    echo "❌ Error: File not found at '$P12_PATH'"
    exit 1
fi

# 2. Get P12 Password
echo ""
echo "👉 Step 2/3: Certificate Password"
read -s -p "Enter the password you set for the .p12 file: " P12_PASSWORD
echo ""

# 3. Get Provisioning Profile
echo ""
echo "👉 Step 3/3: Provisioning Profile"
read -p "Drag and drop your .mobileprovision file here (from Downloads): " PROFILE_PATH
PROFILE_PATH="${PROFILE_PATH%\"}"
PROFILE_PATH="${PROFILE_PATH#\"}"
# Trim whitespace
PROFILE_PATH=$(echo "$PROFILE_PATH" | xargs)

if [ ! -f "$PROFILE_PATH" ]; then
    echo "❌ Error: File not found at '$PROFILE_PATH'"
    exit 1
fi

echo ""
echo "🔐 Processing and uploading secrets to GitHub..."

# Upload BUILD_CERTIFICATE_BASE64
echo "   - Uploading BUILD_CERTIFICATE_BASE64..."
base64 -i "$P12_PATH" | gh secret set BUILD_CERTIFICATE_BASE64

# Upload P12_PASSWORD
echo "   - Uploading P12_PASSWORD..."
echo "$P12_PASSWORD" | gh secret set P12_PASSWORD

# Upload BUILD_PROVISION_PROFILE_BASE64
echo "   - Uploading BUILD_PROVISION_PROFILE_BASE64..."
base64 -i "$PROFILE_PATH" | gh secret set BUILD_PROVISION_PROFILE_BASE64

# Upload KEYCHAIN_PASSWORD (random)
echo "   - Uploading KEYCHAIN_PASSWORD..."
echo "temp-password-$(date +%s)" | gh secret set KEYCHAIN_PASSWORD

echo ""
echo "✅ All secrets uploaded successfully!"
echo "You can now re-run the failed CI job."
