import SwiftUI
import WidgetKit
import Combine

struct Poem_Of_The_Day_WidgetEntry: TimelineEntry {
    let date: Date
    let poem: Poem
}
// 

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Poem_Of_The_Day_WidgetEntry {
        Poem_Of_The_Day_WidgetEntry(date: Date(), poem: Poem(title: "Placeholder Poem", lines: ["This is a placeholder poem."]))
    }

    func getSnapshot(in context: Context, completion: @escaping (Poem_Of_The_Day_WidgetEntry) -> Void) {
        let entry = Poem_Of_The_Day_WidgetEntry(date: Date(), poem: Poem(title: "Snapshot Poem", lines: ["This is a snapshot poem."]))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Poem_Of_The_Day_WidgetEntry>) -> Void) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.stevereitz.poemoftheday")
        var poem: Poem? = nil
        
        if let title = sharedDefaults?.string(forKey: "poemTitle"),
           let content = sharedDefaults?.string(forKey: "poemContent") {
            poem = Poem(title: title, lines: content.components(separatedBy: "\n"))
            if let finalPoem = poem {
                createTimeline(with: finalPoem, completion: completion)
                return
            }
        }
        
        // If no poem is found in shared storage, fetch a new one
        guard let url = URL(string: "https://poetrydb.org/random") else {
            let placeholderPoem = Poem(title: "Placeholder Poem", lines: ["This is a placeholder poem."])
            createTimeline(with: placeholderPoem, completion: completion)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let poems = try? JSONDecoder().decode([PoemResponse].self, from: data), let firstPoem = poems.first {
                let fetchedPoem = firstPoem.toPoem()
                poem = fetchedPoem
                // Save poem to shared UserDefaults for the app
                sharedDefaults?.set(poem?.title, forKey: "poemTitle")
                sharedDefaults?.set(poem?.content, forKey: "poemContent")
            } else {
                poem = Poem(title: "Error Fetching Poem", lines: ["Unable to fetch the poem at this time."])
            }
            
            if let finalPoem = poem {
                createTimeline(with: finalPoem, completion: completion)
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

    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.poem.title)
                .font(.headline)
                .padding(.bottom, 5)
            Text(entry.poem.content)
                .font(.body)
                .lineLimit(3)
        }
        .padding()
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
