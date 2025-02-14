//
//  HeartRateView.swift
//  trackerV3
//
//  Created by Ryan Yue on 2/5/25.
//

import SwiftUI
import Charts

struct HeartRateView: View {
    @ObservedObject var bleManager: BLEManager
    @State private var heartRateData: [HeartRateDataPoint] = []  // Stores HR data for graph

    let maxDataPoints = 100  // Limits how many points appear on the graph

    var body: some View {
        VStack {
            Text("Heart Rate Monitor")
                .font(.title)
                .padding()

            VStack {
                Text("Current Heart Rate:")
                    .font(.headline)

                Text("\(bleManager.receivedHR) BPM")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
            .padding()

            Chart(heartRateData) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Heart Rate", point.value)
                )
                .foregroundStyle(.red)
            }
            .frame(height: 250)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)

            Spacer()
        }
        .padding()
        .onReceive(bleManager.$receivedHR) { newHR in
            addNewDataPoint(newHR)
        }
    }

    /// Adds new heart rate data points to the graph while keeping a rolling buffer
    private func addNewDataPoint(_ newHR: String) {
        if let hrValue = Float(newHR) {
            let timestamp = Date()
            heartRateData.append(HeartRateDataPoint(timestamp: timestamp, value: hrValue))

            if heartRateData.count > maxDataPoints {
                heartRateData.removeFirst(heartRateData.count - maxDataPoints)
            }
        }
    }
}

/// Represents a single heart rate data point for the chart
struct HeartRateDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Float
}

#Preview {
    HeartRateView(bleManager: BLEManager())
}
