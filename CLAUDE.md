# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Poem of the Day** is an iOS app with widget extension that delivers daily poetry to users. The app fetches poems from the PoetryDB API (https://poetrydb.org/random) and includes:

- Main iOS app with SwiftUI interface
- Home screen widget extension for iOS
- Favorites system with persistent storage
- Shared data between app and widget using App Groups
- Dark/light mode support with accessibility features

## Architecture

### Core Components

- **Main App**: `Poem of the Day/` - SwiftUI app with navigation, poem display, and favorites
- **Widget Extension**: `Poem of the Day Widget/` - iOS widget that shows daily poems on home screen
- **Shared Data**: Uses App Group `group.com.stevereitz.poemoftheday` for data sharing between app and widget
- **API Integration**: Fetches poems from PoetryDB API with error handling and retry logic

### Key Files

- `Poem.swift` - Core data models (`Poem`, `PoemResponse`) and API response handling
- `ContentView.swift` - Main app UI with `PoemViewModel` for state management
- `Poem_of_the_Day_Widget.swift` - Widget timeline provider and UI components
- Widget timeline updates at midnight daily and shares poem data via UserDefaults

### Data Flow

1. App checks if new poem needed (daily refresh logic)
2. Fetches from PoetryDB API if required
3. Stores in shared UserDefaults with App Group
4. Widget timeline provider reads shared data
5. Both app and widget display same daily poem

## Development Commands

### Building and Running
```bash
# Open project in Xcode
open "Poem of the Day.xcodeproj"

# Build from command line
xcodebuild -project "Poem of the Day.xcodeproj" -scheme "Poem of the Day" -configuration Debug build

# Build widget extension
xcodebuild -project "Poem of the Day.xcodeproj" -scheme "Poem of the Day WidgetExtension" -configuration Debug build
```

### Testing
```bash
# Run unit tests
xcodebuild test -project "Poem of the Day.xcodeproj" -scheme "Poem of the Day" -destination "platform=iOS Simulator,name=iPhone 15"

# Run specific test file
xcodebuild test -project "Poem of the Day.xcodeproj" -scheme "Poem of the Day" -only-testing:PoemTests -destination "platform=iOS Simulator,name=iPhone 15"

# Run UI tests
xcodebuild test -project "Poem of the Day.xcodeproj" -scheme "Poem of the Day" -only-testing:PoemUITests -destination "platform=iOS Simulator,name=iPhone 15"
```

### Test Plans
- `Poem of the Day.xctestplan` - Main test plan for unit and UI tests
- `TestPlan.xctestplan` - Additional test configuration

## Key Implementation Details

### Modern Architecture (Updated 2025)
- **Async/Await**: Full migration from Combine to modern Swift concurrency
- **Actor-based networking**: Thread-safe `NetworkService` using actors
- **Repository pattern**: Clean separation with `PoemRepository` for data management
- **Dependency injection**: `DependencyContainer` for testable, modular architecture
- **Modern SwiftUI**: Uses `NavigationStack` instead of deprecated `NavigationView`

### Daily Poem Logic
- App stores `lastPoemFetchDate` in shared UserDefaults
- Compares current date with last fetch date using `Calendar.isDate(_:inSameDayAs:)`
- Fetches new poem only when date changes (not on every app launch)
- Widget timeline refreshes at midnight using `Timeline(entries:policy:)`

### Error Handling
- Custom `PoemError` enum with localized descriptions and recovery suggestions
- Proper error propagation through async/await chain
- Network-specific error handling (timeouts, no connection, rate limiting)
- Graceful fallback to cached poems when API unavailable

### Concurrency & Thread Safety
- `NetworkService` actor ensures thread-safe API calls
- `PoemRepository` actor manages state mutations safely
- `@MainActor` view models ensure UI updates on main thread
- Async repository methods prevent blocking UI

### App Group Configuration
- Bundle identifier: `group.com.stevereitz.poemoftheday`  
- Shared between main app and widget extension
- Used for poem data, favorites, and sync timestamps

### Testing Strategy
- Comprehensive unit tests for new architecture layers
- `NetworkServiceTests` with mock URLSession for async networking
- `PoemRepositoryTests` with mock dependencies and actor testing
- `PoemViewModelTests` for UI state management
- Mock repositories and network services for isolated testing