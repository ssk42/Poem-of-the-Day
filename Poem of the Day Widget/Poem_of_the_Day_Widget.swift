import SwiftUI
import WidgetKit
import Combine

struct Poem_Of_The_Day_WidgetEntry: TimelineEntry {
    let date: Date
    let poem: Poem
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Poem_Of_The_Day_WidgetEntry {
        Poem_Of_The_Day_WidgetEntry(date: Date(), poem: Poem(id: UUID(), title: "Placeholder Poem", lines: ["This is a placeholder poem."], author: "Widget"))
    }

    func getSnapshot(in context: Context, completion: @escaping (Poem_Of_The_Day_WidgetEntry) -> Void) {
        let entry = Poem_Of_The_Day_WidgetEntry(date: Date(), poem: Poem(id: UUID(), title: "Snapshot Poem", lines: ["This is a snapshot poem."], author: "Widget"))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Poem_Of_The_Day_WidgetEntry>) -> Void) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.stevereitz.poemoftheday")
        var poem: Poem? = nil

        if let title = sharedDefaults?.string(forKey: "poemTitle"),
           let content = sharedDefaults?.string(forKey: "poemContent"),
           let author = sharedDefaults?.string(forKey: "poemAuthor") {
            poem = Poem(id: UUID(), title: title, lines: content.components(separatedBy: "\n"), author: author)
            if let finalPoem = poem {
                createTimeline(with: finalPoem, completion: completion)
                return
            }
        }

        // Fetch poem from PoetryDB
        fetchPoemFromPoetryDB { fetchedPoem in
            if let finalPoem = fetchedPoem {
                createTimeline(with: finalPoem, completion: completion)
            } else {
                // Provide a default poem if we couldn't fetch one
                let defaultPoem = Poem(id: UUID(), title: "Default Poem", lines: ["Check the app for a new poem!"], author: "Widget")
                createTimeline(with: defaultPoem, completion: completion)
            }
        }
    }

    private func fetchPoemFromPoetryDB(completion: @escaping (Poem?) -> Void) {
        guard let url = URL(string: "https://poetrydb.org/random") else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let poems = try? JSONDecoder().decode([PoemResponse].self, from: data), let firstPoem = poems.first {
                let fetchedPoem = firstPoem.toPoem()
                completion(fetchedPoem)
            } else {
                completion(nil)
            }
        }.resume()
    }

    private func createTimeline(with poem: Poem, completion: @escaping (Timeline<Poem_Of_The_Day_WidgetEntry>) -> Void) {
        let currentDate = Date()
        var entries: [Poem_Of_The_Day_WidgetEntry] = []

        for offset in 0..<7 {
            if let entryDate = Calendar.current.date(byAdding: .day, value: offset, to: currentDate) {
                let entry = Poem_Of_The_Day_WidgetEntry(date: entryDate, poem: poem)
                entries.append(entry)
            }
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct Poem_Of_The_Day_WidgetView: View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.2) : Color(red: 0.9, green: 0.95, blue: 1.0),
                    colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color(red: 0.8, green: 0.9, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.poem.title)
                    .font(.headline)
                    .lineLimit(1)
                    .padding(.bottom, 2)
                
                Text(entry.poem.content)
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .lineLimit(6)
                    .lineSpacing(2)
                
                Spacer()
                
                if let author = entry.poem.author, !author.isEmpty {
                    HStack {
                        Spacer()
                        Text("— \(author)")
                            .font(.caption2)
                            .italic()
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
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

// Structs needed by the widget
struct Poem: Identifiable, Codable {
    let id: UUID?
    let title: String
    let content: String
    let author: String?

    init(id: UUID? = UUID(), title: String, lines: [String], author: String = "Unknown") {
        self.id = id
        self.title = title
        self.content = lines.joined(separator: "\n")
        self.author = author
    }
}

struct PoemResponse: Codable {
    let title: String
    let lines: [String]
    let author: String
    
    func toPoem() -> Poem {
        return Poem(id: UUID(), title: title, lines: lines, author: author)
    }
}
