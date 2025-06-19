//
//  ErrorView.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import SwiftUI

/// Reusable error view component
struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var errorInfo: (title: String, message: String, icon: String) {
        if let poemError = error as? PoemError {
            return errorDetails(for: poemError)
        } else {
            return (
                title: "Something went wrong",
                message: error.localizedDescription,
                icon: "exclamationmark.triangle"
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: errorInfo.icon)
                .font(.system(size: 50))
                .foregroundColor(.appError)
                .padding(.bottom, 8)
            
            Text(errorInfo.title)
                .font(.headline)
                .foregroundColor(.primaryText)
                .multilineTextAlignment(.center)
            
            Text(errorInfo.message)
                .font(.subheadline)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: retryAction) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.appPrimary)
                    .cornerRadius(AppConfiguration.UI.buttonCornerRadius)
            }
            .hapticFeedback()
        }
        .padding()
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(errorInfo.title). \(errorInfo.message)")
        .accessibilityAction(named: "Retry") {
            retryAction()
        }
    }
    
    private func errorDetails(for error: PoemError) -> (title: String, message: String, icon: String) {
        switch error {
        case .networkUnavailable:
            return (
                title: "No Internet Connection",
                message: "Please check your internet connection and try again.",
                icon: "wifi.slash"
            )
        case .noPoems:
            return (
                title: "No Poems Available",
                message: "We couldn't find any poems right now. Please try again later.",
                icon: "book.closed"
            )
        case .rateLimited:
            return (
                title: "Too Many Requests",
                message: "Please wait a moment before requesting another poem.",
                icon: "clock"
            )
        case .unsupportedOperation:
            return (
                title: "Feature Not Available",
                message: "This feature is not available on your device.",
                icon: "exclamationmark.triangle"
            )
        case .serverError(let code):
            return (
                title: "Server Error",
                message: "The server encountered an error (\(code)). Please try again later.",
                icon: "server.rack"
            )
        default:
            return (
                title: "Something went wrong",
                message: error.localizedDescription,
                icon: "exclamationmark.triangle"
            )
        }
    }
}

/// Compact error view for inline use
struct InlineErrorView: View {
    let message: String
    let retryAction: (() -> Void)?
    
    init(message: String, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
                .foregroundColor(.appError)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            if let retryAction = retryAction {
                Button("Retry", action: retryAction)
                    .font(.caption)
                    .foregroundColor(.appPrimary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.appError.opacity(0.1))
        )
    }
}

/// Error alert modifier
struct ErrorAlert: ViewModifier {
    @Binding var error: Error?
    let retryAction: (() -> Void)?
    
    init(error: Binding<Error?>, retryAction: (() -> Void)? = nil) {
        self._error = error
        self.retryAction = retryAction
    }
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                }
                
                if let retryAction = retryAction {
                    Button("Retry") {
                        error = nil
                        retryAction()
                    }
                }
            } message: {
                if let error = error {
                    Text(error.localizedDescription)
                }
            }
    }
}

extension View {
    func errorAlert(_ error: Binding<Error?>, retryAction: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlert(error: error, retryAction: retryAction))
    }
}

// MARK: - Previews

#if DEBUG
struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ErrorView(
                error: PoemError.networkUnavailable,
                retryAction: {}
            )
            .preferredColorScheme(.light)
            .previewDisplayName("Network Error - Light")
            
            ErrorView(
                error: PoemError.noPoems,
                retryAction: {}
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("No Poems - Dark")
            
            InlineErrorView(
                message: "Failed to load content",
                retryAction: {}
            )
            .previewDisplayName("Inline Error")
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
#endif