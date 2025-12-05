//
//  VibeAnalyzer.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import Foundation
import NaturalLanguage

actor VibeAnalyzer: VibeAnalyzerProtocol {
    
    // MARK: - Keyword Dictionaries
    
    private let vibeKeywords: [DailyVibe: [String]]
    private let embedding: NLEmbedding?
    private var vibeVectors: [DailyVibe: [Double]] = [:]
    
    // AI Analyzer for iOS 26+
    private var aiAnalyzer: Any? // Holds AIVibeAnalyzer on supported devices
    
    init() {
        self.vibeKeywords = VibeAnalyzer.loadVibeKeywords()
        self.embedding = NLEmbedding.sentenceEmbedding(for: .english)
        
        if self.embedding == nil {
            AppLogger.shared.warning("NLEmbedding is NIL. Semantic analysis will be disabled.", category: .vibe)
        } else {
            AppLogger.shared.info("NLEmbedding loaded successfully.", category: .vibe)
        }
        
        // Pre-compute vibe vectors
        if let embedding = self.embedding {
            for vibe in DailyVibe.allCases {
                let keywords = self.vibeKeywords[vibe]?.prefix(5).joined(separator: " ") ?? ""
                let vibeDefinition = "\(vibe.displayName). \(vibe.description). \(keywords)"
                if let vector = embedding.vector(for: vibeDefinition) {
                    self.vibeVectors[vibe] = vector
                }
            }
            }

        
        // Initialize AI analyzer if available
        if #available(iOS 26, *) {
            self.aiAnalyzer = AIVibeAnalyzer()
        }
    }
    private static func loadVibeKeywords() -> [DailyVibe: [String]] {
        if let url = Bundle.main.url(forResource: "VibeKeywords", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let keywords = try JSONDecoder().decode([String: [String]].self, from: data)
                var vibeKeywords: [DailyVibe: [String]] = [:]
                for (key, value) in keywords {
                    if let vibe = DailyVibe(rawValue: key) {
                        vibeKeywords[vibe] = value.map { $0.lowercased() }
                    }
                }
                if !vibeKeywords.isEmpty { return vibeKeywords }
            } catch {
                // Fall through to defaults below
            }
        }
        // Fallback minimal defaults to avoid crashes if resource is missing or duplicated
        return [
            .hopeful: ["hope", "progress", "growth", "recovery", "optimistic", "peace", "breakthrough", "treatment", "new", "optimism", "discovery"],
            .contemplative: ["philosophy", "thought", "reflect", "ponder", "debate", "meaning", "questions", "society", "scholars", "discussion"],
            .energetic: ["surge", "rally", "boom", "race", "soar", "marathon", "runners", "competition", "electric", "excitement", "dynamic", "action"],
            .peaceful: ["calm", "tranquil", "serene", "nature", "green", "preserve", "sanctuary", "retreat", "soothing", "harmony"],
            .melancholic: ["farewell", "loss", "mourning", "rain", "autumn", "memorial", "remembering", "grief", "sadness"],
            .inspiring: ["inspire", "courage", "dream", "achieve", "triumph", "amazing", "major", "step", "forward"],
            .uncertain: ["uncertain", "doubt", "crossroads", "risk", "unknown"],
            .celebratory: ["celebrate", "victory", "win", "award", "festival"],
            .reflective: ["reflect", "memory", "lesson", "learned", "wisdom"],
            .determined: ["resolve", "commit", "focus", "persevere", "persist"],
            .nostalgic: ["memory", "remember", "past", "vintage", "heritage", "tradition", "childhood", "history"],
            .adventurous: ["explore", "journey", "discover", "venture", "quest", "frontier", "expedition", "voyage"],
            .whimsical: ["playful", "imaginative", "creative", "whimsy", "fancy", "peculiar", "quirky", "magic"],
            .urgent: ["immediate", "crisis", "pressing", "crucial", "critical", "urgent", "emergency", "deadline"],
            .triumphant: ["victory", "champion", "conquest", "prevail", "winning", "triumph", "success", "achieve"],
            .solemn: ["reverent", "serious", "dignified", "sacred", "honor", "memorial", "respect", "grave"],
            .playful: ["fun", "lighthearted", "joy", "game", "dance", "jest", "merry", "frolic"],
            .mysterious: ["enigma", "puzzle", "secret", "unknown", "hidden", "mystery", "riddle", "obscure"],
            .rebellious: ["defiant", "resist", "challenge", "rebel", "revolution", "uprising", "protest", "revolt"],
            .compassionate: ["kindness", "empathy", "care", "love", "tender", "compassion", "gentle", "caring"]
        ]
    }
    
    // Expanded sentiment and tone lexicons - 50-100 words per category
    private let positiveWords: Set<String> = [
        "good", "great", "excellent", "amazing", "wonderful", "fantastic", "positive", "successful", "beneficial", "helpful",
        "beautiful", "love", "joy", "happy", "pleased", "excited", "thrilled", "delighted", "proud", "grateful",
        "hope", "hopeful", "optimistic", "uplifting", "progress", "improve", "improved", "improving", "win", "wins",
        "victory", "growth", "strong", "strength", "resilient", "resilience", "bright", "promising", "breakthrough",
        "innovative", "innovation", "remarkable", "inspiring", "inspiration", "encouraging", "encourage", "cheer", "cheerful",
        "celebrate", "celebration", "advance", "advances", "achieve", "achievement", "achievements", "gain", "gains",
        "boost", "booming", "surge", "surging", "record", "records", "milestone", "relief", "recover", "recovery",
        "stability", "stable", "stabilize", "thriving", "thrive", "prosper", "prosperity", "peace", "peaceful",
        "calm", "serene", "tranquil", "brilliant", "outstanding", "superb", "marvelous", "magnificent", "splendid",
        "glorious", "triumphant", "victorious", "winning", "champion", "heroic", "admirable", "praiseworthy", "commendable",
        "favorable", "advantageous", "profitable", "rewarding", "satisfying", "fulfilling", "enjoyable", "pleasurable",
        "blissful", "ecstatic", "euphoric", "jubilant", "elated", "overjoyed", "content", "satisfied", "fulfilled",
        "blessed", "fortunate", "lucky", "privileged", "cherished", "treasured", "valued", "appreciated", "esteemed",
        "respected", "honored", "revered", "beloved", "adored", "cherished", "precious", "treasured", "prized"
    ]

    private let negativeWords: Set<String> = [
        "bad", "terrible", "awful", "horrible", "negative", "failed", "disaster", "crisis", "problem", "issue",
        "concern", "worry", "fear", "angry", "sad", "disappointed", "frustrated", "upset", "troubled", "disturbed",
        "alarmed", "decline", "declined", "declining", "fall", "fallen", "falling", "drop", "dropped", "drops",
        "slump", "slumped", "slumping", "collapse", "collapsed", "collapsing", "loss", "losses", "lose", "losing",
        "risk", "risks", "warning", "warnings", "threat", "threats", "threaten", "threatened", "violence", "violent",
        "conflict", "war", "wars", "deadly", "death", "deaths", "shooting", "shootings", "fraud", "scandal",
        "corruption", "lawsuit", "lawsuits", "shortage", "shortages", "scarcity", "recession", "inflation", "layoff",
        "layoffs", "unemployment", "bankrupt", "bankruptcy", "pollution", "contamination", "outbreak", "pandemic",
        "crash", "accident", "disruption", "disruptions", "strike", "strikes", "devastating", "catastrophic", "tragic",
        "tragedy", "mourning", "grief", "sorrow", "despair", "hopeless", "bleak", "grim", "dismal", "gloomy",
        "depressing", "depressed", "melancholy", "miserable", "wretched", "pitiful", "pathetic", "deplorable",
        "dreadful", "atrocious", "appalling", "shocking", "disturbing", "alarming", "frightening", "terrifying",
        "horrifying", "nightmarish", "chaotic", "turbulent", "unstable", "volatile", "dangerous", "hazardous",
        "risky", "perilous", "precarious", "vulnerable", "fragile", "weak", "failing", "struggling", "suffering",
        "hardship", "adversity", "misfortune", "calamity", "catastrophe", "ruin", "destruction", "devastation",
        "breakdown", "failure", "defeat", "setback", "obstacle", "barrier", "hindrance", "impediment", "difficulty"
    ]

    private let energyWords: Set<String> = [
        "fast", "quick", "rapid", "speed", "rush", "burst", "explosive", "dynamic", "intense", "powerful",
        "strong", "force", "drive", "push", "action", "move", "active", "energetic", "vibrant", "lively",
        "exciting", "thrilling", "surge", "rally", "spike", "spiking", "accelerate", "accelerating", "momentum",
        "charge", "charged", "ignite", "ignites", "ignited", "frenzy", "boom", "booming", "race", "racing",
        "storm", "storming", "rocket", "rocketing", "skyrocket", "soar", "soaring", "leap", "leaping", "jump",
        "jumping", "sprint", "sprinting", "breakneck", "feverish", "bustling", "bustle", "swift", "speedy",
        "hasty", "hurried", "urgent", "immediate", "instant", "sudden", "abrupt", "sharp", "fierce", "aggressive",
        "vigorous", "robust", "mighty", "potent", "forceful", "vigorous", "strenuous", "arduous", "intensive",
        "hectic", "frantic", "frenetic", "wild", "furious", "fierce", "savage", "ferocious", "intense", "extreme",
        "overwhelming", "overpowering", "dominating", "commanding", "authoritative", "decisive", "bold", "daring",
        "audacious", "courageous", "brave", "fearless", "valiant", "heroic", "gallant", "spirited", "animated",
        "enthusiastic", "passionate", "zealous", "ardent", "fervent", "fiery", "burning", "blazing", "scorching",
        "sizzling", "electric", "electrifying", "sparkling", "dazzling", "brilliant", "radiant", "glowing", "shining"
    ]

    private let calmWords: Set<String> = [
        "slow", "gentle", "soft", "quiet", "calm", "peaceful", "serene", "tranquil", "still", "steady", "stable",
        "balanced", "harmonious", "soothing", "relaxing", "comfortable", "easy", "smooth", "gradual", "patient",
        "mindful", "rest", "restful", "ease", "easeful", "light", "breeze", "breezy", "mellow", "lull",
        "hush", "gentleness", "unwind", "quietude", "placid", "composed", "collected", "leisurely", "unhurried",
        "cool", "cooling", "temperate", "moderate", "equilibrium", "peace", "tranquility", "serenity", "stillness",
        "silence", "hush", "quietness", "calmness", "composure", "poise", "dignity", "grace", "elegance", "refinement",
        "delicate", "subtle", "tender", "mild", "modest", "humble", "unassuming", "unpretentious", "simple", "plain",
        "unadorned", "minimal", "sparse", "bare", "stark", "austere", "spartan", "frugal", "restrained", "reserved",
        "controlled", "disciplined", "measured", "careful", "cautious", "prudent", "wise", "thoughtful", "contemplative",
        "meditative", "reflective", "introspective", "pensive", "dreamy", "melancholic", "nostalgic", "wistful", "yearning",
        "longing", "yearning", "craving", "desire", "aspiration", "hope", "optimism", "faith", "trust", "confidence",
        "assurance", "certainty", "security", "safety", "protection", "shelter", "refuge", "sanctuary", "haven", "retreat"
    ]

    // Common English stop words to filter from analysis
    private let stopWords: Set<String> = [
        "the","a","an","and","or","but","if","then","else","when","while","at","by","for","from","in",
        "into","of","on","onto","to","up","with","as","is","am","are","was","were","be","been","being",
        "it","its","itself","this","that","these","those","i","you","he","she","they","we","me","him",
        "her","them","my","your","his","their","our","ours","yours","hers","theirs","not","no","do","does",
        "did","doing","done","have","has","had","having","will","would","can","could","should","shall",
        "may","might","must","about","over","under","again","once","here","there","why","how","all","any",
        "both","each","few","more","most","other","some","such","only","own","same","so","than","too",
        "very"
    ]
    
    func analyzeVibe(from articles: [NewsArticle]) async -> VibeAnalysis {
        // 1. Try AI Analysis first (iOS 26+)
        if #available(iOS 26, *) {
            if let analyzer = aiAnalyzer as? AIVibeAnalyzer, await analyzer.isAvailable {
                if let aiResult = try? await analyzer.analyzeVibe(from: articles) {
                    AppLogger.shared.info("AI Analysis successful: \(aiResult.vibe.displayName)", category: .vibe)
                    return aiResult
                }
            }
        }
        
        // 2. Fallback to existing logic
        AppLogger.shared.info("Using standard analysis (Keyword/Semantic)", category: .vibe)
        
        guard !articles.isEmpty else {
            return VibeAnalysis(vibe: .contemplative, confidence: 0.0, reasoning: "No articles provided for analysis.", keywords: [], sentiment: .neutral, backgroundColorIntensity: 0.0)
        }
        
        // Weighted words for vibe scoring - titles weighted 3x higher than description/content
        // This ensures headlines (most indicative of tone) have greater influence on vibe detection
        let weightedWords = extractWeightedWords(from: articles, titleWeight: 3, descriptionWeight: 1, contentWeight: 1)

        // Unweighted words for sentiment (to avoid biasing by weight)
        let combinedText = articles.map { $0.fullText }.joined(separator: " ")
        let sentimentWords = extractWords(from: combinedText)

        // Calculate sentiment scores with negation handling
        let sentiment = calculateSentiment(from: sentimentWords)

        // Calculate vibe scores for each vibe type
        var vibeScores: [DailyVibe: Double] = [:]
        
        // Use semantic analysis if available, otherwise fall back to keyword density
        // Use semantic analysis if available, otherwise fall back to keyword density
        if let embedding = self.embedding, !vibeVectors.isEmpty {
            // Per-Article Semantic Analysis
            // We analyze each article individually to capture its specific vibe, then aggregate.
            
            var semanticScores: [DailyVibe: Double] = [:]
            var articleCount = 0
            
            for article in articles {
                // Get vector for this article (Title + Description is usually enough and cleaner)
                let articleText = "\(article.title) \(article.description ?? "")"
                guard let articleVector = embedding.vector(for: articleText) else { continue }
                
                articleCount += 1
                
                for vibe in DailyVibe.allCases {
                    if let vibeVector = vibeVectors[vibe] {
                        let similarity = cosineSimilarity(articleVector, vibeVector)
                        // Accumulate similarity (0.0 to 1.0)
                        semanticScores[vibe, default: 0.0] += max(0.0, similarity)
                    }
                }
            }
            
            // Average the scores
            if articleCount > 0 {
                for (vibe, totalScore) in semanticScores {
                    semanticScores[vibe] = totalScore / Double(articleCount)
                }
            }
            
            AppLogger.shared.debug("Analyzed \(articleCount) articles.", category: .vibe)
            
            for vibe in DailyVibe.allCases {
                // Hybrid Score: 30% Keyword Density + 70% Semantic Similarity
                let keywordScore = calculateVibeScore(for: vibe, in: weightedWords)
                let semanticScore = semanticScores[vibe] ?? 0.0
                
                // Normalize semantic score
                // Observed raw scores are typically 0.05 - 0.25.
                // We map 0.05...0.30 to roughly 0.0...1.0
                let normalizedSemantic = max(0.0, min(1.0, (semanticScore - 0.05) * 4.0))
                
                AppLogger.shared.debug("\(vibe.rawValue) - Raw Semantic: \(semanticScore), Normalized: \(normalizedSemantic), Keyword: \(keywordScore)", category: .vibe)
                
                vibeScores[vibe] = (keywordScore * 0.3) + (normalizedSemantic * 0.7)
            }
        } else {
            AppLogger.shared.warning("Using fallback keyword logic (No embedding or vectors).", category: .vibe)
            // Fallback to original keyword-only logic
            for vibe in DailyVibe.allCases {
                let score = calculateVibeScore(for: vibe, in: weightedWords)
                vibeScores[vibe] = score
            }
        }

        // Find the vibe with the highest score
        let topVibeEntry = vibeScores.max(by: { $0.value < $1.value })
        let topVibe = (topVibeEntry?.value ?? 0 > 0) ? (topVibeEntry?.key ?? .contemplative) : .contemplative
        let confidence = vibeScores[topVibe] ?? 0.0

        // Generate reasoning
        let reasoning = generateReasoning(for: topVibe, from: articles, sentiment: sentiment)

        // Extract key thematic words (use weighted words for relevance)
        let keywords = extractKeywords(for: topVibe, from: weightedWords)

        return VibeAnalysis(
            vibe: topVibe,
            confidence: min(1.0, confidence),
            reasoning: reasoning,
            keywords: keywords,
            sentiment: sentiment,
            backgroundColorIntensity: calculateBackgroundColorIntensity(confidence: confidence, sentiment: sentiment)
        )
    }
    
    private func extractWeightedWords(from articles: [NewsArticle], titleWeight: Int = 3, descriptionWeight: Int = 1, contentWeight: Int = 1) -> [String] {
        guard !articles.isEmpty else { return [] }
        var words: [String] = []
        for article in articles {
            let titleWords = extractWords(from: article.title)
            let descriptionWords = extractWords(from: article.description ?? "")
            let contentWords = extractWords(from: article.content ?? "")

            if titleWeight > 1 {
                for _ in 0..<titleWeight { words.append(contentsOf: titleWords) }
            } else {
                words.append(contentsOf: titleWords)
            }
            if descriptionWeight > 1 {
                for _ in 0..<descriptionWeight { words.append(contentsOf: descriptionWords) }
            } else {
                words.append(contentsOf: descriptionWords)
            }
            if contentWeight > 1 {
                for _ in 0..<contentWeight { words.append(contentsOf: contentWords) }
            } else {
                words.append(contentsOf: contentWords)
            }
        }
        return words
    }
    
    private func extractWords(from text: String) -> [String] {
        let cleanedText = text.lowercased()
            .replacingOccurrences(of: "[^a-zA-Z\\s]", with: " ", options: .regularExpression)

        return cleanedText
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 2 }
            .filter { !stopWords.contains($0) }
    }
    
    private func calculateSentiment(from words: [String]) -> SentimentScore {
        let negations: Set<String> = ["not", "no", "never", "none", "nobody", "nothing", "neither", "nowhere", "hardly", "barely", "scarcely", "without", "lacking", "lack", "lacks", "cannot", "cant", "wont", "dont", "doesnt", "didnt", "isnt", "arent", "wasnt", "werent", "shouldnt", "wouldnt", "couldnt", "mustnt"]

        var posHits = 0
        var negHits = 0
        var energyHits = 0
        var calmHits = 0

        var negationWindow = 0 // number of tokens remaining where negation applies
        let windowSize = 2

        for word in words {
            // Update negation window
            if negations.contains(word) {
                negationWindow = windowSize
                continue
            }

            let invert = negationWindow > 0

            if positiveWords.contains(word) {
                if invert { negHits += 1 } else { posHits += 1 }
            } else if negativeWords.contains(word) {
                if invert { posHits += 1 } else { negHits += 1 }
            }

            // Energy/calm are not strongly affected by negation in headlines; treat normally
            if energyWords.contains(word) { energyHits += 1 }
            if calmWords.contains(word) { calmHits += 1 }

            // Decay negation window
            if negationWindow > 0 { negationWindow -= 1 }
        }

        let sentimentTotal = max(1, posHits + negHits)
        let energyTotal = max(1, energyHits + calmHits)

        // Map difference ratio to 0..1 with 0.5 neutral
        let positivity = 0.5 + 0.5 * Double(posHits - negHits) / Double(sentimentTotal)
        let energy = 0.5 + 0.5 * Double(energyHits - calmHits) / Double(energyTotal)

        // Complexity based on average word length and vocabulary diversity
        guard !words.isEmpty else {
            return SentimentScore(positivity: 0.5, energy: 0.5, complexity: 0.5)
        }
        let averageWordLength = Double(words.reduce(0) { $0 + $1.count }) / Double(words.count)
        let uniqueWords = Set(words).count
        let vocabularyDiversity = Double(uniqueWords) / Double(words.count)
        let complexity = (averageWordLength / 10.0 + vocabularyDiversity) / 2.0

        return SentimentScore(
            positivity: max(0.0, min(1.0, positivity)),
            energy: max(0.0, min(1.0, energy)),
            complexity: max(0.0, min(1.0, complexity))
        )
    }
    
    /// Calculates vibe score using exact word boundary matching (no substring matching)
    /// Returns a simple density score (0.0 to 1.0) based on keyword matches, treating all vibes equally
    private func calculateVibeScore(for vibe: DailyVibe, in words: [String]) -> Double {
        guard let keywords = vibeKeywords[vibe], !words.isEmpty else { return 0.0 }
        // Use exact word matching (Set.contains) - no substring matching to avoid false positives
        let keywordSet = Set(keywords.map { $0.lowercased() })
        let matchCount = words.reduce(0) { $0 + (keywordSet.contains($1) ? 1 : 0) }
        // Simple density-based score - treats all vibes equally regardless of keyword count
        let density = Double(matchCount) / Double(words.count) // 0..1
        return density
    }
    
    /// Calculates cosine similarity between two vectors
    private func cosineSimilarity(_ vectorA: [Double], _ vectorB: [Double]) -> Double {
        guard vectorA.count == vectorB.count else { return 0.0 }
        
        var dotProduct = 0.0
        var magnitudeA = 0.0
        var magnitudeB = 0.0
        
        for i in 0..<vectorA.count {
            dotProduct += vectorA[i] * vectorB[i]
            magnitudeA += vectorA[i] * vectorA[i]
            magnitudeB += vectorB[i] * vectorB[i]
        }
        
        magnitudeA = sqrt(magnitudeA)
        magnitudeB = sqrt(magnitudeB)
        
        if magnitudeA == 0 || magnitudeB == 0 { return 0.0 }
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
    
    private func generateReasoning(for vibe: DailyVibe, from articles: [NewsArticle], sentiment: SentimentScore) -> String {
        let keyThemes = identifyKeyThemes(from: articles)
        
        let sentimentDescription: String
        switch sentiment.positivity {
        case 0.0..<0.3:
            sentimentDescription = "challenging news"
        case 0.3..<0.7:
            sentimentDescription = "mixed developments"
        default:
            sentimentDescription = "positive developments"
        }
        
        let energyDescription: String
        switch sentiment.energy {
        case 0.0..<0.3:
            energyDescription = "calm, steady news"
        case 0.3..<0.7:
            energyDescription = "moderate activity"
        default:
            energyDescription = "high-energy events"
        }
        
        return "Today's news reflects a \(vibe.displayName.lowercased()) mood based on \(sentimentDescription) and \(energyDescription). Key themes include: \(keyThemes.joined(separator: ", ")). Headlines suggest \(vibe.description.lowercased())."
    }
    
    /// Identifies key themes using exact word matching (no substring matching)
    /// Uses weighted words so titles have 3x influence on theme detection
    private func identifyKeyThemes(from articles: [NewsArticle]) -> [String] {
        // Use weighted words so titles influence theme detection (titleWeight: 3)
        let words = extractWeightedWords(from: articles, titleWeight: 3, descriptionWeight: 1, contentWeight: 1)

        // Common news themes to look for
        let themes: [String: [String]] = [
            "politics": ["government", "president", "congress", "election", "policy", "law", "senate", "parliament", "minister", "vote", "voting"],
            "health": ["health", "medical", "doctor", "hospital", "treatment", "vaccine", "disease", "virus", "wellness", "care"],
            "technology": ["technology", "digital", "app", "internet", "computer", "innovation", "software", "hardware", "ai", "robot"],
            "environment": ["climate", "environment", "green", "renewable", "pollution", "nature", "emissions", "wildlife", "forest", "ocean"],
            "economy": ["economy", "business", "market", "financial", "money", "economic", "stocks", "jobs", "trade", "inflation"],
            "social": ["community", "social", "people", "family", "education", "culture", "society", "schools", "youth", "arts"]
        ]

        var themeScores: [String: Int] = [:]
        let wordCounts = words.reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }

        // Use exact word matching (Set.contains) - no substring matching
        for (theme, keywords) in themes {
            let keySet = Set(keywords.map { $0.lowercased() })
            let matches = keySet.reduce(0) { acc, key in acc + (wordCounts[key] ?? 0) }
            themeScores[theme] = matches
        }

        return themeScores
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }
    
    private func extractKeywords(for vibe: DailyVibe, from words: [String]) -> [String] {
        guard let vibeWords = vibeKeywords[vibe], !words.isEmpty else { return [] }
        let keySet = Set(vibeWords.map { $0.lowercased() })
        let freq = words.reduce(into: [String: Int]()) { dict, w in
            if keySet.contains(w) { dict[w, default: 0] += 1 }
        }
        return freq
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }
    
    private func calculateBackgroundColorIntensity(confidence: Double, sentiment: SentimentScore) -> Double {
        // Base intensity from confidence (higher confidence = stronger color)
        let confidenceContribution = confidence * 0.6
        
        // Sentiment contribution to intensity
        // Higher energy and more extreme positivity/negativity contribute to stronger colors
        let energyContribution = sentiment.energy * 0.3
        let emotionalIntensity = abs(sentiment.positivity - 0.5) * 2.0 // 0.5 is neutral, extreme values are stronger
        let emotionalContribution = emotionalIntensity * 0.1
        
        // Combine all factors
        let totalIntensity = confidenceContribution + energyContribution + emotionalContribution
        
        // Ensure intensity is between 0.3 (minimum visibility) and 1.0 (maximum intensity)
        return max(0.3, min(1.0, totalIntensity))
    }
}
