#!/bin/bash

# validate_version_info.sh
# Script to validate Info.plist versioning before build
# - Ensures CFBundleVersion is incremented by 1 for each archive
# - Prevents duplicate bundle versions
# - Validates minimum iOS deployment target does not exceed current SDK

set -e

INFO_PLIST="$SRCROOT/polly/Info.plist"
BUILD_VERSION_HISTORY_FILE="$SRCROOT/build_version_history.txt"

# Check if Info.plist exists
if [ ! -f "$INFO_PLIST" ]; then
    echo "Error: Info.plist not found at $INFO_PLIST"
    exit 1
fi

# Extract current version info
BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST")
BUNDLE_SHORT_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")
echo "Current CFBundleVersion: $BUNDLE_VERSION"
echo "Current CFBundleShortVersionString: $BUNDLE_SHORT_VERSION"

# Create version history file if it doesn't exist
if [ ! -f "$BUILD_VERSION_HISTORY_FILE" ]; then
    echo "Creating build version history file..."
    echo "# Build Version History" > "$BUILD_VERSION_HISTORY_FILE"
    echo "# Format: CFBundleShortVersionString,CFBundleVersion,BuildDate" >> "$BUILD_VERSION_HISTORY_FILE"
fi

# Check for duplicate bundle versions
if grep -q "^$BUNDLE_SHORT_VERSION,$BUNDLE_VERSION," "$BUILD_VERSION_HISTORY_FILE"; then
    echo "Error: Duplicate bundle version detected."
    echo "Version $BUNDLE_SHORT_VERSION ($BUNDLE_VERSION) has already been used."
    echo "Please increment CFBundleVersion in Info.plist."
    exit 1
fi

# Check if CFBundleVersion is incremented by 1
PREV_BUNDLE_VERSION=""
if [ -f "$BUILD_VERSION_HISTORY_FILE" ]; then
    PREV_BUNDLE_VERSION=$(grep "^$BUNDLE_SHORT_VERSION," "$BUILD_VERSION_HISTORY_FILE" | tail -1 | cut -d',' -f2)
    if [ ! -z "$PREV_BUNDLE_VERSION" ]; then
        EXPECTED_VERSION=$((PREV_BUNDLE_VERSION + 1))
        if [ "$BUNDLE_VERSION" != "$EXPECTED_VERSION" ]; then
            echo "Warning: CFBundleVersion should be incremented by 1."
            echo "Previous build for $BUNDLE_SHORT_VERSION was $PREV_BUNDLE_VERSION, expected $EXPECTED_VERSION, got $BUNDLE_VERSION."
            
            # Automatically correct the version
            if [ "$BUNDLE_VERSION" -lt "$EXPECTED_VERSION" ]; then
                echo "Automatically updating CFBundleVersion to $EXPECTED_VERSION"
                /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $EXPECTED_VERSION" "$INFO_PLIST"
                BUNDLE_VERSION=$EXPECTED_VERSION
            fi
        fi
    fi
fi

# Validate iOS deployment target against current SDK
MIN_DEPLOYMENT_TARGET=$(/usr/libexec/PlistBuddy -c "Print :MinimumOSVersion" "$INFO_PLIST" 2>/dev/null || echo "Not specified")
if [ "$MIN_DEPLOYMENT_TARGET" != "Not specified" ]; then
    CURRENT_SDK_VERSION=$(xcrun --sdk iphoneos --show-sdk-version)
    
    # Compare versions (simple major version check)
    MIN_MAJOR=$(echo $MIN_DEPLOYMENT_TARGET | cut -d. -f1)
    SDK_MAJOR=$(echo $CURRENT_SDK_VERSION | cut -d. -f1)
    
    if [ $MIN_MAJOR -gt $SDK_MAJOR ]; then
        echo "Error: Minimum iOS deployment target ($MIN_DEPLOYMENT_TARGET) exceeds current SDK version ($CURRENT_SDK_VERSION)"
        exit 1
    fi
    
    echo "Minimum iOS deployment target: $MIN_DEPLOYMENT_TARGET (Current SDK: $CURRENT_SDK_VERSION)"
else
    echo "No MinimumOSVersion specified in Info.plist"
fi

# Record current version in history file if we're in a real build (not validation only)
if [ "$1" != "validate_only" ]; then
    CURRENT_DATE=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$BUNDLE_SHORT_VERSION,$BUNDLE_VERSION,$CURRENT_DATE" >> "$BUILD_VERSION_HISTORY_FILE"
    echo "Recorded build version in history file."
fi

echo "Version validation completed successfully."
exit 0