import SwiftUI

struct TelemetryDebugView: View {
    @State private var events: [AnyTelemetryEvent] = []
    @State private var summary: TelemetryEventSummary = TelemetryEventSummary()
    @State private var isLoading = false
    @State private var showShareSheet = false
    @State private var exportData = ""
    
    private let telemetryService: TelemetryServiceProtocol
    
    @MainActor
    init(telemetryService: TelemetryServiceProtocol? = nil) {
        self.telemetryService = telemetryService ?? DependencyContainer.shared.makeTelemetryService()
    }
    
    var body: some View {
        NavigationView {
            List {
                summarySection
                eventsSection
            }
            .navigationTitle("Telemetry Debug")
            .toolbar {
                #if os(visionOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Export") {
                        exportTelemetryData()
                    }
                }
                #elseif os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        exportTelemetryData()
                    }
                }
                #endif
            }
            .refreshable {
                await loadTelemetryData()
            }
            .sheet(isPresented: $showShareSheet) {
                #if canImport(UIKit)
                ShareSheet(items: [exportData])
                #else
                Text("Sharing not supported on this platform")
                #endif
            }
        }
        .task {
            await loadTelemetryData()
        }
    }
    
    private var summarySection: some View {
        Section("Summary") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total Events:")
                    Spacer()
                    Text("\(summary.totalEvents)")
                        .fontWeight(.semibold)
                }
                
                if let mostCommon = summary.mostCommonEvent {
                    HStack {
                        Text("Most Common:")
                        Spacer()
                        Text(mostCommon)
                            .fontWeight(.semibold)
                    }
                }
                
                HStack {
                    Text("Avg/Day:")
                    Spacer()
                    Text(String(format: "%.1f", summary.averageEventsPerDay))
                        .fontWeight(.semibold)
                }
                
                if let dateRange = summary.dateRange {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Date Range:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(dateRange.start, style: .date) - \(dateRange.end, style: .date)")
                            .font(.caption)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var eventsSection: some View {
        Section("Event Breakdown") {
            ForEach(summary.eventCounts.sorted(by: { $0.value > $1.value }), id: \.key) { eventName, count in
                HStack {
                    Text(eventName.replacingOccurrences(of: "_", with: " ").capitalized)
                    Spacer()
                    Text("\(count)")
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
            
            if summary.sourceBreakdown.count > 1 {
                Divider()
                
                ForEach(summary.sourceBreakdown.sorted(by: { $0.value > $1.value }), id: \.key) { source, count in
                    HStack {
                        Text("\(source.capitalized) Events:")
                        Spacer()
                        Text("\(count)")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    private func loadTelemetryData() async {
        isLoading = true
        
        async let eventsTask = telemetryService.exportAllEvents()
        async let summaryTask = telemetryService.getEventSummary()
        
        events = await eventsTask
        summary = await summaryTask
        
        isLoading = false
    }
    
    private func exportTelemetryData() {
        Task {
            if let jsonData = await telemetryService.exportEventsAsJSON() {
                exportData = jsonData
                showShareSheet = true
            }
        }
    }
}

// ShareSheet is defined in ContentView.swift

#Preview {
    TelemetryDebugView(telemetryService: MockTelemetryService())
}