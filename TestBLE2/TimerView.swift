//
//  TimerView.swift
//  TestBLE2
//
//  Created by Tobias Krizansky on 20.10.2025.
//

import SwiftUI

struct TimerView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var showSettings = false
    @State private var showTimerPicker = false
    @State private var timerSeconds: Int = 0
    @State private var isRunning = false
    @State private var timer: Timer?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Timer Display Circle
                    ZStack {
                        Circle()
                            .stroke(Color(white: 0.2), lineWidth: 8)
                            .frame(width: 280, height: 280)
                        
                        Text(timeString)
                            .font(.system(size: 56, weight: .thin, design: .default))
                            .foregroundColor(.white)
                            .monospacedDigit()
                    }
                    
                    // Control Button
                    if !isRunning && timerSeconds == 0 {
                        Button {
                            showTimerPicker = true
                        } label: {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .stroke(Color(white: 0.3), lineWidth: 2)
                                )
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.system(size: 32, weight: .light))
                                        .foregroundColor(.white)
                                )
                        }
                    } else if isRunning {
                        Button {
                            pauseTimer()
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
                                resetTimer()
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
                                startTimer()
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
            .navigationTitle("Timer")
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
            .sheet(isPresented: $showTimerPicker) {
                TimerPickerView(timerSeconds: $timerSeconds)
            }
            .onAppear {
                NotificationCenter.default.addObserver(forName: NSNotification.Name("ResetTimer"), object: nil, queue: .main) { _ in
                    timerSeconds = 0
                    isRunning = false
                    timer?.invalidate()
                }
            }
        }
    }
    
    private var timeString: String {
        let minutes = timerSeconds / 60
        let seconds = timerSeconds % 60
        return String(format: "%02d : %02d", minutes, seconds)
    }
    
    private func startTimer() {
        isRunning = true
        
        // Post notification to reset stopwatch
        NotificationCenter.default.post(name: NSNotification.Name("ResetStopwatch"), object: nil)
        
        // Send to ESP32
        let hours = timerSeconds / 3600
        let minutes = (timerSeconds % 3600) / 60
        let seconds = timerSeconds % 60
        bleManager.setTimer(hours: hours, minutes: minutes, seconds: seconds)
        bleManager.startTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timerSeconds > 0 {
                timerSeconds -= 1
            } else {
                pauseTimer()
            }
        }
    }
    
    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        
        // Send to ESP32
        bleManager.pauseTimer()
    }
    
    private func resetTimer() {
        timerSeconds = 0
        isRunning = false
        timer?.invalidate()
        
        // Send to ESP32
        bleManager.resetTimer()
        bleManager.dismissTimer()
    }
}

struct TimerPickerView: View {
    @Binding var timerSeconds: Int
    @Environment(\.dismiss) var dismiss
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    HStack(spacing: 20) {
                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)")
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                        
                        Text(":")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        
                        Picker("Seconds", selection: $seconds) {
                            ForEach(0..<60) { second in
                                Text("\(second)")
                                    .tag(second)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                    }
                }
            }
            .navigationTitle("Set Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Set") {
                        timerSeconds = (minutes * 60) + seconds
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TimerView()
}
