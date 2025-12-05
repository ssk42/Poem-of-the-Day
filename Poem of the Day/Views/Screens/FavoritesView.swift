//
//  FavoritesView.swift
//  Poem of the Day
//
//  Extracted from ContentView.swift for better maintainability
//

import SwiftUI

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
                        .onAppear { NSLog("FavoritesView: Showing empty state view") }
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
                    .accessibilityIdentifier("favorites_list")
                    #if os(iOS)
                    .listStyle(InsetGroupedListStyle())
                    #endif
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Favorite Poems")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(visionOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #elseif os(iOS)
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
        .accessibilityIdentifier("favorites_empty_state")
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
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
