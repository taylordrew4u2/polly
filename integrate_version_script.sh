#!/bin/bash

# integrate_version_script.sh
# This script adds the validate_version_info.sh script as a Run Script Build Phase to the Xcode project
# Run this once to configure your project

PROJECTROOT="$(dirname "$0")"
cd "$PROJECTROOT"

# Path to the target Xcode project
PROJECT_FILE="$PROJECTROOT/polly.xcodeproj/project.pbxproj"

# Ensure the validation script exists and is executable
if [ ! -f "$PROJECTROOT/validate_version_info.sh" ]; then
    echo "Error: validate_version_info.sh not found!"
    exit 1
fi

chmod +x "$PROJECTROOT/validate_version_info.sh"

echo "✅ Validation script is executable"

# Instructions for manually adding the build script
echo "=========================================================="
echo "To complete the integration, please follow these steps in Xcode:"
echo "1. Open your Xcode project (polly.xcodeproj)"
echo "2. Select the 'polly' target"
echo "3. Go to the 'Build Phases' tab"
echo "4. Click the '+' button at the top left of the panel"
echo "5. Select 'New Run Script Phase'"
echo "6. Drag this new phase to be the first build phase"
echo "7. In the script field, paste the following:"
echo ""
echo "# Run version validation script"
echo "set -e"
echo "SCRIPT=\"\${SRCROOT}/validate_version_info.sh\""
echo "if [ -f \"\$SCRIPT\" ]; then"
echo "    \"\$SCRIPT\""
echo "else"
echo "    echo \"Warning: Version validation script not found at \$SCRIPT\""
echo "fi"
echo ""
echo "8. Optionally, rename the phase to 'Validate Version Info'"
echo "9. Make sure 'Run script only when installing' is NOT checked"
echo "10. Ensure 'Enable User Script Sandboxing' is NOT checked (if available)"
echo "=========================================================="
echo ""
echo "After completing these steps, the validation script will run before each build"
echo "and will validate your app's versioning information."