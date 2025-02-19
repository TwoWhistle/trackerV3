//
//  BLEManager.swift
//  trackerV3
//
//  Created by Ryan Yue on 2/4/25.
//


import CoreBluetooth
import SwiftUI

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var receivedHR: String = "0"
    @Published var receivedEEG: String = "0"
    @Published var eegBands: [String: Float] = ["Delta": 0, "Theta": 0, "Alpha": 0, "Beta": 0, "Gamma": 0]

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var heartRateCharacteristic: CBCharacteristic?
    private var eegCharacteristic: CBCharacteristic?

    let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789abc")
    let heartRateCharUUID = CBUUID(string: "abcd1234-ab12-cd34-ef56-abcdef123456")
    let eegCharUUID = CBUUID(string: "abcd5678-ab12-cd34-ef56-abcdef123456")

    private var eegDataBuffer: [Float] = []  // Stores raw EEG data for FFT
    private var eegDataLog: [(Date, Float)] = [] // Stores raw EEG data with timestamps

    override init() {
        super.init()
        print("🔵 BLEManager Initialized - Starting Central Manager")
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    /// Check if Bluetooth is powered on
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("✅ Bluetooth is ON - Scanning for ALL peripherals...")
            central.scanForPeripherals(withServices: nil, options: nil) // Scan for ALL devices
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                print("⏳ Scan Check: If no devices found yet, BLE may not be working")
            }
        } else {
            print("❌ Bluetooth is OFF or Not Available")
        }
    }


    /// Found a BLE peripheral
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let peripheralName = peripheral.name ?? "Unknown Device"
        print("🔍 Discovered Peripheral: \(peripheralName) | RSSI: \(RSSI)")

        // 🔹 Relaxed Name Matching: Check if the name CONTAINS "ESP32"
        if peripheralName.lowercased().contains("esp32") {
            print("✅ Matched ESP32 Device: \(peripheralName)")
            connectedPeripheral = peripheral
            connectedPeripheral?.delegate = self
            centralManager.stopScan()
            print("🚀 Stopping Scan & Connecting to \(peripheralName)")
            centralManager.connect(peripheral, options: nil)
        }
    }


    /// Connected to the ESP32
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ Connected to ESP32 - Discovering Services...")
        peripheral.discoverServices([serviceUUID])
    }

    /// Failed to connect
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("🔴 BLE Disconnected from \(peripheral.name ?? "Unknown Device") - Restarting Scan...")

        // Reset stored peripheral references
        connectedPeripheral = nil
        heartRateCharacteristic = nil
        eegCharacteristic = nil

        // Restart scanning for ESP32
        central.scanForPeripherals(withServices: nil, options: nil)
    }


    /// Discovered BLE Services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("❌ Error discovering services: \(error.localizedDescription)")
            return
        }

        if let services = peripheral.services {
            for service in services {
                print("🛠 Discovered Service: \(service.uuid)")
                if service.uuid == serviceUUID {
                    print("🔄 Discovering Characteristics for Service: \(serviceUUID)")
                    peripheral.discoverCharacteristics([heartRateCharUUID, eegCharUUID], for: service)
                }
            }
        } else {
            print("❌ No Services Found")
        }
    }

    /// Discovered BLE Characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("❌ Error discovering characteristics: \(error.localizedDescription)")
            return
        }

        for characteristic in service.characteristics ?? [] {
            print("📡 Found Characteristic: \(characteristic.uuid)")

            if characteristic.uuid == heartRateCharUUID {
                heartRateCharacteristic = characteristic
                print("🔔 Enabling notifications for Heart Rate")
                peripheral.setNotifyValue(true, for: characteristic)
            } else if characteristic.uuid == eegCharUUID {
                eegCharacteristic = characteristic
                print("🔔 Enabling notifications for EEG Data")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    /// BLE Data Received
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("📡 Data Received from \(characteristic.uuid)")

        if let data = characteristic.value {
            let stringValue = String(data: data, encoding: .utf8) ?? "N/A"
            print("📩 Raw Data: \(stringValue)")

            if characteristic.uuid == heartRateCharUUID {
                DispatchQueue.main.async {
                    self.receivedHR = stringValue
                }
                print("❤️ Heart Rate Updated: \(stringValue)")
            }
            else if characteristic.uuid == eegCharUUID {
                if let eegValue = Float(stringValue) {
                    DispatchQueue.main.async {
                        self.receivedEEG = stringValue
                    }
                    processEEGData(eegValue)
                    self.saveEEGData(eegValue)
                    print("🧠 EEG Data Updated: \(stringValue)")
                } else {
                    print("⚠️ Invalid EEG Data: \(stringValue)")
                }
            }
        } else {
            print("❌ No Data Received")
        }
    }

    /// Stores EEG data and triggers FFT when buffer is full
    private func processEEGData(_ eegValue: Float) {
        print("📊 Processing EEG Value: \(eegValue)")

        eegDataBuffer.append(eegValue)
        print("📈 EEG Buffer Size: \(eegDataBuffer.count)/256")


        if eegDataBuffer.count >= 256 {
            print("⚡ Running FFT on EEG Data...")
            let newBands = FFTProcessor.performFFT(eegDataBuffer)

            DispatchQueue.main.async {
                self.eegBands = newBands
                print("🎯 EEG Bands Updated: \(self.eegBands)")
            }

            eegDataBuffer.removeAll()
        }
    }
    
    
    /// Stores EEG data with timestamp
        private func saveEEGData(_ eegValue: Float) {
            let timestamp = Date()
            self.eegDataLog.append((timestamp, eegValue))
            let entry = "\(timestamp),\(eegValue)\n"
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("EEGDataLog.txt")
            
            if let handle = try? FileHandle(forWritingTo: fileURL) {
                handle.seekToEndOfFile()
                if let data = entry.data(using: .utf8) {
                    handle.write(data)
                }
                handle.closeFile()
            } else {
                try? entry.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        }
        
        /// Exports EEG data log
        func exportEEGData() {
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("EEGDataLog.txt")
            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
        }

}

