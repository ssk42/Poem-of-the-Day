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
    private let repository: PoemRepositoryProtocol
    
    private init() {
        self.networkService = NetworkService()
        self.repository = PoemRepository(networkService: networkService)
    }
    
    // For testing
    init(networkService: NetworkServiceProtocol, repository: PoemRepositoryProtocol) {
        self.networkService = networkService
        self.repository = repository
    }
    
    func makeNetworkService() -> NetworkServiceProtocol {
        return networkService
    }
    
    
    func makeRepository() -> PoemRepositoryProtocol {
        return repository
    }
    
    func makePoemViewModel() -> PoemViewModel {
        return PoemViewModel(repository: repository)
    }
}