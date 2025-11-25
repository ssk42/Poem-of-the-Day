//
//  DependencyContainer.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//  Updated with notification and history services
//

import Foundation

@MainActor
final class DependencyContainer: ObservableObject {
    static let shared = DependencyContainer()
    
    private let networkService: NetworkServiceProtocol
    private let newsService: NewsServiceProtocol
    private let vibeAnalyzer: VibeAnalyzerProtocol
    private let aiService: PoemGenerationServiceProtocol?
    private let telemetryService: TelemetryServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private let historyService: PoemHistoryServiceProtocol
    private let repository: PoemRepositoryProtocol
    
    private init() {
        self.networkService = NetworkService()
        self.newsService = NewsService()
        self.vibeAnalyzer = VibeAnalyzer()
        self.telemetryService = TelemetryService()
        self.notificationService = NotificationService()
        self.historyService = PoemHistoryService()
        
        // Initialize AI service if available (iOS 18+)
        if #available(iOS 18, *) {
            self.aiService = PoemGenerationService()
        } else {
            self.aiService = nil
        }
        
        self.repository = PoemRepository(
            networkService: networkService,
            newsService: newsService,
            vibeAnalyzer: vibeAnalyzer,
            aiService: aiService,
            telemetryService: telemetryService,
            historyService: historyService
        )
        
        // Register notification categories
        Task {
            await (notificationService as? NotificationService)?.registerNotificationCategories()
        }
    }
    
    // For testing
    init(networkService: NetworkServiceProtocol, 
         newsService: NewsServiceProtocol,
         vibeAnalyzer: VibeAnalyzerProtocol,
         aiService: PoemGenerationServiceProtocol?,
         telemetryService: TelemetryServiceProtocol,
         notificationService: NotificationServiceProtocol,
         historyService: PoemHistoryServiceProtocol,
         repository: PoemRepositoryProtocol) {
        self.networkService = networkService
        self.newsService = newsService
        self.vibeAnalyzer = vibeAnalyzer
        self.aiService = aiService
        self.telemetryService = telemetryService
        self.notificationService = notificationService
        self.historyService = historyService
        self.repository = repository
    }
    
    func makeNetworkService() -> NetworkServiceProtocol {
        return networkService
    }
    
    func makeNewsService() -> NewsServiceProtocol {
        return newsService
    }
    
    func makeVibeAnalyzer() -> VibeAnalyzerProtocol {
        return vibeAnalyzer
    }
    
    func makeAIService() -> PoemGenerationServiceProtocol? {
        return aiService
    }
    
    func makeTelemetryService() -> TelemetryServiceProtocol {
        return telemetryService
    }
    
    func makeNotificationService() -> NotificationServiceProtocol {
        return notificationService
    }
    
    func makeHistoryService() -> PoemHistoryServiceProtocol {
        return historyService
    }
    
    func makeRepository() -> PoemRepositoryProtocol {
        return repository
    }
    
    func makePoemViewModel() -> PoemViewModel {
        return PoemViewModel(repository: repository, telemetryService: telemetryService)
    }
}
