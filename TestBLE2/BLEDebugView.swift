//
//  BLEDebugView.swift
//  TestBLE2
//
//  Created on 18.10.2025.
//

import SwiftUI
import CoreBluetooth

struct BLEDebugView: View {
    @EnvironmentObject var bleManager: BLEManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedDevice: BLEManager.DiscoveredDevice?
    @State private var showDetails = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Scan control
                HStack {
                    Button(bleManager.isScanning ? "Stop Scanning" : "Start Scanning") {
                        if bleManager.isScanning {
                            bleManager.stopScanning()
                        } else {
                            bleManager.startScanning()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                    
                    // Device count
                    Text("\(bleManager.discoveredDevices.count) devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Devices list
                List {
                    ForEach(bleManager.discoveredDevices.sorted(by: { $0.rssiValue > $1.rssiValue })) { device in
                        DeviceRowView(device: device)
                            .onTapGesture {
                                selectedDevice = device
                                showDetails = true
                            }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    // Restart scanning on pull to refresh
                    bleManager.stopScanning()
                    bleManager.discoveredDevices = []
                    bleManager.startScanning()
                }
                .overlay {
                    if bleManager.discoveredDevices.isEmpty {
                        ContentUnavailableView {
                            Label("No Devices Found", systemImage: "antenna.radiowaves.left.and.right.slash")
                        } description: {
                            Text(bleManager.isScanning ? "Scanning for nearby devices..." : "Pull down to scan for devices")
                        }
                    }
                }
            }
            .navigationTitle("BLE Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        bleManager.discoveredDevices = []
                    }
                }
            }
            .sheet(isPresented: $showDetails) {
                if let device = selectedDevice {
                    DeviceDetailView(device: device)
                        .environmentObject(bleManager)
                }
            }
        }
        .onAppear {
            // Enable debug mode when the debug view appears
            bleManager.debugModeEnabled = true
            if !bleManager.isScanning {
                bleManager.startScanning()
            }
        }
        .onDisappear {
            // Disable debug mode when the debug view disappears
            bleManager.debugModeEnabled = false
            
            // If we're not connected, stop scanning
            if !bleManager.isConnected {
                bleManager.stopScanning()
            }
        }
    }
}

// MARK: - Device Row View
struct DeviceRowView: View {
    let device: BLEManager.DiscoveredDevice
    
    var body: some View {
        HStack(spacing: 12) {
            // RSSI indicator
            ZStack {
                Circle()
                    .fill(rssiColor)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "wave.3.right")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            // Device info
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.headline)
                
                Text(device.identifierString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            // Signal strength
            VStack(alignment: .trailing) {
                Text("\(device.rssiValue) dBm")
                    .font(.subheadline)
                    .foregroundColor(rssiColor)
                
                // Time discovered
                Text(timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // RSSI color based on signal strength
    private var rssiColor: Color {
        let value = device.rssiValue
        if value >= -60 {
            return .green
        } else if value >= -80 && value < -60 {
            return .orange
        } else {
            return .red
        }
    }
    
    // Time since discovery
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: device.timestamp, relativeTo: Date())
    }
}

// MARK: - Device Detail View
struct DeviceDetailView: View {
    let device: BLEManager.DiscoveredDevice
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var bleManager: BLEManager
    
    var body: some View {
        NavigationStack {
            List {
                // Basic info section
                Section("Device Information") {
                    InfoRow(label: "Name", value: device.name)
                    InfoRow(label: "Identifier", value: device.identifierString)
                    InfoRow(label: "RSSI", value: "\(device.rssiValue) dBm")
                    InfoRow(label: "Discovered", value: device.timestamp.formatted())
                }
                
                // Advertisement data
                Section("Advertisement Data") {
                    Text(device.advertisementDataDescription)
                        .font(.system(.body, design: .monospaced))
                        .padding(.vertical, 4)
                }
                
                // Connect button
                Section {
                    Button("Connect to Device") {
                        // Use our new connection method
                        bleManager.connectToDevice(device.peripheral)
                        dismiss()
                    }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Device Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

// MARK: - Helper Views
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    BLEDebugView()
        .environmentObject(BLEManager())
}
