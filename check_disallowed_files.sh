#!/bin/bash
# Script to check and remove disallowed files for App Store submission

echo "Checking for disallowed files that might cause App Store rejection..."

# Path to your app's build directory
# Note: This is a placeholder path. You'll need to update this with your actual build path after building
BUILD_DIR="/Users/taylordrew/Library/Developer/Xcode/DerivedData/polly-*/Build/Products/Release-iphoneos/polly.app"

# Check if we have any disallowed file patterns
echo "Scanning for disallowed file patterns..."

# List of patterns to check for
DISALLOWED_PATTERNS=(
  "*.dSYM"
  "Headers"
  "Modules"
  "*.swiftmodule"
  "PrivateHeaders"
  "*.framework/Headers"
  "*.framework/Modules"
)

# Function to check if disallowed files exist
check_disallowed_files() {
  local dir="$1"
  if [ -d "$dir" ]; then
    echo "Checking directory: $dir"
    for pattern in "${DISALLOWED_PATTERNS[@]}"; do
      found=$(find "$dir" -name "$pattern" 2>/dev/null)
      if [ -n "$found" ]; then
        echo "⚠️ WARNING: Found disallowed files matching pattern '$pattern':"
        echo "$found"
        echo "These files should be removed before App Store submission."
      fi
    done
  else
    echo "Directory not found: $dir"
    echo "Please build your app first or update the BUILD_DIR path in this script."
  fi
}

# Check for disallowed files
check_disallowed_files "$BUILD_DIR"

echo "Disallowed file check completed."
echo "If any warnings were shown above, those files should be removed from the Copy Bundle Resources phase."