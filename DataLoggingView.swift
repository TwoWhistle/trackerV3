//
//  DataLoggingView.swift
//  trackerV3
//
//  Created by Ryan Yue on 2/18/25.
//

// DataLoggingView.swift
import SwiftUI

struct DataLoggingView: View {
    @ObservedObject var bleManager: BLEManager
    @State private var selectedState: String = ""
    @State private var selectedTime: Date = Date()
    @State private var loggedData: [(Date, String)] = []
    
    let brainStates = [
        "Focused", "Distracted", "Fatigued", "Relaxed", "Overstimulated",
        "Active Learning", "Passive Learning", "Struggling", "Memorizing", "Comprehending",
        "Motivated", "Bored", "Frustrated", "Confident", "Happy", "Sad", "Angry", "Fearful",
        "Rested", "Drowsy", "Stressed", "Flow State"
    ]
    
    var body: some View {
        VStack {
            Text("Data Logging")
                .font(.title)
                .padding()
            
            Text("""
            1. Cognitive States
            Focused, Distracted, Fatigued, Relaxed, Overstimulated
            2. Learning States
            Active Learning, Passive Learning, Struggling, Memorizing, Comprehending
            3. Emotional States
            Motivated, Bored, Frustrated, Confident, Happy, Sad, Angry, Fearful
            4. Physiological States
            Rested, Drowsy, Stressed, Flow State
            """)
            .padding()
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Picker("Select State", selection: $selectedState) {
                ForEach(brainStates, id: \..self) { state in
                    Text(state)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            
            DatePicker("Select Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .padding()
            
            Button("Log Entry") {
                loggedData.append((selectedTime, selectedState))
                saveToFile()
            }
            .padding()
            .buttonStyle(.borderedProminent)
            
            Button("Export Data") {
                exportData()
            }
            .padding()
            Button("Export Raw EEG Data") {
                bleManager.exportEEGData()
            }
            .padding()
            .buttonStyle(.borderedProminent)
        }
    }
    
    func saveToFile() {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("BrainStateLog.txt")
        let content = loggedData.map { "\($0.0),\($0.1)" }.joined(separator: "\n")
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    func exportData() {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("BrainStateLog.txt")
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
    }
}
