# About This Project

"Poem of the Day" is an iOS application written in Swift and SwiftUI. Its core function is to generate a unique poem daily based on the "vibe" determined by analyzing current news headlines. The app also includes a home screen widget to display the daily poem.

## Key Technologies

- **Language:** Swift
- **UI Framework:** SwiftUI
- **Testing:** XCTest for unit and UI testing.
- **Project Management:** Xcode Project (`.xcodeproj`)

## Project Structure

The project is organized into several directories, following the MVVM (Model-View-ViewModel) design pattern.

-   **`Poem of the Day/`**: The main application target.
    -   **`Core/`**: Contains the `DependencyContainer` for dependency injection and core application protocols.
    -   **`Models/`**: Data models for the application, such as `Poem`, `PoemError`, and `VibeModels`.
    -   **`Services/`**: Handles business logic and data fetching.
        -   `NewsService`: Fetches news headlines.
        -   `VibeAnalyzer`: Analyzes news to determine a "vibe".
        -   `PoemGenerationService`: Generates poems based on the vibe.
        -   `PoemRepository`: Manages storing and retrieving poems.
        -   `NetworkService`: Provides generic networking capabilities.
    -   **`ViewModels/`**: Connects the Models to the Views. `PoemViewModel` prepares poem data for display.
    -   **`Views/`**: Contains the SwiftUI views.
        -   `Screens/`: Top-level views like `ContentView` and `VibeGenerationView`.
        -   `Components/`: Reusable UI components like `ErrorView` and `LoadingView`.
-   **`Poem of the Day Widget/`**: Contains the code for the home screen widget extension.
-   **`Poem of the DayTests/`**: Unit tests for the application logic, organized by feature (e.g., `Services`, `ViewModels`).
-   **`Poem of the DayUITests/`**: UI tests for the application.

## How to Build and Run

You can build, test, and run the application using Xcode.

1.  Open `Poem of the Day.xcodeproj` in Xcode.
2.  Select the "Poem of the Day" scheme.
3.  Choose a simulator or a connected device.
4.  Click the "Run" button.

To build from the command line, you can use `xcodebuild`:

```sh
xcodebuild build -scheme "Poem of the Day" -destination "generic/platform=iOS"
```

## Development Conventions

-   The app uses the **MVVM** architecture to separate concerns.
-   Dependencies are managed through a custom `DependencyContainer` for inversion of control and improved testability.
-   The app is designed to be asynchronous, handling network requests and poem generation in the background.
