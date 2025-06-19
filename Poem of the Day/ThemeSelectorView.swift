//
//  ThemeSelectorView.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import SwiftUI

struct ThemeSelectorView: View {
    let onThemeSelected: (PoemTheme) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerView
                        themeGrid
                    }
                    .padding()
                }
            }
            .navigationTitle("Choose a Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.2) : Color(red: 0.9, green: 0.95, blue: 1.0),
                colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color(red: 0.8, green: 0.9, blue: 1.0)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 40))
                .foregroundColor(.purple)
                .padding(.bottom, 8)
            
            Text("AI Poem Generator")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Text("Choose a theme for your personalized poem")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var themeGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(PoemTheme.allCases, id: \.self) { theme in
                ThemeCard(theme: theme) {
                    onThemeSelected(theme)
                }
            }
        }
    }
}

struct ThemeCard: View {
    let theme: PoemTheme
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private var themeIcon: String {
        switch theme {
        case .nature: return "leaf.fill"
        case .love: return "heart.fill"
        case .friendship: return "person.2.fill"
        case .hope: return "sunrise.fill"
        case .seasons: return "snowflake"
        case .dreams: return "moon.stars.fill"
        case .journey: return "map.fill"
        case .peace: return "hands.sparkles.fill"
        case .wonder: return "sparkles"
        case .gratitude: return "hands.and.sparkles.fill"
        }
    }
    
    private var themeColor: Color {
        switch theme {
        case .nature: return .green
        case .love: return .red
        case .friendship: return .orange
        case .hope: return .yellow
        case .seasons: return .cyan
        case .dreams: return .indigo
        case .journey: return .brown
        case .peace: return .mint
        case .wonder: return .pink
        case .gratitude: return .purple
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: themeIcon)
                    .font(.system(size: 28))
                    .foregroundColor(themeColor)
                
                Text(theme.displayName)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(themeColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(theme.displayName) theme")
        .accessibilityHint("Generate a poem about \(theme.rawValue)")
    }
}

#if DEBUG
struct ThemeSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        ThemeSelectorView { theme in
            print("Selected theme: \(theme)")
        }
        .preferredColorScheme(.light)
        
        ThemeSelectorView { theme in
            print("Selected theme: \(theme)")
        }
        .preferredColorScheme(.dark)
    }
}
#endif