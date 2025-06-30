//
//  NewsService.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import Foundation

// RSS Feed Sources - Free and reliable
struct RSSSource: Decodable {
    let name: String
    let url: URL
    let category: String
    
    static func loadSources() -> [RSSSource] {
        guard let url = Bundle.main.url(forResource: "RSSFeeds", withExtension: "json") else {
            fatalError("RSSFeeds.json not found")
        }
        
        do {
            let data = try Data(contentsOf: url)
            let sources = try JSONDecoder().decode([RSSSource].self, from: data)
            return sources
        } catch {
            fatalError("Failed to decode RSSFeeds.json: \(error)")
        }
    }
}

enum NewsError: Error, LocalizedError {
    case invalidURL
    case noArticles
    case invalidResponse
    case networkUnavailable
    case parsingFailed
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid news URL"
        case .noArticles:
            return "No news articles found"
        case .invalidResponse:
            return "Invalid response from news service"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .parsingFailed:
            return "Failed to parse news data"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noArticles:
            return "Try again later or check different news sources"
        case .networkUnavailable:
            return "Check your internet connection"
        default:
            return "Please try again later"
        }
    }
}

actor NewsService: NewsServiceProtocol {
    private let session: URLSession
    private let maxArticlesPerSource = 5
    private let dateFormatter: DateFormatter
    
    init(session: URLSession = .shared) {
        self.session = session
        self.dateFormatter = DateFormatter()
        // RSS feeds typically use RFC 2822 format
        self.dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    }
    
    func fetchDailyNews() async throws -> [NewsArticle] {
        var allArticles: [NewsArticle] = []
        let sources = RSSSource.loadSources()
        
        // Fetch from multiple RSS sources concurrently
        await withTaskGroup(of: [NewsArticle].self) { group in
            for source in sources {
                group.addTask {
                    do {
                        return try await self.fetchRSSFeed(from: source)
                    } catch {
                        // Log error but don't fail entire operation
                        print("Failed to fetch from \(source.name): \(error)")
                        return []
                    }
                }
            }
            
            for await articles in group {
                allArticles.append(contentsOf: articles)
            }
        }
        
        // Sort by publication date (newest first) and limit total articles
        let sortedArticles = allArticles
            .sorted { $0.publishedAt > $1.publishedAt }
            .prefix(20)
        
        if sortedArticles.isEmpty {
            throw NewsError.noArticles
        }
        
        return Array(sortedArticles)
    }
    
    private func fetchRSSFeed(from source: RSSSource) async throws -> [NewsArticle] {
        do {
            let (data, response) = try await session.data(from: source.url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NewsError.invalidResponse
            }
            
            return try parseRSSFeed(data: data, source: source)
            
        } catch {
            if error.isNetworkError {
                throw NewsError.networkUnavailable
            } else {
                throw error
            }
        }
    }
    
    private func parseRSSFeed(data: Data, source: RSSSource) throws -> [NewsArticle] {
        let parser = RSSParser()
        let rssItems = try parser.parse(data: data)
        
        return rssItems.prefix(maxArticlesPerSource).compactMap { item in
            guard let title = item.title, !title.isEmpty else { return nil }
            
            let publishedDate = item.pubDate.flatMap { 
                self.dateFormatter.date(from: $0) ?? self.parseAlternativeDate($0)
            } ?? Date()
            
            return NewsArticle(
                title: title,
                description: item.description,
                content: item.content,
                publishedAt: publishedDate,
                source: NewsSource(name: source.name, id: source.name.lowercased().replacingOccurrences(of: " ", with: "-")),
                url: item.link.flatMap { URL(string: $0) }
            )
        }
    }
    
    private func parseAlternativeDate(_ dateString: String) -> Date? {
        // Try alternative date formats
        let alternativeFormats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd HH:mm:ss",
            "MMM dd, yyyy"
        ]
        
        for format in alternativeFormats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
}

// MARK: - RSS Parser

struct RSSItem {
    let title: String?
    let description: String?
    let content: String?
    let link: String?
    let pubDate: String?
}

class RSSParser: NSObject, XMLParserDelegate {
    private var items: [RSSItem] = []
    private var currentElement: String = ""
    private var currentTitle: String = ""
    private var currentDescription: String = ""
    private var currentContent: String = ""
    private var currentLink: String = ""
    private var currentPubDate: String = ""
    
    func parse(data: Data) throws -> [RSSItem] {
        items = []
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        guard parser.parse() else {
            throw NewsError.parsingFailed
        }
        
        return items
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "item" {
            currentTitle = ""
            currentDescription = ""
            currentContent = ""
            currentLink = ""
            currentPubDate = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
        case "title":
            currentTitle += string
        case "description":
            currentDescription += string
        case "content:encoded", "content":
            currentContent += string
        case "link":
            currentLink += string
        case "pubDate":
            currentPubDate += string
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            let item = RSSItem(
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                description: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines),
                link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                pubDate: currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            items.append(item)
        }
        currentElement = ""
    }
}

private extension Error {
    var isNetworkError: Bool {
        if let urlError = self as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut:
                return true
            default:
                return false
            }
        }
        return false
    }
}