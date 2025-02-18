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
        ScrollView {
            VStack {
                Text("EEG Frequency Bands")
                    .font(.title)
                    .padding()
                
                /*Chart(eegData) { point in
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
                 */
                
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
                
                // ✅ Relative EEG Power (% of Total)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Relative EEG Power (%)")
                        .font(.headline)
                    
                    let totalPower = bleManager.eegBands.values.reduce(0, +)
                    
                    ForEach(["Delta", "Theta", "Alpha", "Beta", "Gamma"], id: \.self) { band in
                        let power = bleManager.eegBands[band] ?? 0
                        let relativePower = totalPower > 0 ? (power / totalPower * 100) : 0  // Avoid division by zero
                        
                        HStack {
                            Text("\(band):")
                            Spacer()
                            Text("\(relativePower, specifier: "%.1f")%")
                                .foregroundColor(colorForBand(band))
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                
                // ✅ EEG Power Ratios (Beta/Alpha, Theta/Beta, Gamma/Beta)
                VStack(alignment: .leading, spacing: 10) {
                    Text("EEG Power Ratios")
                        .font(.headline)
                    
                    let beta = bleManager.eegBands["Beta"] ?? 0
                    let alpha = bleManager.eegBands["Alpha"] ?? 0
                    let theta = bleManager.eegBands["Theta"] ?? 0
                    let gamma = bleManager.eegBands["Gamma"] ?? 0
                    
                    let betaAlphaRatio = alpha > 0 ? beta / alpha : 0
                    let thetaBetaRatio = beta > 0 ? theta / beta : 0
                    let gammaBetaRatio = beta > 0 ? gamma / beta : 0
                    
                    // ✅ Beta/Alpha Ratio
                    HStack {
                        Text("Beta/Alpha:")
                        Spacer()
                        Text("\(betaAlphaRatio, specifier: "%.2f")")
                            .foregroundColor(.orange)
                    }
                    Text(" - 🔹 **High (>3.0):** Increased focus, stress, or anxiety")
                    Text(" - 🔹 **Low (<1.5):** Relaxation, decreased attention")
                    
                    // ✅ Theta/Beta Ratio
                    HStack {
                        Text("Theta/Beta:")
                        Spacer()
                        Text("\(thetaBetaRatio, specifier: "%.2f")")
                            .foregroundColor(.purple)
                    }
                    Text(" - 🔹 **High (>3.5):** Linked to ADHD, difficulty concentrating")
                    Text(" - 🔹 **Low (<2.0):** Strong attention and cognitive control")
                    
                    // ✅ Gamma/Beta Ratio
                    HStack {
                        Text("Gamma/Beta:")
                        Spacer()
                        Text("\(gammaBetaRatio, specifier: "%.2f")")
                            .foregroundColor(.red)
                    }
                    Text(" - 🔹 **High (>1.2):** Strong cognitive processing, meditation")
                    Text(" - 🔹 **Low (<0.5):** Low cognitive activity, fatigue")
                    
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
            }
            .padding()
        }
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



