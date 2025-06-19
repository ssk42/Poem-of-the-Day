//
//  PoemViewModel.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import Foundation
import SwiftUI

@MainActor
final class PoemViewModel: ObservableObject {
    @Published var poemOfTheDay: Poem?
    @Published var favorites: [Poem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showErrorAlert = false
    
    private let repository: PoemRepositoryProtocol
    
    init(repository: PoemRepositoryProtocol = PoemRepository()) {
        self.repository = repository
        
        Task {
            await loadInitialData()
        }
    }
    
    func loadInitialData() async {
        isLoading = true
        
        async let poemTask = loadDailyPoem()
        async let favoritesTask = loadFavorites()
        
        await poemTask
        await favoritesTask
        
        isLoading = false
    }
    
    func refreshPoem() async {
        isLoading = true
        
        do {
            poemOfTheDay = try await repository.refreshDailyPoem()
        } catch {
            await handleError(error)
        }
        
        isLoading = false
    }
    
    func toggleFavorite(poem: Poem) async {
        let isFavorite = await repository.isFavorite(poem)
        
        if isFavorite {
            await repository.removeFromFavorites(poem)
        } else {
            await repository.addToFavorites(poem)
        }
        
        await loadFavorites()
    }
    
    func isFavorite(poem: Poem) -> Bool {
        favorites.contains { $0.id == poem.id }
    }
    
    // MARK: - Private Methods
    
    private func loadDailyPoem() async {
        do {
            poemOfTheDay = try await repository.getDailyPoem()
        } catch {
            await handleError(error)
        }
    }
    
    private func loadFavorites() async {
        favorites = await repository.getFavorites()
    }
    
    private func handleError(_ error: Error) async {
        if let poemError = error as? PoemError {
            errorMessage = poemError.localizedDescription
        } else {
            errorMessage = "An unexpected error occurred"
        }
        showErrorAlert = true
    }
}