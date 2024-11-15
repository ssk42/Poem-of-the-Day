import SwiftUI
import WidgetKit
import Combine

struct ContentView: View {
    @StateObject private var viewModel = PoemViewModel()

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
            } else {
                ProgressView("Loading...")
            }
        }
        .padding()
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("Error"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

class PoemViewModel: ObservableObject {
    private let sharedDefaults = UserDefaults(suiteName: "group.com.stevereitz.poemoftheday")
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var poemOfTheDay: Poem?
    private var cancellable: AnyCancellable?

    init() {
        loadPoemFromSharedStorage()
        if poemOfTheDay == nil {
            fetchPoemOfTheDay()
        }
    }

    func loadPoemFromSharedStorage() {
        if let title = sharedDefaults?.string(forKey: "poemTitle"),
           let content = sharedDefaults?.string(forKey: "poemContent") {
            self.poemOfTheDay = Poem(title: title, lines: content.components(separatedBy: "\n"))
        }
    }

    func fetchPoemOfTheDay() {
        loadPoemFromSharedStorage() // Load the saved poem first, if available
        guard let url = URL(string: "https://poetrydb.org/random") else {
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
            .catch { [weak self] error -> Just<Poem> in
                DispatchQueue.main.async {
                    self?.showAlert = true
                    if let urlError = error as? URLError, urlError.code == .fileDoesNotExist {
                        self?.alertMessage = "The poem could not be found (404 error). Please try again later."
                    } else {
                        self?.alertMessage = "Failed to load the poem of the day. Please try again later."
                    }
                }
                print("Error fetching poem: \(error.localizedDescription)")
                return Just(Poem(id: UUID(), title: "Default Poem", lines: ["This is a default poem content."]))
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

                // Notify widget to reload
                WidgetCenter.shared.reloadAllTimelines()
            })
    }
}
