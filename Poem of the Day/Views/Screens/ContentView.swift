//
//  ContentView.swift
//  Poem of the Day
//
//  Created by Stephen Reitz on 11/14/24.
//  Updated with history, settings, and accessibility improvements
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    @EnvironmentObject private var dependencies: DependencyContainer
    @StateObject private var viewModel: PoemViewModel
    @State private var isPoemLoading = false
    @State private var showFavorites = false
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showShareSheet = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    init() {
        let container = DependencyContainer.shared
        self._viewModel = StateObject(wrappedValue: container.makePoemViewModel())
    }
    
    private var toolbarPlacement: ToolbarItemPlacement {
        #if os(visionOS)
        return .topBarTrailing
        #else
        return .navigationBarTrailing
        #endif
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerView
                        
                        if isPoemLoading {
                            loadingView
                                .accessibilityIdentifier("loading_indicator")
                        } else if let poem = viewModel.poemOfTheDay {
                            poemCard(poem: poem)
                        } else if viewModel.errorMessage != nil {
                            errorView
                        }
                        
                        controlButtons
                    }
                    .padding()
                }
                .refreshable {
                    isPoemLoading = true
                    await viewModel.refreshPoem()
                    isPoemLoading = false
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            showHistory = true
                        } label: {
                            Label("History", systemImage: "clock.arrow.circlepath")
                        }
                        
                        Button {
                            showSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .accessibilityLabel("Menu")
                            .accessibilityHint("Opens menu with history and settings options")
                    }
                    .accessibilityIdentifier("menu_button")
                }
                
                ToolbarItem(placement: toolbarPlacement) {
                    Button(action: {
                        showFavorites = true
                    }) {
                        Label("Favorites", systemImage: "heart.fill")
                            .foregroundColor(.red)
                    }
                    .accessibilityLabel("Favorite Poems")
                    .accessibilityHint("View your saved favorite poems")
                    .accessibilityIdentifier("favorites_button")
                }
            }
            .sheet(isPresented: $showFavorites) {
                FavoritesView(favorites: viewModel.favorites)
            }
            .sheet(isPresented: $showHistory) {
                PoemHistoryView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showShareSheet) {
                #if canImport(UIKit)
                if let poem = viewModel.poemOfTheDay {
                    ShareSheet(items: [poem.shareText])
                }
                #else
                EmptyView()
                #endif
            }
            .sheet(isPresented: $viewModel.showVibeGeneration) {
                if let vibe = viewModel.currentVibe {
                    VibeGenerationView(
                        vibeAnalysis: vibe,
                        onGeneratePoem: {
                            viewModel.showVibeGeneration = false
                            Task {
                                isPoemLoading = true
                                await viewModel.generateVibeBasedPoem()
                                isPoemLoading = false
                            }
                        },
                        onCustomPrompt: {
                            viewModel.showVibeGeneration = false
                            viewModel.showCustomPrompt = true
                        }
                    )
                }
            }
            .sheet(isPresented: $viewModel.showCustomPrompt) {
                CustomPromptView { prompt in
                    Task {
                        await viewModel.generateCustomPoem(prompt: prompt)
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) { }
                Button("Retry") {
                    Task {
                        await viewModel.refreshPoem()
                    }
                }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }
    
    private func provideFeedback(success: Bool) {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(success ? .success : .error)
        #endif
    }
    
    // MARK: - UI Components
    
    private var backgroundGradient: some View {
        Group {
            if let currentVibe = viewModel.currentVibe {
                // Use vibe-based background colors
                currentVibe.vibe.backgroundGradient(for: colorScheme)
                    .opacity(currentVibe.backgroundColorInfo.intensity)
                    .animation(.easeInOut(duration: 1.0), value: currentVibe.vibe)
            } else {
                // Default background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.2) : Color(red: 0.9, green: 0.95, blue: 1.0),
                        colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color(red: 0.8, green: 0.9, blue: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .accessibilityHidden(true)
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Poem of the Day")
                .font(.system(size: scaledFontSize(32), weight: .bold, design: .serif))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("app_title")
            
            // Small AI generation buttons at the top
            if viewModel.isAIGenerationAvailable {
                HStack(spacing: 8) {
                    Button(action: {
                        viewModel.showVibeGeneration = true
                    }) {
                        HStack(spacing: 4) {
                            Text(viewModel.currentVibe?.vibe.emoji ?? "🎭")
                                .font(.caption)
                            Image(systemName: "brain.head.profile")
                                .font(.caption2)
                            Text("Vibe")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.purple)
                        )
                    }
                    .accessibilityLabel("Generate vibe-based poem")
                    .accessibilityIdentifier("top_vibe_poem_button")
                    
                    Button(action: {
                        viewModel.showCustomPrompt = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil.and.outline")
                                .font(.caption2)
                            Text("Custom")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.purple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .strokeBorder(Color.purple, lineWidth: 1.5)
                        )
                    }
                    .accessibilityLabel("Create custom poem")
                    .accessibilityIdentifier("top_custom_poem_button")
                }
                .padding(.top, 4)
            }
            
            // Show vibe analysis info if available
            if let currentVibe = viewModel.currentVibe {
                HStack(spacing: 8) {
                    Text(currentVibe.vibe.emoji)
                        .font(.title3)
                        .accessibilityHidden(true)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today's \(currentVibe.vibe.displayName) Vibe")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Text(currentVibe.backgroundColorInfo.colorDescription)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Color intensity indicator
                    Circle()
                        .fill(currentVibe.vibe.primaryBackgroundColor(for: colorScheme))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .strokeBorder(colorScheme == .dark ? Color.white : Color.black, lineWidth: 1)
                        )
                        .opacity(currentVibe.backgroundColorInfo.intensity)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                        .opacity(0.8)
                )
                .transition(.scale.combined(with: .opacity))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Today's vibe is \(currentVibe.vibe.displayName). \(currentVibe.vibe.description)")
                .accessibilityIdentifier("vibe_indicator")
            }
            
            Text(formattedDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .accessibilityLabel("Date: \(formattedDate)")
        }
        .padding(.vertical)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
    
    /// Scale font size based on dynamic type
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
    
    private func poemCard(poem: Poem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
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
                    
                    // Show vibe indicator if this is an AI-generated poem
                    if let vibe = poem.vibe {
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
                }
            }
            
            Divider()
                .accessibilityHidden(true)
            
            Text(poem.content)
                .font(.system(size: scaledFontSize(16), weight: .regular, design: .serif))
                .lineSpacing(8)
                .padding(.vertical, 8)
                .accessibilityLabel("Poem content: \(poem.content)")
                .accessibilityIdentifier("poem_content")
            
            HStack {
                Button(action: {
                    Task {
                        await viewModel.toggleFavorite(poem: poem)
                        #if canImport(UIKit)
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        #endif
                    }
                }) {
                    Label(
                        viewModel.isFavorite(poem: poem) ? "Unfavorite" : "Favorite",
                        systemImage: viewModel.isFavorite(poem: poem) ? "heart.fill" : "heart"
                    )
                    .foregroundColor(viewModel.isFavorite(poem: poem) ? .red : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .strokeBorder(viewModel.isFavorite(poem: poem) ? Color.red : Color.primary, lineWidth: 1)
                    )
                }
                .accessibilityLabel(viewModel.isFavorite(poem: poem) ? "Remove from favorites" : "Add to favorites")
                .accessibilityHint(viewModel.isFavorite(poem: poem) ? "Double tap to remove this poem from your favorites" : "Double tap to add this poem to your favorites")
                .accessibilityIdentifier("favorite_button")
                
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.sharePoem(poem)
                    }
                    showShareSheet = true
                }) {
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
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text("Loading your poem...")
                .font(.system(size: scaledFontSize(16), weight: .medium, design: .serif))
                .foregroundColor(.secondary)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading poem, please wait")
        .accessibilityIdentifier("loading_view")
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
                .accessibilityHidden(true)
            
            Text("Unable to load poem")
                .font(.headline)
            
            Text("Please try again later")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                Task {
                    await viewModel.refreshPoem()
                }
            }) {
                Text("Retry")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .accessibilityHint("Double tap to try loading the poem again")
        }
        .padding()
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Error loading poem. Tap Retry to try again.")
        .accessibilityIdentifier("error_view")
    }
    
    private var controlButtons: some View {
        VStack(spacing: 12) {
            // Regular poem refresh
            Button(action: {
                Task {
                    isPoemLoading = true
                    await viewModel.refreshPoem()
                    isPoemLoading = false
                }
            }) {
                Label("Get New Poem", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .accessibilityLabel("Get a new poem")
            .accessibilityHint("Double tap to fetch a new random poem")
            .accessibilityIdentifier("refresh_button")
            
            // AI generation buttons (only show if available)
            if viewModel.isAIGenerationAvailable {
                HStack(spacing: 12) {
                    Button(action: {
                        // Just show the sheet - generation happens when user taps the button inside
                        viewModel.showVibeGeneration = true
                    }) {
                        VStack(spacing: 4) {
                            HStack {
                                Text(viewModel.currentVibe?.vibe.emoji ?? "🎭")
                                    .font(.title3)
                                    .accessibilityHidden(true)
                                Image(systemName: "brain.head.profile")
                                    .font(.subheadline)
                            }
                            Text("Vibe Poem")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.purple.opacity(0.3), radius: 3, x: 0, y: 2)
                    }
                    .accessibilityLabel("Generate AI poem based on today's news vibe")
                    .accessibilityHint("Double tap to create a poem inspired by today's mood from the news")
                    .accessibilityIdentifier("vibe_poem_button")
                    
                    Button(action: {
                        viewModel.showCustomPrompt = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "pencil.and.outline")
                                .font(.title3)
                            Text("Custom")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.purple)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .strokeBorder(Color.purple, lineWidth: 2)
                                .background(Capsule().fill(Color.clear))
                        )
                    }
                    .accessibilityLabel("Create custom AI poem")
                    .accessibilityHint("Double tap to write your own prompt for an AI-generated poem")
                    .accessibilityIdentifier("custom_poem_button")
                }
            }
            
        }
    }
}

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Share Sheet

