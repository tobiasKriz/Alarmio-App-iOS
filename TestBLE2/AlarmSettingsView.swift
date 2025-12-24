// AlarmSettingsView.swift
// TestBLE2
//
// Created on 19.10.2025.
//

import SwiftUI

struct AlarmSettingsView: View {
    @EnvironmentObject var bleManager: BLEManager
    @Environment(\.dismiss) var dismiss
    @State private var tempAlarmTime = Date()
    @State private var selectedDays: Set<Int> = []
    @State private var alarmName: String = ""
    
    var existingAlarm: BLEManager.LocalAlarm?
    var onSave: ((BLEManager.LocalAlarm) -> Void)?
    
    private let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    init(existingAlarm: BLEManager.LocalAlarm? = nil, onSave: ((BLEManager.LocalAlarm) -> Void)? = nil) {
        self.existingAlarm = existingAlarm
        self.onSave = onSave
        
        // Initialize with existing alarm if provided
        if let alarm = existingAlarm {
            _tempAlarmTime = State(initialValue: alarm.time)
            _alarmName = State(initialValue: alarm.name)
            _selectedDays = State(initialValue: Self.parseRepeatDays(from: alarm.repeatDays))
        }
    }
    
    private static func parseRepeatDays(from repeatDays: BLEManager.RepeatDays) -> Set<Int> {
        var days = Set<Int>()
        if repeatDays.contains(.sunday) { days.insert(0) }
        if repeatDays.contains(.monday) { days.insert(1) }
        if repeatDays.contains(.tuesday) { days.insert(2) }
        if repeatDays.contains(.wednesday) { days.insert(3) }
        if repeatDays.contains(.thursday) { days.insert(4) }
        if repeatDays.contains(.friday) { days.insert(5) }
        if repeatDays.contains(.saturday) { days.insert(6) }
        return days
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: tempAlarmTime)
    }
    
    private var repeatDaysString: String {
        if selectedDays.isEmpty {
            return "Never"
        } else if selectedDays.count == 7 {
            return "Every Day"
        } else if selectedDays.count == 5 && !selectedDays.contains(0) && !selectedDays.contains(6) {
            return "Weekdays"
        } else if selectedDays.count == 2 && selectedDays.contains(0) && selectedDays.contains(6) {
            return "Weekends"
        } else {
            return selectedDays.sorted().map { weekDays[$0] }.joined(separator: ", ")
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Time picker
                    DatePicker(
                        "Alarm Time",
                        selection: $tempAlarmTime,
                        displayedComponents: [.hourAndMinute]
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .padding()
                    
                    // Alarm name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Alarm Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                        
                        TextField("e.g., Morning, Work, Exercise", text: $alarmName)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(white: 0.15))
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 16)
                    
                    // Repeat days section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Repeat")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text(repeatDaysString)
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(white: 0.15))
                        
                        // Day buttons
                        HStack(spacing: 12) {
                            ForEach(0..<7, id: \.self) { index in
                                Button {
                                    if selectedDays.contains(index) {
                                        selectedDays.remove(index)
                                    } else {
                                        selectedDays.insert(index)
                                    }
                                } label: {
                                    Text(weekDays[index])
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(selectedDays.contains(index) ? .black : .white)
                                        .frame(width: 44, height: 44)
                                        .background(selectedDays.contains(index) ? Color.orange : Color(white: 0.15))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle(existingAlarm == nil ? "Add Alarm" : "Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        // Convert selected days to RepeatDays bitmask
                        var repeatDays = BLEManager.RepeatDays(rawValue: 0)
                        if selectedDays.contains(0) { repeatDays.insert(.sunday) }
                        if selectedDays.contains(1) { repeatDays.insert(.monday) }
                        if selectedDays.contains(2) { repeatDays.insert(.tuesday) }
                        if selectedDays.contains(3) { repeatDays.insert(.wednesday) }
                        if selectedDays.contains(4) { repeatDays.insert(.thursday) }
                        if selectedDays.contains(5) { repeatDays.insert(.friday) }
                        if selectedDays.contains(6) { repeatDays.insert(.saturday) }
                        
                        // Create or update the alarm
                        var alarm: BLEManager.LocalAlarm
                        if let existing = existingAlarm {
                            // Editing existing alarm - preserve ID and enabled state
                            alarm = BLEManager.LocalAlarm(
                                id: existing.id,
                                name: alarmName.isEmpty ? "Alarm" : alarmName,
                                time: tempAlarmTime,
                                isEnabled: existing.isEnabled,
                                repeatDays: repeatDays,
                                isScheduledOnESP32: existing.isScheduledOnESP32
                            )
                        } else {
                            // New alarm - disabled by default
                            alarm = BLEManager.LocalAlarm(
                                name: alarmName.isEmpty ? "Alarm" : alarmName,
                                time: tempAlarmTime,
                                isEnabled: false,
                                repeatDays: repeatDays
                            )
                        }
                        
                        onSave?(alarm)
                        dismiss()
                    }
                    .foregroundColor(.orange)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    AlarmSettingsView(onSave: { _ in })
        .environmentObject(BLEManager())
}
