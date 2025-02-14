//
//  trackerV3App.swift
//  trackerV3
//
//  Created by Ryan Yue on 2/4/25.
//


import SwiftUI
import SwiftData

@main
struct trackerV3App: App {
    init() {
            print("🚀 App Started Successfully") // ✅ Ensures logs are printing
            UserDefaults.standard.set(true, forKey: "OS_ACTIVITY_MODE") // ✅ Forces debug logging
        }
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

    @StateObject var bleManager = BLEManager()  // Shared BLE manager instance

    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Tracker", systemImage: "list.bullet")
                    }

                BLETerminalView(bleManager: bleManager)
                    .tabItem {
                        Label("BLE Terminal", systemImage: "antenna.radiowaves.left.and.right")
                    }

                EEGView(bleManager: bleManager)
                    .tabItem {
                        Label("EEG Data", systemImage: "waveform")
                    }
                
                HeartRateView(bleManager: bleManager) // New Heart Rate Tab
                    .tabItem {
                        Label("Heart Rate", systemImage: "heart.fill")
                    }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
