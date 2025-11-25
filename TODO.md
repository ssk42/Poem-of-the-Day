# Poem of the Day: Development Roadmap

This document outlines the planned features and improvements for the "Poem of the Day" application.

---

### **Phase 1: Core Experience & User Engagement (Short-Term)**

This phase focuses on foundational improvements that add immediate value and encourage daily use.

*   **[ ] Poem History:**
    *   **Description:** Implement a scrollable list or calendar view where users can access and read poems from previous days.
    *   **Implementation Notes:**
        *   Extend `PoemRepository` to store and fetch a collection of past poems, not just the latest one.
        *   Create a new SwiftUI `View` called `PoemHistoryView` to display the list of poems.
        *   Consider using a `List` or `ScrollView` for the display. A `LazyVStack` would be efficient for performance.
        *   Each item in the list should be a tappable card that navigates to a detail view for that poem.

*   **[ ] Sharing Functionality:**
    *   **Description:** Add a "Share" button on the main poem view to allow users to share the daily poem's text or a stylized image to social media, messages, or other apps.
    *   **Implementation Notes:**
        *   Integrate the standard SwiftUI `ShareLink` for simple text sharing.
        *   For image sharing, create a new SwiftUI view that renders the poem in a visually appealing, shareable format.
        *   Use `ImageRenderer` to convert this SwiftUI view into a `UIImage` that can be passed to the share sheet.

*   **[ ] Daily Poem Notifications:**
    *   **Description:** Implement opt-in local notifications to remind users when their new poem for the day is ready.
    *   **Implementation Notes:**
        *   Use the `UserNotifications` framework.
        *   Request user permission for notifications at an appropriate time (e.g., on first app launch or from a settings screen).
        *   Schedule a daily repeating `UNNotificationRequest` to trigger at a user-friendly time (e.g., 8:00 AM).

*   **[ ] UI & UX Polish:**
    *   **Description:** Refine UI animations and transitions for a smoother experience.
    *   **Implementation Notes:**
        *   Use SwiftUI's `withAnimation` block to animate changes in view state.
        *   Implement custom `ViewModifier`s for reusable animation effects.
        *   Refine the `VibeGenerationView` with more engaging loading animations.

---

### **Phase 2: Personalization & Customization (Mid-Term)**

This phase empowers users to tailor the app to their preferences, making the experience more personal and engaging.

*   **[ ] Vibe Influence:**
    *   **Description:** Allow users to select preferred news categories (e.g., Technology, Arts, World News) to help guide the "vibe" analysis.
    *   **Implementation Notes:**
        *   Update `NewsService` to fetch articles from specific categories. This may require changes to the underlying news API or RSS feeds.
        *   Store user preferences in `UserDefaults` or a new settings model.
        *   Add a new view for users to manage their category preferences.

*   **[ ] Poem Style Selection:**
    *   **Description:** Introduce different poetic styles (e.g., Haiku, Sonnet, Free Verse) that users can choose from.
    *   **Implementation Notes:**
        *   Update the `PoemGenerationService` to accept a "style" parameter.
        *   The prompt sent to the generative AI should be modified to request a poem in the selected style.
        *   Add a UI element (e.g., a `Picker`) in the settings or main view to allow style selection.

*   **[ ] Favorites System:**
    *   **Description:** Enable users to mark specific poems as "favorites" for quick and easy access.
    *   **Implementation Notes:**
        *   Add a `isFavorite` boolean property to the `Poem` model.
        *   Update `PoemRepository` with methods to mark poems as favorites and fetch all favorite poems.
        *   Create a `FavoritesView` to display a list of favorited poems.
        *   Add a "Favorite" button (e.g., a star icon) to the poem detail view.

*   **[ ] Comprehensive Settings Screen:**
    *   **Description:** Create a dedicated settings view to manage notifications, vibe preferences, poem styles, and other app settings.
    *   **Implementation Notes:**
        *   Create a `SettingsView` using a `Form` to present the various options.
        *   Use `@AppStorage` property wrappers to easily bind UI controls to `UserDefaults`.

---

### **Phase 3: Advanced Features & Ecosystem (Long-Term)**

This phase focuses on expanding the app's reach and technical capabilities.

*   **[ ] iCloud Sync:**
    *   **Description:** Sync poem history, favorites, and user preferences across a user's devices.
    *   **Implementation Notes:**
        *   Use `CoreData` with iCloud syncing capabilities (`NSPersistentCloudKitContainer`).
        *   Refactor `PoemRepository` to use Core Data as its backing store instead of `UserDefaults` or JSON files.
        *   Ensure proper handling of data merging and conflicts.

*   **[ ] iPad and macOS Support:**
    *   **Description:** Design and build dedicated user interfaces optimized for iPad and macOS.
    *   **Implementation Notes:**
        *   Use adaptive SwiftUI views that work well on different screen sizes.
        *   Employ `NavigationSplitView` for a multi-column layout on larger screens.
        *   Create a separate macOS target in the Xcode project.

*   **[ ] Interactive Widgets:**
    *   **Description:** Enhance the home screen widgets to be more interactive.
    *   **Implementation Notes:**
        *   Use the `WidgetKit` framework and App Intents.
        *   Create intents that allow users to trigger actions like "Show Next Favorite" or "Generate New Poem" directly from the widget.

*   **[ ] Monetization (Optional):**
    *   **Description:** Introduce a "Poem of the Day Pro" via a one-time In-App Purchase.
    *   **Implementation Notes:**
        *   Use the `StoreKit` framework to handle In-App Purchases.
        *   Create a `StoreManager` class to encapsulate the logic for purchasing and restoring products.
        *   Gate access to premium features based on the user's purchase status.
