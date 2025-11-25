# 📖 Poem of the Day

> *Experience poetry that adapts to the world around you*

![iOS](https://img.shields.io/badge/iOS-18.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-green.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

An intelligent iOS poetry app that curates daily poems and creates AI-generated verse based on real-world sentiment analysis. The app features dynamic background colors that respond to daily emotional vibes, creating an immersive and emotionally resonant poetry experience.

## ✨ Features

### 🎨 **Dynamic Vibe Backgrounds** *(New!)*
- **Intelligent Color Adaptation**: Background colors automatically change based on daily news sentiment analysis
- **10 Unique Mood Palettes**: Each vibe (Hopeful, Energetic, Peaceful, etc.) has carefully crafted color schemes
- **Light & Dark Mode Support**: Adaptive colors for both system themes
- **Smooth Transitions**: Elegant 1.0-second animations between mood changes
- **Intensity Scaling**: Color vibrancy adjusts based on confidence and emotional intensity

### 📚 **Poetry Experience**
- **Daily Curated Poems**: Hand-selected poetry updated daily
- **Favorite Poems**: Save and organize your favorite verses
- **Share Functionality**: Share poems with friends and social media
- **Beautiful Typography**: Optimized reading experience with serif fonts
- **Accessibility Support**: VoiceOver, Dynamic Type, and high contrast support

### 🤖 **AI-Powered Poetry Generation**
- **Vibe-Based Poems**: AI generates poetry matching the current daily mood
- **Custom Prompts**: Create personalized poems with your own topics
- **Smart Context**: AI considers current news sentiment and emotional tone
- **Multiple Styles**: Various poetry forms and styles available

### 📰 **Intelligent Vibe Analysis**
- **Real-time News Analysis**: Processes current news to determine daily emotional tone
- **10 Distinct Vibes**: Hopeful, Contemplative, Energetic, Peaceful, Melancholic, Inspiring, Uncertain, Celebratory, Reflective, Determined
- **Sentiment Scoring**: Advanced algorithms analyze positivity, energy, and complexity
- **Visual Indicators**: Color-coded vibe display with intensity feedback

### 📱 **Widgets & Integration**
- **Home Screen Widgets**: Display daily poems directly on your home screen
- **Widget Synchronization**: Real-time updates with the main app
- **Multiple Sizes**: Support for various widget configurations
- **Background Updates**: Automatic content refresh

### 📊 **Analytics & Insights**
- **Privacy-First Telemetry**: Optional usage analytics with full transparency
- **Performance Monitoring**: App performance and user experience tracking
- **Debug Console**: Advanced debugging tools for development

## 🏗️ Technical Architecture

### **SwiftUI + Modern Swift**
- **Native SwiftUI**: Pure SwiftUI implementation with iOS 18+ features
- **MVVM Architecture**: Clean separation of concerns with ViewModels
- **Async/Await**: Modern Swift concurrency throughout
- **Combine Framework**: Reactive data binding and state management

### **AI & Machine Learning**
- **Sentiment Analysis Engine**: Custom algorithm for news emotion detection
- **Keyword Extraction**: Intelligent content analysis and categorization
- **Confidence Scoring**: Probabilistic assessment of mood classifications
- **Background Color Intelligence**: Dynamic color selection based on emotional state

### **Data & Storage**
- **Core Data Integration**: Persistent storage for favorites and user data
- **News API Integration**: Real-time news fetching and processing
- **Caching Strategy**: Intelligent data caching for offline functionality
- **Migration Support**: Seamless data migration between app versions

### **Testing Excellence**
- **250+ Test Functions**: Comprehensive test coverage across 27 test files
- **Unit Tests (150 functions)**: Core logic, models, services, and AI components
- **UI Tests (100 functions)**: Complete user interface and interaction testing
- **Performance Tests**: Memory usage, launch time, and responsiveness validation
- **Accessibility Tests**: VoiceOver, Dynamic Type, and inclusive design verification

## 🎨 Vibe Color Palettes

| Vibe | Light Mode | Dark Mode | Description |
|------|------------|-----------|-------------|
| **Hopeful** | Sunrise gold & warm amber | Deep gold & rich amber | Warm, optimistic tones inspiring positivity |
| **Energetic** | Vibrant orange & coral | Electric orange & crimson | High-energy colors that invigorate and motivate |
| **Peaceful** | Soft sage & tranquil blue | Forest green & midnight blue | Calming nature-inspired hues for serenity |
| **Melancholic** | Muted lavender & soft gray | Deep purple & charcoal | Gentle, introspective colors for contemplation |
| **Contemplative** | Thoughtful blue & periwinkle | Navy & deep indigo | Intellectual tones encouraging deep thinking |
| **Inspiring** | Rich gold & champagne | Bronze & burnished gold | Luxurious colors that spark creativity |
| **Celebratory** | Bright coral & festive pink | Magenta & deep rose | Joyful, party-like colors for special moments |
| **Reflective** | Soft indigo & lavender mist | Deep violet & midnight purple | Introspective shades for self-examination |
| **Determined** | Strong teal & ocean blue | Steel blue & deep teal | Confident colors representing strength and resolve |
| **Uncertain** | Gentle gray & cloudy blue | Storm gray & slate blue | Neutral tones reflecting ambiguity and questioning |

## 🚀 Getting Started

### Prerequisites
- Xcode 16.0+
- iOS 18.0+ deployment target
- macOS 14.0+ for development
- Apple Developer account (for device testing)
- Bazelisk (for Bazel builds) - optional

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/poem-of-the-day.git
 can 
   ```

2. **Choose your build system:**

   **Option A: Xcode (Traditional)**
   ```bash
   open "Poem of the Day.xcodeproj"
   # Press Cmd+R to build and run
   ```

   **Option B: Bazel (Recommended for CI/CD)**
   ```bash
   # Install Bazelisk
   brew install bazelisk
   
   # Make the helper script executable
   chmod +x bazel.sh
   
   # Build the app
   ./bazel.sh build
   
   # Run tests
   ./bazel.sh test
   ```

3. **Configure API Keys** *(Optional)*
   - Add news API credentials to `AppConfiguration.swift`
   - Configure AI service endpoints if using external providers

4. **Build and Run**
   - **Xcode**: Select your target device or simulator, press `Cmd+R`
   - **Bazel**: Run `./bazel.sh build` then deploy to simulator

### Configuration

Create a `Config.plist` file with your API configurations:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NewsAPIKey</key>
    <string>your-news-api-key</string>
    <key>AIServiceEndpoint</key>
    <string>your-ai-service-url</string>
</dict>
</plist>
```

## 🧪 Testing

### Running Tests

**With Bazel (Recommended)**
```bash
# All tests
./bazel.sh test

# Unit tests only
./bazel.sh unit-test

# UI tests only
./bazel.sh ui-test

# Generate coverage report
./bazel.sh coverage

# Run CI pipeline locally
./bazel.sh ci
```

**With Xcode**
```bash
# All Tests
xcodebuild test -scheme "Poem of the Day" -destination "platform=iOS Simulator,name=iPhone 16"

# Unit Tests Only
xcodebuild test -scheme "Poem of the Day" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:"Poem of the DayTests"

# UI Tests Only
xcodebuild test -scheme "Poem of the Day" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:"Poem of the DayUITests"

# Background Color Tests
xcodebuild test -scheme "Poem of the Day" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:"Poem of the DayTests/VibeAnalyzerTests"
```

For detailed Bazel build and test instructions, see [BAZEL_BUILD.md](BAZEL_BUILD.md).

### Test Coverage

- **Core Logic**: 95%+ coverage of business logic and data models
- **UI Components**: 100% coverage of user interface flows
- **AI Features**: Comprehensive testing of sentiment analysis and poem generation
- **Background Colors**: Complete validation of vibe-based color system
- **Accessibility**: Full VoiceOver and Dynamic Type support verification
- **Performance**: Memory usage, launch time, and responsiveness benchmarks
- **Edge Cases**: Error handling, network failures, and data corruption scenarios

## 📁 Project Structure

```
Poem of the Day/
├── 📱 App/
│   ├── Poem_of_the_DayApp.swift          # App entry point
│   └── AppConfiguration.swift            # Configuration and environment setup
├── 🎨 Views/
│   ├── Screens/
│   │   ├── ContentView.swift             # Main app interface with dynamic backgrounds
│   │   ├── VibeGenerationView.swift      # AI poem generation interface
│   │   └── TelemetryDebugView.swift      # Analytics debug console
│   └── Components/
│       ├── LoadingView.swift             # Loading states and animations
│       └── ErrorView.swift               # Error handling and recovery
├── 🧠 Models/
│   ├── Poem.swift                        # Core poem data model
│   ├── VibeModels.swift                  # Vibe analysis and color definitions
│   └── PoemError.swift                   # Error types and handling
├── ⚙️ Services/
│   ├── VibeAnalyzer.swift               # AI sentiment analysis and color calculation
│   ├── PoemGenerationService.swift      # AI poem creation
│   ├── NewsService.swift                # News fetching and processing
│   ├── PoemRepository.swift             # Data persistence and favorites
│   ├── TelemetryService.swift           # Analytics and performance monitoring
│   └── NetworkService.swift             # HTTP networking and API calls
├── 🎯 ViewModels/
│   └── PoemViewModel.swift               # Main app state and business logic
├── 🧪 Tests/
│   ├── Core/                            # Unit tests for business logic
│   ├── Platform/                        # Device and platform-specific tests
│   ├── Security/                        # Security and input validation tests
│   ├── Performance/                     # Performance and optimization tests
│   ├── Localization/                    # Multi-language support tests
│   ├── Migration/                       # Data migration and compatibility tests
│   ├── Background/                      # Background processing tests
│   └── EdgeCases/                       # Edge case and error scenario tests
└── 🧪 UITests/
    ├── VibeBackgroundColorUITests.swift # Background color system validation
    ├── AIFeaturesUITests.swift          # AI functionality user interface tests
    ├── AccessibilityUITests.swift       # Accessibility and inclusive design tests
    └── PerformanceUITests.swift         # UI performance and responsiveness tests
```

## 🔄 Recent Updates

### v2.1.0 - Dynamic Background Colors
- ✨ **New Vibe-Based Backgrounds**: 10 unique color palettes responding to daily mood
- 🎨 **Intelligent Color Intensity**: Dynamic color strength based on sentiment confidence
- 🌙 **Enhanced Dark Mode**: Adaptive color schemes for both light and dark themes
- ⚡ **Smooth Animations**: 1-second transitions between background changes
- 🧪 **Comprehensive Testing**: 20+ new tests for color system validation

### v2.0.0 - AI Poetry Generation
- 🤖 **AI-Powered Poems**: Generate custom poetry based on current vibe
- 📰 **News Sentiment Analysis**: Real-time mood detection from current events
- 🎯 **Custom Prompts**: User-directed poem generation
- 📊 **Advanced Analytics**: Enhanced telemetry and performance monitoring

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass (`xcodebuild test`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to your branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftLint for code formatting
- Include comprehensive test coverage
- Document public APIs with Swift DocC

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Poetry Database**: Curated collection of public domain poetry
- **News APIs**: Real-time news sentiment analysis providers
- **AI Services**: Machine learning models for text generation and analysis
- **Open Source Community**: Libraries and frameworks that made this possible

## 📞 Support

- 🐛 **Bug Reports**: [Create an issue](https://github.com/your-username/poem-of-the-day/issues)
- 💡 **Feature Requests**: [Discussion board](https://github.com/your-username/poem-of-the-day/discussions)
- 📧 **Contact**: support@poemoftheday.app
- 📚 **Documentation**: [Wiki](https://github.com/your-username/poem-of-the-day/wiki)

---

*Made with ❤️ and Swift*
