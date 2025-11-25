//
//  View+Extensions.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - View Extensions

extension View {
    
    /// Apply conditional modifiers based on a boolean condition
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Apply conditional modifiers with else clause
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
    
    /// Add corner radius with specific corners
    #if canImport(UIKit)
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    #endif
    
    /// Add app-standard card styling
    func cardStyle(
        cornerRadius: CGFloat = AppConfiguration.UI.cardCornerRadius,
        shadowRadius: CGFloat = 10,
        shadowOpacity: Double = 0.1
    ) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: 5)
        )
    }
    
    /// Add app-standard button styling
    func buttonStyle(
        cornerRadius: CGFloat = AppConfiguration.UI.buttonCornerRadius,
        backgroundColor: Color = .blue,
        foregroundColor: Color = .white
    ) -> some View {
        self
            .foregroundColor(foregroundColor)
            .padding()
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
    }
    
    /// Add shimmer loading effect
    @ViewBuilder
    func shimmer(when isLoading: Bool) -> some View {
        if isLoading {
            self.overlay(
                ShimmerView()
                    .cornerRadius(AppConfiguration.UI.cardCornerRadius)
            )
        } else {
            self
        }
    }
    
    /// Add haptic feedback on tap
    func hapticFeedback(_ style: HapticFeedbackStyle = .medium) -> some View {
        onTapGesture {
            if AppConfiguration.UI.hapticFeedbackEnabled {
                #if canImport(UIKit)
                let impactFeedback = UIImpactFeedbackGenerator(style: style.uiKitStyle)
                impactFeedback.impactOccurred()
                #endif
            }
        }
    }
    
    /// Add accessibility traits and labels
    func accessibilityConfiguration(
        label: String? = nil,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .if(label != nil) { view in
                view.accessibilityLabel(label!)
            }
            .if(hint != nil) { view in
                view.accessibilityHint(hint!)
            }
            .accessibilityAddTraits(traits)
    }
}

// MARK: - Haptic Feedback Support

enum HapticFeedbackStyle {
    case light
    case medium
    case heavy
    case soft
    case rigid
    
    #if canImport(UIKit)
    var uiKitStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .light: return .light
        case .medium: return .medium
        case .heavy: return .heavy
        case .soft: return .soft
        case .rigid: return .rigid
        }
    }
    #endif
}

// MARK: - Custom Shapes

#if canImport(UIKit)
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
#endif

// MARK: - Shimmer Effect

struct ShimmerView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.gray.opacity(0.3),
                Color.white.opacity(0.8),
                Color.gray.opacity(0.3)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .scaleEffect(x: 3, y: 1, anchor: .center)
        .offset(x: phase)
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                phase = 300
            }
        }
    }
}

// MARK: - Color Extensions

extension Color {
    
    /// App-specific color palette
    static let appPrimary = Color.blue
    static let appSecondary = Color.purple
    static let appSuccess = Color.green
    static let appWarning = Color.orange
    static let appError = Color.red
    
    /// Dynamic colors that adapt to light/dark mode
    static let cardBackground = Color(.systemBackground)
    static let cardSecondaryBackground = Color(.secondarySystemBackground)
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    
    /// Vibe-specific colors
    static func vibeColor(for vibe: DailyVibe) -> Color {
        switch vibe {
        case .hopeful:
            return .green
        case .contemplative:
            return .indigo
        case .energetic:
            return .orange
        case .peaceful:
            return .mint
        case .melancholic:
            return .gray
        case .inspiring:
            return .yellow
        case .uncertain:
            return .purple
        case .celebratory:
            return .pink
        case .reflective:
            return .brown
        case .determined:
            return .red
        case .nostalgic:
            return .brown
        case .adventurous:
            return .teal
        case .whimsical:
            return .purple
        case .urgent:
            return .orange
        case .triumphant:
            return .yellow
        case .solemn:
            return .gray
        case .playful:
            return .pink
        case .mysterious:
            return .indigo
        case .rebellious:
            return .red
        case .compassionate:
            return .pink
        }
    }
}