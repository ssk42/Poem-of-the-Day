//
//  VibeGenerationView.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import SwiftUI

struct VibeGenerationView: View {
    let vibeAnalysis: VibeAnalysis
    let onGeneratePoem: () -> Void
    let onCustomPrompt: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerView
                        vibeCard
                        actionButtons
                    }
                    .padding()
                }
            }
            .navigationTitle("Today's Vibe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("cancel_button")
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
            Text(vibeAnalysis.vibe.emoji)
                .font(.system(size: 60))
                .padding(.bottom, 8)
            
            Text("Today's Vibe: \(vibeAnalysis.vibe.displayName)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .accessibilityIdentifier("current_vibe")
            
            Text(vibeAnalysis.vibe.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var vibeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Analysis")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text(vibeAnalysis.reasoning)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            
            if !vibeAnalysis.keywords.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Themes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(vibeAnalysis.keywords.prefix(6), id: \.self) { keyword in
                            Text(keyword)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(colorScheme == .dark ? Color(red: 0.3, green: 0.3, blue: 0.4) : Color(red: 0.95, green: 0.95, blue: 0.97))
                                )
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            sentimentIndicator
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private var sentimentIndicator: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sentiment Analysis")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            VStack(spacing: 8) {
                sentimentBar(label: "Positivity", value: vibeAnalysis.sentiment.positivity, color: .green)
                sentimentBar(label: "Energy", value: vibeAnalysis.sentiment.energy, color: .orange)
                sentimentBar(label: "Complexity", value: vibeAnalysis.sentiment.complexity, color: .blue)
            }
        }
    }
    
    private func sentimentBar(label: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * value, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button(action: onGeneratePoem) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                    Text("Generate Poem from Today's Vibe")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .accessibilityLabel("Generate a poem based on today's vibe")
            .accessibilityIdentifier("generate_vibe_poem_button")
            
            Button(action: onCustomPrompt) {
                HStack {
                    Image(systemName: "pencil.and.outline")
                        .font(.title3)
                    Text("Write Custom Poem")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.purple)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    Capsule()
                        .strokeBorder(Color.purple, lineWidth: 2)
                        .background(Capsule().fill(Color.clear))
                )
            }
            .accessibilityLabel("Write a custom poem with your own prompt")
        }
    }
}

struct CustomPromptView: View {
    @State private var promptText: String = ""
    let onGenerate: (String) -> Void
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
                
                VStack(spacing: 24) {
                    headerSection
                    promptInputSection
                    Spacer()
                    generateButton
                }
                .padding()
            }
            .navigationTitle("Custom Poem")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("cancel_button")
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "pencil.and.outline")
                .font(.system(size: 40))
                .foregroundColor(.purple)
                .padding(.bottom, 8)
            
            Text("Create Your Own Poem")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Text("Describe what you'd like your poem to be about")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var promptInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Poem Idea")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            TextEditor(text: $promptText)
                .font(.body)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .frame(minHeight: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .accessibilityIdentifier("custom_prompt_text_field")
            
            Text("Examples: \"A poem about friendship\", \"Write about the ocean at sunset\", \"Something inspiring about overcoming challenges\"")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
    }
    
    private var generateButton: some View {
        Button(action: {
            onGenerate(promptText)
            dismiss()
        }) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title3)
                Text("Generate Poem")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .accessibilityIdentifier("generate_custom_poem_button")
        .disabled(promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
    }
}

#if DEBUG
struct VibeGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        let mockVibe = VibeAnalysis(
            vibe: .hopeful,
            confidence: 0.8,
            reasoning: "Today's news reflects positive developments in renewable energy and community initiatives, suggesting an optimistic outlook.",
            keywords: ["breakthrough", "community", "positive", "innovation", "hope"],
            sentiment: SentimentScore(positivity: 0.7, energy: 0.6, complexity: 0.5)
        )
        
        VibeGenerationView(
            vibeAnalysis: mockVibe,
            onGeneratePoem: {},
            onCustomPrompt: {}
        )
        .preferredColorScheme(.light)
        
        VibeGenerationView(
            vibeAnalysis: mockVibe,
            onGeneratePoem: {},
            onCustomPrompt: {}
        )
        .preferredColorScheme(.dark)
        
        CustomPromptView(onGenerate: { _ in })
            .preferredColorScheme(.light)
    }
}
#endif