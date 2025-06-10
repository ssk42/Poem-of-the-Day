import SwiftUI
import WidgetKit
import Combine

struct ContentView: View {
    // This is the original line from your paste.txt
    @StateObject private var viewModel = PoemViewModel()
    @State private var showFavorites = false
    @State private var isRefreshing = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerView
                        
                        if let poem = viewModel.poemOfTheDay {
                            poemCard(poem: poem)
                        } else {
                            loadingView
                        }
                        
                        controlButtons
                    }
                    .padding()
                }
                .refreshable {
                    isRefreshing = true
                    viewModel.fetchPoemOfTheDay()
                    WidgetCenter.shared.reloadAllTimelines()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        isRefreshing = false
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showFavorites = true
                    }) {
                        Label("Favorites", systemImage: "heart.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $showFavorites) {
                FavoritesView(favorites: viewModel.favorites)
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Error"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // MARK: - UI Components
    
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
        VStack(spacing: 8) {
            Text("Poem of the Day")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Text(formattedDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
    
    private func poemCard(poem: Poem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(poem.title)
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                if let author = poem.author {
                    Text("by \(author)")
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            Text(poem.content)
                .font(.system(size: 16, weight: .regular, design: .serif))
                .lineSpacing(8)
                .padding(.vertical, 8)
            
            HStack {
                Spacer()
                
                Button(action: {
                    viewModel.toggleFavorite(poem: poem)
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
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text("Loading your poem...")
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundColor(.secondary)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // Update the controlButtons variable in ContentView.swift
    private var controlButtons: some View {
        Button(action: {
            // Force a new poem fetch regardless of when the last one was fetched
            viewModel.fetchPoemOfTheDay(force: true)
            WidgetCenter.shared.reloadAllTimelines()
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
    }
}

// MARK: - Favorites View

struct FavoritesView: View {
    let favorites: [Poem]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
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
                            }
                            .listRowBackground(
                                colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color.white
                            )
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Favorite Poems")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 70))
                .foregroundColor(.gray)
            
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
                
                if let author = poem.author {
                    Text("by \(author)")
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
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

class PoemViewModel: ObservableObject {
    private let sharedDefaults = UserDefaults(suiteName: "group.com.stevereitz.poemoftheday")
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var poemOfTheDay: Poem?
    @Published var favorites: [Poem] = []
    private var cancellable: AnyCancellable?

    init() {
        loadFavorites()
        checkAndUpdateDailyPoem()
    }
    
    // Check if we need a new poem based on the date
    private func checkAndUpdateDailyPoem() {
        // Check if we have a stored poem
        loadPoemFromSharedStorage()
        
        // Check when the last poem was fetched
        let calendar = Calendar.current
        let now = Date()
        
        if let lastFetchDate = sharedDefaults?.object(forKey: "lastPoemFetchDate") as? Date {
            // Check if the last fetch date is from a previous day
            if !calendar.isDate(lastFetchDate, inSameDayAs: now) {
                // It's a new day, fetch a new poem
                fetchPoemOfTheDay()
            }
        } else {
            // No fetch date stored, this is first run or data was cleared
            fetchPoemOfTheDay()
        }
    }

    func loadPoemFromSharedStorage() {
        if let title = sharedDefaults?.string(forKey: "poemTitle"),
           let content = sharedDefaults?.string(forKey: "poemContent"),
           let author = sharedDefaults?.string(forKey: "poemAuthor") {
            self.poemOfTheDay = Poem(title: title, lines: content.components(separatedBy: "\n"), author: author)
        }
    }

    func fetchPoemOfTheDay(force: Bool = false) {
        // Check if we should fetch a new poem
        if !force {
            let calendar = Calendar.current
            let now = Date()
            
            if let lastFetchDate = sharedDefaults?.object(forKey: "lastPoemFetchDate") as? Date,
               calendar.isDate(lastFetchDate, inSameDayAs: now) {
                // Already fetched a poem today, just load from storage
                loadPoemFromSharedStorage()
                return
            }
        }
        
        // Proceed with fetching a new poem
        let urlString = "https://poetrydb.org/random"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }

        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { output -> Data in
                guard let httpResponse = output.response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                print("HTTP Status Code: \(httpResponse.statusCode)")
                guard (200...299).contains(httpResponse.statusCode) else {
                    if httpResponse.statusCode == 404 {
                        throw URLError(.fileDoesNotExist)
                    } else {
                        throw URLError(.init(rawValue: httpResponse.statusCode))
                    }
                }
                return output.data
            }
            .receive(on: DispatchQueue.main)
            .retry(2) // Retry twice before failing
            .handleEvents(receiveSubscription: { _ in print("Fetching poem...") },
                          receiveOutput: { data in
                              if let jsonString = String(data: data, encoding: .utf8) {
                                  print("Received JSON: \(jsonString)")
                              }
                          },
                          receiveCompletion: { completion in
                              switch completion {
                              case .finished:
                                  print("Finished successfully")
                              case .failure(let error):
                                  print("Error during completion: \(error.localizedDescription)")
                              }
                          },
                          receiveCancel: { print("Cancelled") })
            .decode(type: [PoemResponse].self, decoder: JSONDecoder())
            .compactMap { $0.first?.toPoem() }  // Convert PoemResponse to Poem
            .catch { [weak self] error -> AnyPublisher<Poem, Never> in
                DispatchQueue.main.async {
                    self?.showAlert = true
                    if let urlError = error as? URLError,
                       urlError.code == .fileDoesNotExist {
                        self?.alertMessage = "The poem could not be found (404 error). Please try again later."
                    } else {
                        self?.alertMessage = "Failed to fetch poem. Please try again later."
                    }
                }
                return Just(
                    Poem(id: UUID(), title: "Default Poem", lines: ["This is a default poem content."])
                ).eraseToAnyPublisher()
            }
            
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    DispatchQueue.main.async {
                        self?.showAlert = true
                        self?.alertMessage = "Failed to load the poem of the day. Please try again later."
                    }
                    print("Sink received failure: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] poem in
                self?.poemOfTheDay = poem

                // Save poem to shared UserDefaults for the widget
                let sharedDefaults = UserDefaults(suiteName: "group.com.stevereitz.poemoftheday")
                sharedDefaults?.set(poem.title, forKey: "poemTitle")
                sharedDefaults?.set(poem.content, forKey: "poemContent")
                sharedDefaults?.set(poem.author ?? "", forKey: "poemAuthor")
                
                // Save the current date as the fetch date
                sharedDefaults?.set(Date(), forKey: "lastPoemFetchDate")

                // Notify widget to reload
                WidgetCenter.shared.reloadAllTimelines()
            })
    }

    func toggleFavorite(poem: Poem) {
        if let index = favorites.firstIndex(where: { $0.id == poem.id }) {
            favorites.remove(at: index)
        } else {
            favorites.append(poem)
        }
        saveFavorites()
    }

    func isFavorite(poem: Poem) -> Bool {
        return favorites.contains(where: { $0.id == poem.id })
    }

    private func loadFavorites() {
        if let data = sharedDefaults?.data(forKey: "favoritePoems"),
           let savedFavorites = try? JSONDecoder().decode([Poem].self, from: data) {
            self.favorites = savedFavorites
        }
    }

    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favorites) {
            sharedDefaults?.set(data, forKey: "favoritePoems")
        }
    }
}
