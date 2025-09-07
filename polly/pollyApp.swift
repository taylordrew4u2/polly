//
//  pollyApp.swift
//  polly
//
//  Created by taylor drew on 9/1/25.
//

import SwiftUI
import SwiftData

@main
struct pollyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true) // Changed to in-memory for simpler startup

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark) // Ensure dark mode for better compatibility with the timer UI
        }
        .modelContainer(sharedModelContainer)
    }
}
