//
//  Poem_of_the_DayTests.swift
//  Poem of the DayTests
//
//  Created by Stephen Reitz on 11/14/24.
//

import Testing
@testable import Poem_of_the_Day

struct Poem_of_the_DayTests {

    @Test func example() async throws {
        let response = PoemResponse(
            title: "Test Title",
            lines: ["Line one", "Line two"],
            author: "Test Author"
        )

        let poem = response.toPoem()

        #expect(poem.title == "Test Title")
        #expect(poem.content == "Line one\nLine two")
        #expect(poem.author == "Test Author")
    }

}
