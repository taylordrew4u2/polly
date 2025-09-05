#!/bin/bash
# Script to configure correct architecture settings for App Store submission
# Run this in Xcode by selecting: Product > Scheme > Edit Scheme > Build > Pre-actions

# Set architecture to arm64 only for device builds
defaults write com.apple.dt.Xcode IDEBuildSettings_ARCHS_STANDARD_INCLUDING_64_BIT -string "arm64"

# Make sure VALID_ARCHS is set correctly
defaults write com.apple.dt.Xcode IDEBuildSettings_VALID_ARCHS -string "arm64"

# Ensure we strip simulator slices
defaults write com.apple.dt.Xcode STRIP_INSTALLED_PRODUCT -string "YES"

echo "Architecture settings configured for App Store submission"