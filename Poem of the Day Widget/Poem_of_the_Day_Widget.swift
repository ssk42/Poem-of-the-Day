import SwiftUI
import WidgetKit
import Combine

struct Poem_Of_The_Day_WidgetEntry: TimelineEntry {
    let date: Date
    let poem: WidgetPoem
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Poem_Of_The_Day_WidgetEntry {
        Poem_Of_The_Day_WidgetEntry(date: Date(), poem: WidgetPoem(id: UUID(), title: "Placeholder Poem", lines: ["This is a placeholder poem."], author: "Widget"))
    }

    func getSnapshot(in context: Context, completion: @escaping (Poem_Of_The_Day_WidgetEntry) -> Void) {
        let entry = Poem_Of_The_Day_WidgetEntry(date: Date(), poem: WidgetPoem(id: UUID(), title: "Snapshot Poem", lines: ["This is a snapshot poem."], author: "Widget"))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Poem_Of_The_Day_WidgetEntry>) -> Void) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.stevereitz.poemoftheday")
        var poem: WidgetPoem? = nil

        // Load poem from shared defaults
        if let title = sharedDefaults?.string(forKey: "poemTitle"),
           let content = sharedDefaults?.string(forKey: "poemContent") {
            let author = sharedDefaults?.string(forKey: "poemAuthor")
            var vibe = sharedDefaults?.string(forKey: "poemVibe")
            
            // Fallback: If no poem-specific vibe, try to load from cached vibe analysis
            if vibe == nil || vibe?.isEmpty == true {
                if let vibeData = sharedDefaults?.data(forKey: "cachedVibeAnalysis"),
                   let vibeAnalysis = try? JSONDecoder().decode(VibeAnalysis.self, from: vibeData) {
                    vibe = vibeAnalysis.vibe.rawValue
                }
            }
            
            poem = WidgetPoem(id: UUID(), title: title, lines: content.components(separatedBy: "\n"), author: author, vibe: vibe)
        }
        
        // Check if we should fetch a new poem based on date
        let calendar = Calendar.current
        let now = Date()
        var shouldFetchNewPoem = false
        
        if let lastFetchDate = sharedDefaults?.object(forKey: "lastPoemFetchDate") as? Date {
            // Check if the last fetch is from a previous day
            if !calendar.isDate(lastFetchDate, inSameDayAs: now) {
                shouldFetchNewPoem = true
            }
        } else {
            // No last fetch date, should fetch
            shouldFetchNewPoem = true
        }
        
        if poem != nil && !shouldFetchNewPoem {
            // We have a poem and don't need to fetch a new one
            createTimeline(with: poem!, completion: completion)
            return
        }

        // Fetch a new poem from PoetryDB if needed
        fetchPoemFromPoetryDB { fetchedPoem in
            if let finalPoem = fetchedPoem {
                // Save the fetched poem
                sharedDefaults?.set(finalPoem.title, forKey: "poemTitle")
                sharedDefaults?.set(finalPoem.content, forKey: "poemContent")
                sharedDefaults?.set(finalPoem.author ?? "", forKey: "poemAuthor")
                // Note: We don't have vibe data when fetching randomly from PoetryDB in the widget
                // In a real scenario, the main app should push the vibe-checked poem
                
                // Save current date as fetch date
                sharedDefaults?.set(Date(), forKey: "lastPoemFetchDate")
                
                createTimeline(with: finalPoem, completion: completion)
            } else if let existingPoem = poem {
                // Use existing poem if fetch failed
                createTimeline(with: existingPoem, completion: completion)
            } else {
                // Provide a default poem if we have no poem at all
                let defaultPoem = WidgetPoem(id: UUID(), title: "Default Poem", lines: ["Check the app for a new poem!"], author: "Widget")
                createTimeline(with: defaultPoem, completion: completion)
            }
        }
    }

    private func fetchPoemFromPoetryDB(completion: @escaping (WidgetPoem?) -> Void) {
        guard let url = URL(string: "https://poetrydb.org/random") else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let poems = try? JSONDecoder().decode([WidgetPoemResponse].self, from: data), let firstPoem = poems.first {
                let fetchedPoem = firstPoem.toPoem()
                completion(fetchedPoem)
            } else {
                completion(nil)
            }
        }.resume()
    }

    private func createTimeline(with poem: WidgetPoem, completion: @escaping (Timeline<Poem_Of_The_Day_WidgetEntry>) -> Void) {
        let calendar = Calendar.current
        let currentDate = Date()
        var entries: [Poem_Of_The_Day_WidgetEntry] = []

        // Create an entry for today
        let todayEntry = Poem_Of_The_Day_WidgetEntry(date: currentDate, poem: poem)
        entries.append(todayEntry)
        
        // Calculate midnight of the next day
        let midnight = calendar.startOfDay(for: currentDate)
        if let nextMidnight = calendar.date(byAdding: .day, value: 1, to: midnight) {
            // Create an entry that triggers exactly at midnight
            let nextDayEntry = Poem_Of_The_Day_WidgetEntry(date: nextMidnight, poem: poem)
            entries.append(nextDayEntry)
        }

        // Set the timeline to update at midnight
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct Poem_Of_The_Day_WidgetView: View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        ZStack {
            // Background gradient - always use vibe color if available
            vibeBackgroundGradient
            
            VStack(alignment: .leading, spacing: widgetSpacing) {
                // Title with vibe emoji for small widget
                HStack(spacing: 4) {
                    if widgetFamily == .systemSmall, let vibeRaw = entry.poem.vibe, let vibe = DailyVibe(rawValue: vibeRaw) {
                        Text(vibe.emoji)
                            .font(.caption)
                    }
                    Text(entry.poem.title)
                        .font(titleFont)
                        .lineLimit(widgetFamily == .systemSmall ? 1 : 2)
                }
                .padding(.bottom, widgetFamily == .systemSmall ? 0 : 2)
                
                Text(entry.poem.content)
                    .font(contentFont)
                    .lineLimit(contentLineLimit)
                    .lineSpacing(widgetFamily == .systemSmall ? 1 : 2)
                
                Spacer(minLength: 0)
                
                // Author - hide on small if needed for space
                if widgetFamily != .systemSmall, let author = entry.poem.author, !author.isEmpty {
                    HStack {
                        Spacer()
                        Text("— \(author)")
                            .font(.caption2)
                            .italic()
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(widgetPadding)
        }
    }
    
    // MARK: - Size-Specific Properties
    
    private var vibeBackgroundGradient: some View {
        Group {
            if let vibeRaw = entry.poem.vibe, let vibe = DailyVibe(rawValue: vibeRaw) {
                vibe.backgroundGradient(for: colorScheme)
            } else {
                // Default gradient when no vibe
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.2) : Color(red: 0.9, green: 0.95, blue: 1.0),
                        colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color(red: 0.8, green: 0.9, blue: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    private var titleFont: Font {
        switch widgetFamily {
        case .systemSmall:
            return .system(size: 12, weight: .semibold, design: .serif)
        case .systemMedium:
            return .system(size: 14, weight: .semibold, design: .serif)
        case .systemLarge, .systemExtraLarge:
            return .headline
        @unknown default:
            return .headline
        }
    }
    
    private var contentFont: Font {
        switch widgetFamily {
        case .systemSmall:
            return .system(size: 11, weight: .regular, design: .serif)
        case .systemMedium:
            return .system(size: 13, weight: .regular, design: .serif)
        case .systemLarge, .systemExtraLarge:
            return .system(size: 15, weight: .regular, design: .serif)
        @unknown default:
            return .system(size: 14, weight: .regular, design: .serif)
        }
    }
    
    private var contentLineLimit: Int {
        switch widgetFamily {
        case .systemSmall:
            return 8  // More lines with smaller text
        case .systemMedium:
            return 5
        case .systemLarge, .systemExtraLarge:
            return 12
        @unknown default:
            return 6
        }
    }
    
    private var widgetSpacing: CGFloat {
        switch widgetFamily {
        case .systemSmall:
            return 4
        case .systemMedium:
            return 6
        default:
            return 8
        }
    }
    
    private var widgetPadding: CGFloat {
        switch widgetFamily {
        case .systemSmall:
            return 10
        case .systemMedium:
            return 12
        default:
            return 16
        }
    }
}

struct Poem_Of_The_Day_Widget: Widget {
    let kind: String = "Poem_Of_The_Day_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            Poem_Of_The_Day_WidgetView(entry: entry)
        }
        .configurationDisplayName("Poem of the Day")
        .description("Get a new poem every day on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// Widget-specific data models (duplicated for widget target isolation)
struct WidgetPoem: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    let author: String?
    let vibe: String?
    let vibeEmoji: String?

    init(id: UUID = UUID(), title: String, lines: [String], author: String? = nil, vibe: String? = nil, vibeEmoji: String? = nil) {
        self.id = id
        self.title = title
        self.content = lines.joined(separator: "\n")
        self.author = author?.isEmpty == true ? nil : author
        self.vibe = vibe
        self.vibeEmoji = vibeEmoji
    }
}

struct WidgetPoemResponse: Codable {
    let title: String
    let lines: [String]
    let author: String
    
    func toPoem() -> WidgetPoem {
        // Random poems from PoetryDB don't have vibes
        return WidgetPoem(id: UUID(), title: title, lines: lines, author: author)
    }
}
