//
//  LoadingView.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import SwiftUI

/// Reusable loading view component
struct LoadingView: View {
    let message: String
    let showProgress: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(message: String = "Loading...", showProgress: Bool = true) {
        self.message = message
        self.showProgress = showProgress
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if showProgress {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            }
            
            Text(message)
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading content")
    }
}

/// Inline loading view for smaller spaces
struct InlineLoadingView: View {
    let message: String?
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            
            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            }
        }
        .padding()
    }
}

/// Full screen loading overlay
struct LoadingOverlay: View {
    let message: String
    @Environment(\.colorScheme) private var colorScheme
    
    init(message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
}

// MARK: - Previews

#if DEBUG
struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoadingView(message: "Loading your daily poem...")
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            LoadingView(message: "Generating AI poem...")
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            InlineLoadingView(message: "Fetching news...")
                .previewDisplayName("Inline Loading")
            
            LoadingOverlay(message: "Analyzing today's vibe...")
                .previewDisplayName("Loading Overlay")
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
#endif