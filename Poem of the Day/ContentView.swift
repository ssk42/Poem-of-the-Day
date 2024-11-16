import SwiftUI
import WidgetKit
import Combine

struct ContentView: View {
    @StateObject private var viewModel = PoemViewModel()
    @State private var showFavorites = false

    var body: some View {
        VStack {
            Spacer()
            Button(action: {
                viewModel.fetchPoemOfTheDay()
                WidgetCenter.shared.reloadAllTimelines() // Notify the widget to update
            }) {
                Text("Fetch New Poem")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()

            Text("Poem of the Day")
                .font(.largeTitle)
                .padding()

            if let poem = viewModel.poemOfTheDay {
                Text(poem.title)
                    .font(.title)
                    .padding(.top, 20)
                
                if let author = poem.author {
                    Text("by \(author)")
                        .font(.subheadline)
                        .padding(.bottom, 10)
                }

                ScrollView {
                    VStack(alignment: .leading) {
                        Text(poem.content)
                            .padding(.top, 10)
                            .padding(.horizontal)
                    }
                }
                .frame(maxHeight: .infinity)

                Button(action: {
                    viewModel.toggleFavorite(poem: poem)
                }) {
                    HStack {
                        Image(systemName: viewModel.isFavorite(poem: poem) ? "heart.fill" : "heart")
                            .foregroundColor(viewModel.isFavorite(poem: poem) ? .red : .gray)
                        Text(viewModel.isFavorite(poem: poem) ? "Unfavorite" : "Favorite")
                    }
                }
                .padding()
            } else {
                ProgressView("Loading...")
            }

            Button(action: {
                showFavorites = true
            }) {
                Text("View Favorites")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .sheet(isPresented: $showFavorites) {
                FavoritesView(favorites: viewModel.favorites)
            }
        }
        .padding()
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("Error"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

struct FavoritesView: View {
    let favorites: [Poem]

    var body: some View {
        NavigationView {
            List(favorites) { poem in
                VStack(alignment: .leading) {
                    Text(poem.title)
                        .font(.headline)
                    if let author = poem.author {
                        Text("by \(author)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text(poem.content)
                        .font(.body)
                        .lineLimit(3)
                        .padding(.top, 5)
                }
            }
            .navigationTitle("Favorite Poems")
        }
    }
}

class PoemViewModel: ObservableObject {
    private let sharedDefaults = UserDefaults(suiteName: "group.com.stevereitz.poemoftheday")
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var poemOfTheDay: Poem?
    @Published var favorites: [Poem] = []
    private var cancellable: AnyCancellable?

    init() {
        loadPoemFromSharedStorage()
        loadFavorites()
        if poemOfTheDay == nil {
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

    func fetchPoemOfTheDay() {
        loadPoemFromSharedStorage() // Load the saved poem first, if available
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
                    self?.alertMessage = "The poem could not be found (404 error). Please try again later."
                }
                return Just(Poem(id: UUID(), title: "Default Poem", lines: ["This is a default poem content."])).eraseToAnyPublisher()
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
