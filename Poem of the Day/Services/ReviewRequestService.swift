//
//  ReviewRequestService.swift
//  Poem of the Day
//

import StoreKit
import UIKit

/// Tracks positive engagement events and requests App Store reviews at appropriate moments.
/// Apple allows at most 3 review requests per 365-day period; this service adds its own
/// 60-day cooldown so we never burn the quota on low-engagement sessions.
@MainActor
final class ReviewRequestService {
    static let shared = ReviewRequestService()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let appLaunchCount = "review_appLaunchCount"
        static let favoritesAddedCount = "review_favoritesAddedCount"
        static let aiPoemsGeneratedCount = "review_aiPoemsGeneratedCount"
        static let lastRequestDate = "review_lastRequestDate"
        static let totalRequestCount = "review_totalRequestCount"
    }

    private init() {}

    func recordAppLaunch() {
        let count = increment(Keys.appLaunchCount)
        // Third launch: user is returning — a good moment to ask
        if count == 3 {
            requestReviewIfAppropriate()
        }
    }

    func recordFavoriteAdded() {
        let count = increment(Keys.favoritesAddedCount)
        // Second favorite means the user is building a collection
        if count == 2 {
            requestReviewIfAppropriate()
        }
    }

    func recordAIPoemGenerated() {
        let count = increment(Keys.aiPoemsGeneratedCount)
        // First AI poem: high-intent action worth asking about
        if count == 1 {
            requestReviewIfAppropriate()
        }
    }

    // MARK: - Private

    @discardableResult
    private func increment(_ key: String) -> Int {
        let next = defaults.integer(forKey: key) + 1
        defaults.set(next, forKey: key)
        return next
    }

    private func requestReviewIfAppropriate() {
        // Stay well under Apple's 3-per-year cap
        guard defaults.integer(forKey: Keys.totalRequestCount) < 3 else { return }

        // Respect a 60-day cooldown between requests
        if let last = defaults.object(forKey: Keys.lastRequestDate) as? Date {
            let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
            guard days >= 60 else { return }
        }

        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }

        AppStore.requestReview(in: scene)

        increment(Keys.totalRequestCount)
        defaults.set(Date(), forKey: Keys.lastRequestDate)
    }
}
