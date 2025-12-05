//
//  PoemCardView.swift
//  Poem of the Day
//
//  Extracted from ContentView.swift for better maintainability
//

import SwiftUI

struct PoemCardView: View {
    let poem: Poem
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onShare: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            
            Divider()
                .accessibilityHidden(true)
            
            Text(poem.content)
                .font(.system(size: scaledFontSize(16), weight: .regular, design: .serif))
                .lineSpacing(8)
                .padding(.vertical, 8)
                .accessibilityLabel("Poem content: \(poem.content)")
                .accessibilityIdentifier("poem_content")
            
            actionButtons
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .transition(.opacity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("poem_card")
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(poem.title)
                .font(.system(size: scaledFontSize(24), weight: .semibold, design: .serif))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("poem_title")
            
            HStack {
                if let author = poem.author {
                    Text("by \(author)")
                        .font(.system(size: scaledFontSize(16), weight: .medium, design: .serif))
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("poem_author")
                }
                
                Spacer()
                
                if let vibe = poem.vibe {
                    vibeIndicator(vibe: vibe)
                }
            }
        }
    }
    
    // MARK: - Vibe Indicator
    
    private func vibeIndicator(vibe: DailyVibe) -> some View {
        HStack(spacing: 4) {
            Text(vibe.emoji)
                .font(.caption)
                .accessibilityHidden(true)
            Text("Today's \(vibe.displayName) Vibe")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color(red: 0.3, green: 0.3, blue: 0.4) : Color(red: 0.95, green: 0.95, blue: 0.97))
        )
        .accessibilityLabel("Generated from \(vibe.displayName) vibe")
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack {
            Button(action: {
                onToggleFavorite()
                #if canImport(UIKit)
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                #endif
            }) {
                Label(
                    isFavorite ? "Remove from favorites" : "Add to favorites",
                    systemImage: isFavorite ? "heart.fill" : "heart"
                )
                .foregroundColor(isFavorite ? .red : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .strokeBorder(isFavorite ? Color.red : Color.primary, lineWidth: 1)
                )
            }
            .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
            .accessibilityHint(isFavorite ? "Double tap to remove this poem from your favorites" : "Double tap to add this poem to your favorites")
            .accessibilityIdentifier("favorite_button")
            
            Spacer()
            
            Button(action: onShare) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .strokeBorder(Color.primary, lineWidth: 1)
                    )
            }
            .accessibilityLabel("Share poem")
            .accessibilityHint("Double tap to share this poem with others")
            .accessibilityIdentifier("share_button")
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helpers
    
    private func scaledFontSize(_ baseSize: CGFloat) -> CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return baseSize * 0.85
        case .medium:
            return baseSize * 0.9
        case .large:
            return baseSize
        case .xLarge:
            return baseSize * 1.1
        case .xxLarge:
            return baseSize * 1.2
        case .xxxLarge:
            return baseSize * 1.3
        case .accessibility1:
            return baseSize * 1.4
        case .accessibility2:
            return baseSize * 1.5
        case .accessibility3:
            return baseSize * 1.6
        case .accessibility4:
            return baseSize * 1.7
        case .accessibility5:
            return baseSize * 1.8
        @unknown default:
            return baseSize
        }
    }
}
