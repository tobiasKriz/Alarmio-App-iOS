//
//  ContentView.swift
//  TestBLE2
//
//  Created by Tobias Krizansky on 18.10.2025.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var sliderValue: Double = 0
    @State private var showDebugView = false
    @State private var currentTime = Date()
    @State private var timer: Timer?
    @State private var showAlarmSettings = false
    
    private var formattedAlarmTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: bleManager.alarmTime)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Connection status indicator
                HStack {
                    Image(systemName: bleManager.isConnected ? "bluetooth.connected" : "bluetooth.slash")
                        .font(.system(size: 25))
                        .foregroundColor(bleManager.isConnected ? .blue : .red)
                    
                    VStack(alignment: .leading) {
                        Text(bleManager.statusMessage)
                            .foregroundColor(bleManager.isConnected ? .blue : .red)
                            .multilineTextAlignment(.leading)
                        
                        // Show auto-sync status
                        if bleManager.automaticTimeSync && bleManager.isConnected {
                            Text("Auto-sync: ON")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // LED blink control section
                VStack(spacing: 30) {
                    if bleManager.isConnected {
                        // Clock icon
                        Image(systemName: "clock.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                            .symbolEffect(.pulse)
                        
                        // Current time display
                        Text(timeString(from: currentTime))
                            .font(.system(size: 48, design: .monospaced))
                            .bold()
                            .padding()
                        
                        // Controls
                        VStack(spacing: 16) {
                            // Send time button
                            Button {
                                bleManager.sendCurrentTime()
                            } label: {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                    Text("Send Current Time")
                                }
                                .frame(minWidth: 200)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 10)
                            
                            // Last sent info
                            if !bleManager.lastSentTimeString.isEmpty {
                                VStack(spacing: 2) {
                                    Text("Last sent: \(bleManager.lastSentTimeString)")
                                        .font(.callout)
                                    
                                    if let timestamp = bleManager.lastSentTimestamp {
                                        Text(timestamp, style: .relative)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.top, 4)
                            }
                            
                            Divider()
                                .padding(.vertical)
                            
                            // Alarm Button
                            Button {
                                showAlarmSettings = true
                            } label: {
                                HStack {
                                    Image(systemName: bleManager.isAlarmSet ? "alarm.fill" : "alarm")
                                        .foregroundColor(bleManager.isAlarmSet ? .red : .primary)
                                    Text("Alarm Settings")
                                }
                                .frame(minWidth: 200)
                            }
                            .buttonStyle(.bordered)
                            
                            // Alarm status (if set)
                            Group {
                                if bleManager.isAlarmSet {
                                    HStack {
                                        Image(systemName: "bell.fill")
                                            .foregroundColor(.red)
                                        
                                        Text("Alarm set for: \(formattedAlarmTime)")
                                            .font(.callout)
                                            .foregroundColor(.red)
                                    }
                                    .padding(.top, 4)
                                } else {
                                    EmptyView()
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    } else {
                        // Not connected state
                        Text("Waiting for connection...")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        if bleManager.isScanning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                        } else {
                            Button("Scan for ESP32") {
                                bleManager.startScanning()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // Debug button
                Button {
                    showDebugView = true
                } label: {
                    Label("Show Nearby Devices", systemImage: "list.bullet.rectangle")
                }
                .buttonStyle(.bordered)
                .padding(.bottom)
            }
            .navigationTitle("ESP32 BLE Controller")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(bleManager.isConnected ? "Disconnect" : "Scan") {
                        if bleManager.isConnected {
                            bleManager.disconnect()
                        } else {
                            bleManager.startScanning()
                        }
                    }
                }
            }
            .sheet(isPresented: $showDebugView) {
                BLEDebugView()
                    .environmentObject(bleManager)
            }
            .fullScreenCover(isPresented: $showAlarmSettings) {
                AlarmSettingsView()
                    .environmentObject(bleManager)
            }
        }
        .onAppear {
            // Start a timer to update the current time every second
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                currentTime = Date()
                // Update next scheduled alarm
                bleManager.updateNextScheduledAlarm()
            }
        }
        .onDisappear {
            // Invalidate the timer when the view disappears
            timer?.invalidate()
        }
    }
}

// Helper to format time as HH:MM:SS
extension ContentView {
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
        .environmentObject(BLEManager())
}
