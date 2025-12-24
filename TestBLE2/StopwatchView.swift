//
//  StopwatchView.swift
//  TestBLE2
//
//  Created by Tobias Krizansky on 20.10.2025.
//

import SwiftUI

struct StopwatchView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var showSettings = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var isRunning = false
    @State private var timer: Timer?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Stopwatch Display Circle
                    ZStack {
                        Circle()
                            .stroke(Color(white: 0.2), lineWidth: 8)
                            .frame(width: 280, height: 280)
                        
                        Text(timeString)
                            .font(.system(size: 56, weight: .thin, design: .default))
                            .foregroundColor(.white)
                            .monospacedDigit()
                    }
                    
                    // Control Buttons
                    if !isRunning && elapsedTime == 0 {
                        Button {
                            startStopwatch()
                        } label: {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .stroke(Color(white: 0.3), lineWidth: 2)
                                )
                                .overlay(
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 28, weight: .light))
                                        .foregroundColor(.white)
                                )
                        }
                    } else if isRunning {
                        Button {
                            pauseStopwatch()
                        } label: {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .stroke(Color(white: 0.3), lineWidth: 2)
                                )
                                .overlay(
                                    Image(systemName: "pause.fill")
                                        .font(.system(size: 28, weight: .light))
                                        .foregroundColor(.white)
                                )
                        }
                    } else {
                        HStack(spacing: 40) {
                            Button {
                                resetStopwatch()
                            } label: {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 70, height: 70)
                                    .overlay(
                                        Circle()
                                            .stroke(Color(white: 0.3), lineWidth: 2)
                                    )
                                    .overlay(
                                        Image(systemName: "xmark")
                                            .font(.system(size: 28, weight: .light))
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            Button {
                                startStopwatch()
                            } label: {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 70, height: 70)
                                    .overlay(
                                        Circle()
                                            .stroke(Color(white: 0.3), lineWidth: 2)
                                    )
                                    .overlay(
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 28, weight: .light))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Stopwatch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.gray)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                NotificationCenter.default.addObserver(forName: NSNotification.Name("ResetStopwatch"), object: nil, queue: .main) { _ in
                    elapsedTime = 0
                    isRunning = false
                    timer?.invalidate()
                }
            }
        }
    }
    
    private var timeString: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let milliseconds = Int((elapsedTime.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d : %02d", minutes, seconds)
    }
    
    private func startStopwatch() {
        isRunning = true
        
        // Post notification to reset timer
        NotificationCenter.default.post(name: NSNotification.Name("ResetTimer"), object: nil)
        
        // Send to ESP32
        bleManager.startStopwatch()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            elapsedTime += 0.01
        }
    }
    
    private func pauseStopwatch() {
        isRunning = false
        timer?.invalidate()
        
        // Send to ESP32
        bleManager.pauseStopwatch()
    }
    
    private func resetStopwatch() {
        elapsedTime = 0
        isRunning = false
        timer?.invalidate()
        
        // Send to ESP32
        bleManager.resetStopwatch()
        bleManager.dismissStopwatch()
    }
}

#Preview {
    StopwatchView()
}