#if canImport(UIKit)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - Favorites View

struct FavoritesView: View {
    let favorites: [Poem]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.2) : Color(red: 0.9, green: 0.95, blue: 1.0),
                        colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color(red: 0.8, green: 0.9, blue: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if favorites.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(favorites) { poem in
                            NavigationLink(destination: FavoritePoemDetailView(poem: poem)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(poem.title)
                                        .font(.headline)
                                    
                                    if let author = poem.author {
                                        Text("by \(author)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text(poem.content)
                                        .font(.body)
                                        .lineLimit(2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("\(poem.title) by \(poem.author ?? "Unknown author")")
                                .accessibilityHint("Double tap to view full poem")
                            }
                            .listRowBackground(
                                colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color.white
                            )
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Favorite Poems")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                #if os(visionOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 70))
                .foregroundColor(.gray)
                .accessibilityHidden(true)
            
            Text("No Favorite Poems Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your favorite poems will appear here.")
                .foregroundColor(.secondary)
            
            Button("Done") {
                dismiss()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color.blue))
            .foregroundColor(.white)
            .padding(.top, 16)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No favorite poems yet. Your favorite poems will appear here.")
    }
}

// MARK: - Favorite Poem Detail View

struct FavoritePoemDetailView: View {
    let poem: Poem
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(poem.title)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .accessibilityAddTraits(.isHeader)
                
                if let author = poem.author {
                    Text("by \(author)")
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .accessibilityHidden(true)
                
                Text(poem.content)
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .lineSpacing(8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.2) : Color(red: 0.9, green: 0.95, blue: 1.0),
                    colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color(red: 0.8, green: 0.9, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

// For SwiftUI Preview
#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.light)
        
        ContentView()
            .preferredColorScheme(.dark)
    }
}
#endif
