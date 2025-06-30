//
//  DependencyContainer.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
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
    private let repository: PoemRepositoryProtocol
    
    private init() {
        self.networkService = NetworkService()
        self.newsService = NewsService()
        self.vibeAnalyzer = VibeAnalyzer()
        self.telemetryService = TelemetryService()
        
        // Initialize AI service if available (iOS 26+)
        if #available(iOS 26, *) {
            self.aiService = PoemGenerationService()
        } else {
            self.aiService = nil
        }
        
        self.repository = PoemRepository(
            networkService: networkService,
            newsService: newsService,
            vibeAnalyzer: vibeAnalyzer,
            aiService: aiService,
            telemetryService: telemetryService
        )
    }
    
    // For testing
    init(networkService: NetworkServiceProtocol, 
         newsService: NewsServiceProtocol,
         vibeAnalyzer: VibeAnalyzerProtocol,
         aiService: PoemGenerationServiceProtocol?,
         telemetryService: TelemetryServiceProtocol,
         repository: PoemRepositoryProtocol) {
        self.networkService = networkService
        self.newsService = newsService
        self.vibeAnalyzer = vibeAnalyzer
        self.aiService = aiService
        self.telemetryService = telemetryService
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
    
    func makeRepository() -> PoemRepositoryProtocol {
        return repository
    }
    
    func makePoemViewModel() -> PoemViewModel {
        return PoemViewModel(repository: repository, telemetryService: telemetryService)
    }
}