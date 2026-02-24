#if false
//
//  Nourish_BuddyApp.swift
//  Nourish Buddy
//
//  Created by Matthew Beason on 5/4/25.
//

import SwiftUI
import SwiftData

@main
struct Nourish_BuddyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
#endif
