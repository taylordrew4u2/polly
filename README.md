# Polly

A SwiftUI application built with SwiftData for iOS and macOS.

## Requirements

- Xcode 16.4 or later
- iOS 18.5+ / macOS (compatible version)
- Swift 5.0+

## Getting Started

1. Clone this repository
2. Open `polly.xcodeproj` in Xcode
3. Select your target device or simulator
4. Build and run the project (⌘+R)

## Project Structure

- `polly/` - Main application source code
  - `pollyApp.swift` - App entry point with SwiftData container setup
  - `ContentView.swift` - Main user interface
  - `Item.swift` - SwiftData model for items
- `pollyTests/` - Unit tests
- `pollyUITests/` - UI tests

## Features

- SwiftUI-based user interface
- SwiftData for data persistence
- Support for iOS and macOS
- Unit and UI testing support

## Development

The project uses:
- SwiftUI for the user interface
- SwiftData for data management
- Xcode's built-in testing framework

### Building and Testing

- Build: ⌘+B
- Run: ⌘+R
- Test: ⌘+U

## Contributing

When contributing to this project:
1. Ensure your changes don't break existing functionality
2. Add tests for new features
3. Follow Swift coding conventions
4. Update documentation as needed