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
    private let repository: PoemRepositoryProtocol
    
    private init() {
        self.networkService = NetworkService()
        self.newsService = NewsService()
        self.vibeAnalyzer = VibeAnalyzer()
        
        // Initialize AI service if available (iOS 18.1+)
        if #available(iOS 18.1, *) {
            self.aiService = PoemGenerationService()
        } else {
            self.aiService = nil
        }
        
        self.repository = PoemRepository(
            networkService: networkService,
            newsService: newsService,
            vibeAnalyzer: vibeAnalyzer,
            aiService: aiService
        )
    }
    
    // For testing
    init(networkService: NetworkServiceProtocol, 
         newsService: NewsServiceProtocol,
         vibeAnalyzer: VibeAnalyzerProtocol,
         aiService: PoemGenerationServiceProtocol?,
         repository: PoemRepositoryProtocol) {
        self.networkService = networkService
        self.newsService = newsService
        self.vibeAnalyzer = vibeAnalyzer
        self.aiService = aiService
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
    
    
    func makeRepository() -> PoemRepositoryProtocol {
        return repository
    }
    
    func makePoemViewModel() -> PoemViewModel {
        return PoemViewModel(repository: repository)
    }
}