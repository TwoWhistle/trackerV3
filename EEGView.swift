//
//  EEGView.swift
//  trackerV3
//
//  Created by Ryan Yue on 2/5/25.
//


import SwiftUI
import Charts

struct EEGView: View {
    @ObservedObject var bleManager: BLEManager
    @State private var eegData: [EEGDataPoint] = []

    let maxDataPoints = 100

    var body: some View {
        VStack {
            Text("EEG Frequency Bands")
                .font(.title)
                .padding()

            Chart(eegData) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("EEG Band Power", point.value)
                )
                .foregroundStyle(by: .value("Band", point.band))
            }
            .frame(height: 250)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(["Delta", "Theta", "Alpha", "Beta", "Gamma"], id: \.self) { band in
                    HStack {
                        Text("\(band):")
                        Spacer()
                        Text("\(bleManager.eegBands[band] ?? 0, specifier: "%.2f") µV²")
                            .foregroundColor(colorForBand(band)) // ✅ FIXED!
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
        }
        .padding()
    }

    /// ✅ FIX: Function to return colors for each EEG band
    private func colorForBand(_ band: String) -> Color {
        switch band {
        case "Delta": return .blue
        case "Theta": return .purple
        case "Alpha": return .green
        case "Beta": return .orange
        case "Gamma": return .red
        default: return .black
        }
    }
}

/// EEG Data Struct for Charting
struct EEGDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Float
    let band: String
}



