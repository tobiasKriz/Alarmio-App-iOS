//
//  AlarmView.swift
//  TestBLE2
//
//  Created by Tobias Krizansky on 20.10.2025.
//

import SwiftUI
import Combine

struct AlarmView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var showSettings = false
    @State private var showAddAlarm = false
    @State private var editingAlarm: BLEManager.LocalAlarm?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(bleManager.localAlarms) { alarm in
                            AlarmRowView(alarm: alarm, bleManager: bleManager)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingAlarm = alarm
                                }
                                .contextMenu {
                                    Button {
                                        editingAlarm = alarm
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        bleManager.deleteLocalAlarm(alarm)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        bleManager.deleteLocalAlarm(alarm)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button {
                                        editingAlarm = alarm
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                        
                        // Add Alarm Button
                        Button {
                            showAddAlarm = true
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(white: 0.15))
                                    .frame(height: 80)
                                
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "plus")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Alarm")
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
                    .environmentObject(bleManager)
            }
            .sheet(item: $editingAlarm) { alarm in
                AlarmSettingsView(existingAlarm: alarm) { updatedAlarm in
                    bleManager.updateLocalAlarm(updatedAlarm)
                }
                .environmentObject(bleManager)
            }
            .fullScreenCover(isPresented: $showAddAlarm) {
                AlarmSettingsView { newAlarm in
                    bleManager.addLocalAlarm(newAlarm)
                }
                .environmentObject(bleManager)
            }
        }
    }
}

struct AlarmRowView: View {
    let alarm: BLEManager.LocalAlarm
    var bleManager: BLEManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.timeString)
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    if !alarm.name.isEmpty {
                        Text(alarm.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                        Text("·")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Text(alarm.repeatString)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in
                    bleManager.toggleLocalAlarm(alarm)
                }
            ))
                .labelsHidden()
                .tint(.green)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(white: 0.15))
        .cornerRadius(12)
    }
}

#Preview {
    AlarmView()
        .environmentObject(BLEManager())
}
