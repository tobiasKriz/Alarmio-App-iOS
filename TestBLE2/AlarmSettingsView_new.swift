// AlarmSettingsView.swift
// TestBLE2
//
// Created on 19.10.2025.
//

import SwiftUI

struct AlarmSettingsViewNew: View {
    @EnvironmentObject var bleManager: BLEManager
    @Environment(\.dismiss) private var dismiss
    @State private var tempAlarmTime = Date()
    @State private var isAlarmEnabled = false
    
    private var formattedAlarmTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: bleManager.alarmTime)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Alarm icon
                Image(systemName: "alarm")
                    .font(.system(size: 60))
                    .foregroundColor(isAlarmEnabled ? .red : .primary)
                
                Text("Set Alarm Time")
                    .font(.headline)
                
                // Time picker
                DatePicker(
                    "Alarm Time",
                    selection: $tempAlarmTime,
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                
                // Enable/disable switch
                HStack {
                    Text("Enable Alarm")
                    Spacer()
                    Toggle("", isOn: $isAlarmEnabled)
                        .labelsHidden()
                        .tint(.red)
                }
                .padding(.horizontal)
                
                // Manual state monitoring instead of onChange
                Group {
                    if !isAlarmEnabled && bleManager.isAlarmEnabled {
                        Button("Disable Alarm on Device") {
                            bleManager.disableAlarm()
                        }
                        .hidden() // Hidden button that just creates a proper View structure
                    } else {
                        EmptyView() // Always provide a valid View
                    }
                }
                
                // Current status display
                Group {
                    if bleManager.isAlarmSet {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.red)
                            
                            Text("Current alarm: \(formattedAlarmTime)")
                                 .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    } else {
                        EmptyView()
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 15) {
                    Button(action: {
                        // Set the alarm
                        bleManager.alarmTime = tempAlarmTime
                        bleManager.setAlarm()
                        dismiss()
                    }) {
                        Text("Set Alarm")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    .tint(.blue)
                    .disabled(!isAlarmEnabled)
                    
                    Button(action: {
                        // Dismiss an active alarm
                        bleManager.dismissAlarm()
                        dismiss()
                    }) {
                        Text("Dismiss Alarm")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(BorderedButtonStyle())
                    .tint(.orange)
                    .opacity(bleManager.isAlarmSet ? 1.0 : 0.5)
                    .disabled(!bleManager.isAlarmSet)
                    
                    Button(action: {
                        // Disable the alarm completely
                        bleManager.disableAlarm()
                        isAlarmEnabled = false
                        dismiss()
                    }) {
                        Text("Turn Off Alarm")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(BorderedButtonStyle())
                    .tint(.red)
                    .opacity(bleManager.isAlarmEnabled ? 1.0 : 0.5)
                    .disabled(!bleManager.isAlarmEnabled)
                }
                .padding()
            }
            .navigationBarTitle("Alarm Settings", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .onAppear {
                // Load current values from BLEManager
                tempAlarmTime = bleManager.alarmTime
                isAlarmEnabled = bleManager.isAlarmEnabled
                
                // Watch for changes to isAlarmEnabled
                if !isAlarmEnabled && bleManager.isAlarmEnabled {
                    bleManager.disableAlarm()
                }
            }
        }
    }
}

struct AlarmSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AlarmSettingsViewNew()
            .environmentObject(BLEManager())
    }
}
