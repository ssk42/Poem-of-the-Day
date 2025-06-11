import XCTest
import Combine
@testable import Poem_of_the_Day

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "No handler", code: 0))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class PoemViewModelTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockURLProtocol.requestHandler = nil
        cancellables.removeAll()
        super.tearDown()
    }

    func testFetchPoemOfTheDayDecodesData() {
        let expectation = expectation(description: "Poem fetched")

        let json = """
        [{
            "title": "Sample Title",
            "lines": ["Line one", "Line two"],
            "author": "Tester"
        }]
        """
        let data = json.data(using: .utf8)!
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let viewModel = PoemViewModel()
        viewModel.$poemOfTheDay
            .dropFirst()
            .sink { poem in
                if let poem = poem {
                    XCTAssertEqual(poem.title, "Sample Title")
                    XCTAssertEqual(poem.content, "Line one\nLine two")
                    XCTAssertEqual(poem.author, "Tester")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.fetchPoemOfTheDay(force: true)

        waitForExpectations(timeout: 1)
    }
}
