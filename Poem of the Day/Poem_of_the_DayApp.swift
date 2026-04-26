//
//  Poem_of_the_DayApp.swift
//  Poem of the Day
//
//  Created by Stephen Reitz on 11/14/24.
//

import SwiftUI

@main
struct Poem_of_the_DayApp: App {
    @StateObject private var dependencies = DependencyContainer.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dependencies)
        }
    }
}
