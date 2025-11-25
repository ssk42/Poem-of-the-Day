import XCTest
@testable import Poem_of_the_Day

// Test to verify that our async MainActor pattern fixes work
final class SyntaxCheckTest: XCTestCase {
    
    var viewModel: PoemViewModel!
    
    @MainActor
    override func setUpWithError() throws {
        viewModel = PoemViewModel(repository: MockPoemRepository())
    }
    
    // Test the fixed pattern: async method calls without MainActor.run wrapper
    func testAsyncPatternFix() async throws {
        // This should compile without errors - direct async method call
        await viewModel.loadTodaysPoem()
        await viewModel.refreshPoem()
        await viewModel.generateCustomPoem(prompt: "test")
        
        // Property access still needs MainActor.run if necessary
        await MainActor.run {
            XCTAssertNotNil(viewModel.currentPoem)
        }
    }
    
    // Test concurrent operations without MainActor.run wrapper
    func testConcurrentAsyncOperations() async throws {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.viewModel.loadTodaysPoem()
            }
            group.addTask {
                await self.viewModel.refreshPoem()
            }
        }
    }
}