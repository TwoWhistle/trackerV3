//
//  FFTProcessor.swift
//  trackerV3
//
//  Created by Ryan Yue on 2/5/25.
//

import Foundation
import Accelerate

struct FFTProcessor {
    static func performFFT(_ eegData: [Float]) -> [String: Float] {
        let fftSize = 256
        let log2n = vDSP_Length(log2(Float(fftSize)))

        // ✅ Apply Notch Filter (Removes 60 Hz noise)
        let notchFilteredData = applyNotchFilter(eegData, notchFrequency: 60.0, samplingRate: 250.0)

        // ✅ Apply High-Pass Filter (Removes motion artifacts)
        let filteredData = applyHighPassFilter(notchFilteredData, cutoffFrequency: 1.0, samplingRate: 250.0)

        var realParts = [Float](filteredData) + Array(repeating: 0, count: fftSize - filteredData.count)  // Zero-padding
        var imagParts = [Float](repeating: 0, count: fftSize)
        var outputMagnitudes = [Float](repeating: 0, count: fftSize / 2)

        let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))!

        realParts.withUnsafeMutableBufferPointer { realPtr in
            imagParts.withUnsafeMutableBufferPointer { imagPtr in
                var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)

                vDSP_fft_zip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
                vDSP_zvmags(&splitComplex, 1, &outputMagnitudes, 1, vDSP_Length(fftSize / 2))

                var normalizedMagnitudes = [Float](repeating: 0, count: fftSize / 2)
                vDSP_vsmul(outputMagnitudes, 1, [2.0 / Float(fftSize)], &normalizedMagnitudes, 1, vDSP_Length(fftSize / 2))

                vDSP_destroy_fftsetup(fftSetup)
            }
        }

        return processFrequencyBands(outputMagnitudes)
    }

    /// ✅ Notch Filter (Removes 60 Hz Power Line Noise)
    private static func applyNotchFilter(_ data: [Float], notchFrequency: Float, samplingRate: Float) -> [Float] {
        let Q: Float = 30.0  // Controls filter sharpness (higher = narrower notch)
        let omega = 2.0 * .pi * notchFrequency / samplingRate
        let alpha = sin(omega) / (2.0 * Q)

        let a0 = 1 + alpha
        let a1 = -2 * cos(omega)
        let a2 = 1 - alpha
        let b0 = 1
        let b1 = -2 * cos(omega)
        let b2 = 1

        var filteredData = data
        var x1: Float = 0, x2: Float = 0, y1: Float = 0, y2: Float = 0

        for i in 0..<data.count {
            let x0 = data[i]

            let term1 = (Float(b0) / a0) * x0
            let term2 = (b1 / a0) * x1
            let term3 = (Float(b2) / a0) * x2
            let term4 = (a1 / a0) * y1
            let term5 = (a2 / a0) * y2

            let y0 = term1 + term2 + term3 - term4 - term5

            filteredData[i] = y0

            // Shift values for next iteration
            x2 = x1
            x1 = x0
            y2 = y1
            y1 = y0
        }

        return filteredData
    }

    /// ✅ High-Pass Filter (Removes Motion Artifacts < 1 Hz)
    private static func applyHighPassFilter(_ data: [Float], cutoffFrequency: Float, samplingRate: Float) -> [Float] {
        let RC = 1.0 / (2.0 * .pi * cutoffFrequency)
        let dt = 1.0 / samplingRate
        let alpha = dt / (RC + dt)

        var filteredData = [Float](repeating: 0, count: data.count)
        filteredData[0] = data[0]  // Initialize first value

        for i in 1..<data.count {
            filteredData[i] = alpha * (filteredData[i - 1] + data[i] - data[i - 1])
        }

        return filteredData
    }

    private static func processFrequencyBands(_ magnitudes: [Float]) -> [String: Float] {
        let samplingRate: Float = 250.0
        let frequencyResolution = samplingRate / Float(magnitudes.count * 2)

        var bands: [String: Float] = ["Delta": 0, "Theta": 0, "Alpha": 0, "Beta": 0, "Gamma": 0]

        for (index, magnitude) in magnitudes.enumerated() {
            let frequency = Float(index) * frequencyResolution

            if frequency >= 0.5 && frequency < 4 { bands["Delta"]! += magnitude }
            else if frequency >= 4 && frequency < 8 { bands["Theta"]! += magnitude }
            else if frequency >= 8 && frequency < 12 { bands["Alpha"]! += magnitude }
            else if frequency >= 12 && frequency < 30 { bands["Beta"]! += magnitude }
            else if frequency >= 30 && frequency < 100 { bands["Gamma"]! += magnitude }
        }

        return bands
    }
}

