#!/usr/bin/env bash
set -euo pipefail

# StoreKit Eligibilityd Simulator Fix Script
# This script addresses the common StoreKit eligibilityd cache warning in iOS Simulator

red()   { printf "\033[31m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$*"; }
bold()  { printf "\033[1m%s\033[0m\n" "$*"; }

# Your specific device and app details
DEVICE_UDID="4DE73466-849F-48B6-A424-7585C5ADBD3B"
BUNDLE_ID="polly.polly"

echo "🔧 StoreKit Eligibilityd Simulator Fix"
echo "======================================"
echo

bold "About this issue:"
echo "The StoreKit eligibilityd warning is a simulator-only issue that occurs when"
echo "the simulator can't find its cache file. This is harmless and doesn't affect"
echo "device builds, but can spam your logs during development."
echo

# Check if simulator is running
DEVICE_STATE=$(xcrun simctl list devices | grep "$DEVICE_UDID" | awk '{print $NF}' | tr -d '()')

echo "Current device state: $DEVICE_STATE"
echo

# Option 1: Quick fix - erase the affected simulator
bold "Option 1: Quick Fix (Erase affected simulator)"
echo "This will:"
echo "- Shutdown the iPhone 16 Pro simulator"
echo "- Erase its data (including the corrupted cache)"
echo "- Clean reinstall your app"
echo

read -p "Execute quick fix? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    green "Executing quick fix..."
    
    # Shutdown the specific simulator
    echo "Shutting down simulator..."
    xcrun simctl shutdown "$DEVICE_UDID" 2>/dev/null || true
    
    # Erase the simulator
    echo "Erasing simulator data..."
    xcrun simctl erase "$DEVICE_UDID"
    
    green "✓ Simulator reset complete"
    echo "The simulator cache has been cleared. Next time you run your app,"
    echo "the StoreKit eligibilityd warning should be resolved."
    echo
fi

# Option 2: Nuclear option
bold "Option 2: Nuclear Option (Clean everything)"
echo "This will:"
echo "- Shutdown ALL simulators"
echo "- Erase ALL simulator data"
echo "- Clear Xcode derived data"
echo "- Require rebuilding everything"
echo

read -p "Execute nuclear option? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    yellow "⚠️  This will erase ALL simulators and derived data!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        green "Executing nuclear option..."
        
        # Shutdown all simulators
        echo "Shutting down all simulators..."
        xcrun simctl shutdown all
        
        # Erase all simulators
        echo "Erasing all simulator data..."
        xcrun simctl erase all
        
        # Clear derived data
        echo "Clearing Xcode derived data..."
        rm -rf ~/Library/Developer/Xcode/DerivedData/*
        
        green "✓ Complete cleanup finished"
        echo "All simulators and build data have been cleared."
        echo "You'll need to rebuild your project from scratch."
        echo
    fi
fi

# Option 3: StoreKit configuration recommendation
bold "Option 3: StoreKit Configuration (Recommended for StoreKit apps)"
echo "If your app uses StoreKit, consider:"
echo "1. Adding a .storekit configuration file to your project"
echo "2. Selecting it in Scheme → Run → Options → StoreKit Configuration"
echo "3. Or guard StoreKit code to only run when a config is active"
echo

# Create a sample StoreKit configuration
read -p "Create a sample .storekit config file? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cat > "PollyStoreKit.storekit" << 'EOF'
{
  "identifier" : "E9A1B51A",
  "nonRenewingSubscriptions" : [

  ],
  "products" : [

  ],
  "settings" : {
    "_failTransactionsEnabled" : false,
    "_locale" : "en_US",
    "_storefront" : "USA",
    "_storeKitErrors" : [
      {
        "current" : null,
        "enabled" : false,
        "name" : "Load Products"
      },
      {
        "current" : null,
        "enabled" : false,
        "name" : "Purchase"
      },
      {
        "current" : null,
        "enabled" : false,
        "name" : "Verification"
      },
      {
        "current" : null,
        "enabled" : false,
        "name" : "App Store Sync"
      },
      {
        "current" : null,
        "enabled" : false,
        "name" : "Subscription Status"
      },
      {
        "current" : null,
        "enabled" : false,
        "name" : "App Transaction"
      },
      {
        "current" : null,
        "enabled" : false,
        "name" : "Manage Subscriptions Sheet"
      },
      {
        "current" : null,
        "enabled" : false,
        "name" : "Refund Request Sheet"
      },
      {
        "current" : null,
        "enabled" : false,
        "name" : "Offer Code Redeem Sheet"
      }
    ]
  },
  "subscriptionGroups" : [

  ],
  "version" : {
    "major" : 3,
    "minor" : 0
  }
}
EOF
    green "✓ Created PollyStoreKit.storekit configuration file"
    echo "Add this file to your Xcode project and configure it in your scheme."
    echo
fi

bold "Summary:"
echo "The StoreKit eligibilityd warning is a harmless simulator issue."
echo "If your app runs correctly, you can safely ignore the warning."
echo "Use the options above only if the warnings are excessive or problematic."
echo
green "✓ Script completed"