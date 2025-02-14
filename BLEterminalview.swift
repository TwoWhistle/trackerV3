//
//  BLEterminalview.swift
//  trackerV3
//
//  Created by Ryan Yue on 2/4/25.
//

import SwiftUI

struct BLETerminalView: View {
    @ObservedObject var bleManager: BLEManager  // Correctly use ObservableObject

    var body: some View {
        VStack {
            Text("BLE Terminal")
                .font(.title)
                .padding()

            Text("Received Data:")
                .font(.headline)

            Text(bleManager.receivedHR)  // Use correct property
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    BLETerminalView(bleManager: BLEManager())  // Ensure BLEManager is passed correctly
}

