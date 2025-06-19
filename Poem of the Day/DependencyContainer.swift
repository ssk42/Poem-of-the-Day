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
    private let aiService: PoemGenerationServiceProtocol
    private let repository: PoemRepositoryProtocol
    
    private init() {
        self.networkService = NetworkService()
        self.aiService = PoemGenerationService()
        self.repository = PoemRepository(networkService: networkService, aiService: aiService)
    }
    
    // For testing
    init(networkService: NetworkServiceProtocol, aiService: PoemGenerationServiceProtocol, repository: PoemRepositoryProtocol) {
        self.networkService = networkService
        self.aiService = aiService
        self.repository = repository
    }
    
    func makeNetworkService() -> NetworkServiceProtocol {
        return networkService
    }
    
    func makeAIService() -> PoemGenerationServiceProtocol {
        return aiService
    }
    
    func makeRepository() -> PoemRepositoryProtocol {
        return repository
    }
    
    func makePoemViewModel() -> PoemViewModel {
        return PoemViewModel(repository: repository)
    }
}