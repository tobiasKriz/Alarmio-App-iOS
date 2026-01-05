//
//  BLEManager.swift
//  TestBLE2
//
//  Created on 18.10.2025.
//

import Foundation
import CoreBluetooth
import SwiftUI
import Combine

class BLEManager: NSObject, ObservableObject {
    // MARK: - Properties
    private var centralManager: CBCentralManager!
    var peripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    var alarmCharacteristic: CBCharacteristic?  // Added for alarm functionality

    // Discovered devices collection
    @Published var discoveredDevices: [DiscoveredDevice] = []

    // Published properties for SwiftUI to observe
    @Published var isConnected = false
    @Published var isScanning = false
    @Published var statusMessage = "Not connected"
    @Published var blinkCount: Int = 0 // Removed the didSet to prevent automatic sending
    
    // Flag to show when data was last sent
    @Published var lastSentCount: Int = 0
    @Published var lastSentTime: Date?

    // Store the last sent time string
    @Published var lastSentTimeString: String = ""
    @Published var lastSentTimestamp: Date?
    
    // Alarm-related properties
    @Published var alarmTime: Date = Date()
    @Published var isAlarmEnabled: Bool = false
    @Published var isAlarmSet: Bool = false

    // Debug mode for showing all devices
    @Published var debugModeEnabled = false
    
    // Automatic time sync setting
    @Published var automaticTimeSync = true {
        didSet {
            UserDefaults.standard.set(automaticTimeSync, forKey: "automaticTimeSync")
        }
    }
    
    // Font selection
    @Published var selectedFont: Int = 0 {
        didSet {
            UserDefaults.standard.set(selectedFont, forKey: "selectedFont")
            if isConnected {
                sendFontSelection()
            }
        }
    }
    
    // Buzzer settings
    @Published var buzzerEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(buzzerEnabled, forKey: "buzzerEnabled")
            if isConnected {
                sendBuzzerState()
            }
        }
    }
    
    @Published var buzzerVolume: Double = 100 {
        didSet {
            UserDefaults.standard.set(buzzerVolume, forKey: "buzzerVolume")
            if isConnected {
                sendBuzzerVolume()
            }
        }
    }

    // Target device name
    private let targetDeviceName = "ESP32 BLE Clock"  // Updated to match Arduino name

    // Service and characteristic UUIDs
    private let serviceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    private let timeCharacteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    private let alarmCharacteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a9")  // Added for alarm
    private let dateTimeCharacteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26aa")  // Added for date/time
    private let fontCharacteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26ab")  // Added for font
    private let customFontCharacteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26ac")  // Added for custom font data
    private let timerCharacteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26ad")  // Added for timer
    private let stopwatchCharacteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26ae")  // Added for stopwatch
    private let buzzerCharacteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26af")  // Added for buzzer
    private let ringtoneCharacteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26b0")  // Added for ringtone
    
    // Characteristics
    private var dateTimeCharacteristic: CBCharacteristic?
    private var fontCharacteristic: CBCharacteristic?
    private var customFontCharacteristic: CBCharacteristic?
    private var timerCharacteristic: CBCharacteristic?
    private var stopwatchCharacteristic: CBCharacteristic?
    private var buzzerCharacteristic: CBCharacteristic?
    private var ringtoneCharacteristic: CBCharacteristic?
    
    // Ringtone upload state
    @Published var ringtoneUploading = false
    @Published var ringtoneUploadProgress: Double = 0.0
    @Published var selectedRingtone: String = "Nokia" {
        didSet {
            UserDefaults.standard.set(selectedRingtone, forKey: "selectedRingtone")
        }
    }
    
    // Local alarm management
    @Published var localAlarms: [LocalAlarm] = []
    @Published var nextScheduledAlarm: LocalAlarm?

    // Device discovery model
    struct DiscoveredDevice: Identifiable {
        let id: UUID
        let peripheral: CBPeripheral
        let rssi: NSNumber
        let advertisementData: [String: Any]
        let timestamp: Date

        var name: String {
            return peripheral.name ?? "Unknown Device"
        }

        var identifierString: String {
            return peripheral.identifier.uuidString
        }

        var rssiValue: Int {
            return rssi.intValue
        }

        var advertisementDataDescription: String {
            var result = ""

            // Get manufacturer data if available
            if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
                result += "Manufacturer: \(manufacturerData.hexDescription)\n"
            }

            // Get advertised service UUIDs if available
            if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
                result += "Services: \(serviceUUIDs.map { $0.uuidString }.joined(separator: ", "))\n"
            }

            // Get local name if available
            if let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
                result += "Local Name: \(localName)\n"
            }

            return result.isEmpty ? "No advertisement data" : result
        }
    }

    // Local alarm model for scheduling alarms on ESP32
    struct LocalAlarm: Identifiable, Codable {
        var id = UUID()
        var name: String
        var time: Date
        var isEnabled: Bool
        var repeatDays: RepeatDays
        var isScheduledOnESP32: Bool = false
        
        var timeString: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: time)
        }
        
        var repeatString: String {
            if repeatDays.isDaily {
                return "Daily"
            } else if repeatDays.isWeekdays {
                return "Weekdays"
            } else if repeatDays.isWeekends {
                return "Weekends"
            } else if repeatDays.rawValue == 0 {
                return "Once"
            } else {
                var days: [String] = []
                if repeatDays.contains(.sunday) { days.append("Sun") }
                if repeatDays.contains(.monday) { days.append("Mon") }
                if repeatDays.contains(.tuesday) { days.append("Tue") }
                if repeatDays.contains(.wednesday) { days.append("Wed") }
                if repeatDays.contains(.thursday) { days.append("Thu") }
                if repeatDays.contains(.friday) { days.append("Fri") }
                if repeatDays.contains(.saturday) { days.append("Sat") }
                return days.joined(separator: ", ")
            }
        }
    }
    
    // Repeat days bitmask for alarms
    struct RepeatDays: OptionSet, Codable {
        let rawValue: Int
        
        static let sunday    = RepeatDays(rawValue: 1 << 0)
        static let monday    = RepeatDays(rawValue: 1 << 1)
        static let tuesday   = RepeatDays(rawValue: 1 << 2)
        static let wednesday = RepeatDays(rawValue: 1 << 3)
        static let thursday  = RepeatDays(rawValue: 1 << 4)
        static let friday    = RepeatDays(rawValue: 1 << 5)
        static let saturday  = RepeatDays(rawValue: 1 << 6)
        
        static let weekdays: RepeatDays = [.monday, .tuesday, .wednesday, .thursday, .friday]
        static let weekends: RepeatDays = [.saturday, .sunday]
        static let daily: RepeatDays = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        
        var isDaily: Bool { self == .daily }
        var isWeekdays: Bool { self == .weekdays }
        var isWeekends: Bool { self == .weekends }
    }

    // MARK: - Initialization
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // Load saved automaticTimeSync setting
        automaticTimeSync = UserDefaults.standard.object(forKey: "automaticTimeSync") as? Bool ?? true
        
        // Load saved font selection
        selectedFont = UserDefaults.standard.object(forKey: "selectedFont") as? Int ?? 0
        
        // Load saved buzzer settings
        buzzerEnabled = UserDefaults.standard.object(forKey: "buzzerEnabled") as? Bool ?? true
        buzzerVolume = UserDefaults.standard.object(forKey: "buzzerVolume") as? Double ?? 100
        
        // Load saved local alarms
        loadLocalAlarms()
    }

    // MARK: - Public Methods
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            statusMessage = "Bluetooth is not available"
            return
        }

        isScanning = true
        statusMessage = "Scanning for \(targetDeviceName)..."
        // Start scanning with no service filter to find all devices
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }

    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        statusMessage = "Scanning stopped"
    }

    func disconnect() {
        if let peripheral = peripheral, peripheral.state != .disconnected {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    // Connect to a specific peripheral
    func connectToDevice(_ targetPeripheral: CBPeripheral) {
        if let currentPeripheral = peripheral, currentPeripheral.identifier == targetPeripheral.identifier {
            // Already connected or connecting to this device
            return
        }
        
        // Disconnect from current peripheral if needed
        if isConnected {
            disconnect()
        }
        
        // Set the new target peripheral and connect
        peripheral = targetPeripheral
        centralManager.connect(targetPeripheral, options: nil)
        statusMessage = "Connecting to \(targetPeripheral.name ?? "device")..."
    }
    
    // Send blink count to the connected device
    func sendBlinks() {
        // Update the last sent values
        lastSentCount = blinkCount
        lastSentTime = Date()
        
        // Send the current blink count
        sendBlinkCount(blinkCount)
    }
    
    // Send current time to the connected device
    func sendCurrentTime(autoSync: Bool = false) {
        guard isConnected, let peripheral = peripheral, let characteristic = writeCharacteristic else {
            statusMessage = "Not connected or characteristic not found"
            return
        }
        
        // Format the current time as HH:MM:SS
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timeString = formatter.string(from: now)
        
        // Store the sent time information
        lastSentTimeString = timeString
        lastSentTimestamp = now
        
        // Send the time string to the device
        if let data = timeString.data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            
            // Different status message for auto sync vs manual sync
            if autoSync {
                statusMessage = "Auto-synced time: \(timeString)"
                print("Automatic time sync completed: \(timeString)")
            } else {
                statusMessage = "Sent current time: \(timeString)"
                print("Manual time sync completed: \(timeString)")
            }
        }
    }
    
    // Set the alarm on the connected device
    func setAlarm() {
        guard isConnected, let peripheral = peripheral, let characteristic = alarmCharacteristic else {
            statusMessage = "Not connected or alarm characteristic not found"
            return
        }
        
        // Format the alarm time as SET:HH:MM:SS
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let alarmTimeString = "SET:" + formatter.string(from: alarmTime)
        
        // Send the alarm time string to the device
        if let data = alarmTimeString.data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            statusMessage = "Alarm set for: \(formatter.string(from: alarmTime))"
            isAlarmSet = true
            isAlarmEnabled = true
        }
    }
    
    // Turn off the alarm on the connected device (disables ALL alarms)
    func disableAlarm() {
        guard isConnected, let peripheral = peripheral, let characteristic = alarmCharacteristic else {
            statusMessage = "Not connected or alarm characteristic not found"
            return
        }
        
        // Send the OFF command to disable the alarm
        if let data = "OFF".data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            statusMessage = "Alarm disabled"
            isAlarmEnabled = false
            isAlarmSet = false
        }
    }
    
    // Dismiss triggered alarms on the connected device
    func dismissTriggeredAlarms() {
        guard isConnected, let peripheral = peripheral, let characteristic = alarmCharacteristic else {
            statusMessage = "Not connected or alarm characteristic not found"
            return
        }
        
        // Send the DISMISS command to stop triggered alarms
        if let data = "DISMISS".data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            statusMessage = "Alarms dismissed"
            print("✅ Sent DISMISS command - stopped triggered alarms")
        }
    }
    
    // Clear all alarms from ESP32
    func clearAllAlarms() {
        guard isConnected, let peripheral = peripheral, let characteristic = alarmCharacteristic else {
            statusMessage = "Not connected or alarm characteristic not found"
            return
        }
        
        // Send the CLEAR command to remove all alarms
        if let data = "CLEAR".data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            statusMessage = "All alarms cleared from ESP32"
            print("✅ Sent CLEAR command - all alarms removed")
        }
    }
    
    // Dismiss a triggered alarm on the connected device
    func dismissAlarm() {
        guard isConnected, let peripheral = peripheral, let characteristic = alarmCharacteristic else {
            statusMessage = "Not connected or alarm characteristic not found"
            return
        }
        
        // Send the DISMISS command to stop a triggered alarm
        if let data = "DISMISS".data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            statusMessage = "Alarm dismissed"
        }
    }
    
    // MARK: - Enhanced Alarm Functions
    
    // Set alarm for a specific time (hour, minute, second)
    func setAlarm(hour: Int, minute: Int, second: Int = 0) {
        // Create a Date object for today with the specified time
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = second
        
        if let alarmDate = calendar.date(from: components) {
            alarmTime = alarmDate
            setAlarm()
        }
    }
    
    // Quick test alarm function - sets alarm for 10 seconds from now
    func setTestAlarm() {
        let calendar = Calendar.current
        let futureTime = calendar.date(byAdding: .second, value: 10, to: Date()) ?? Date()
        alarmTime = futureTime
        setAlarm()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        statusMessage = "Test alarm set for 10 seconds: \(formatter.string(from: futureTime))"
    }
    
    // Get formatted alarm time string
    func getFormattedAlarmTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: alarmTime)
    }
    
    // Check if alarm time has passed (for UI purposes)
    func isAlarmInPast() -> Bool {
        return alarmTime < Date()
    }

    // MARK: - Local Alarm Management
    
    func loadLocalAlarms() {
        if let data = UserDefaults.standard.data(forKey: "localAlarms"),
           let alarms = try? JSONDecoder().decode([LocalAlarm].self, from: data) {
            localAlarms = alarms
            updateNextScheduledAlarm()
        }
    }
    
    func saveLocalAlarms() {
        if let data = try? JSONEncoder().encode(localAlarms) {
            UserDefaults.standard.set(data, forKey: "localAlarms")
        }
    }
    
    func addLocalAlarm(_ alarm: LocalAlarm) {
        localAlarms.append(alarm)
        saveLocalAlarms()
        updateNextScheduledAlarm()
        
        // If connected to ESP32, schedule the alarm there too
        if isConnected && alarm.isEnabled {
            scheduleAlarmOnESP32(alarm)
        }
    }
    
    func updateLocalAlarm(_ alarm: LocalAlarm) {
        if let index = localAlarms.firstIndex(where: { $0.id == alarm.id }) {
            localAlarms[index] = alarm
            saveLocalAlarms()
            updateNextScheduledAlarm()
            
            // Update on ESP32 if connected
            if isConnected {
                scheduleAllAlarmsOnESP32()
            }
        }
    }
    
    func deleteLocalAlarm(_ alarm: LocalAlarm) {
        localAlarms.removeAll { $0.id == alarm.id }
        saveLocalAlarms()
        updateNextScheduledAlarm()
        
        // Refresh ESP32 alarms
        if isConnected {
            scheduleAllAlarmsOnESP32()
        }
    }
    
    func toggleLocalAlarm(_ alarm: LocalAlarm) {
        if let index = localAlarms.firstIndex(where: { $0.id == alarm.id }) {
            localAlarms[index].isEnabled.toggle()
            saveLocalAlarms()
            updateNextScheduledAlarm()
            
            // Update ESP32
            if isConnected {
                scheduleAllAlarmsOnESP32()
            }
        }
    }
    
    func updateNextScheduledAlarm() {
        let enabledAlarms = localAlarms.filter { $0.isEnabled }
        
        // Find the next alarm to trigger
        let now = Date()
        var nextAlarm: LocalAlarm?
        var shortestTimeUntil: TimeInterval = .greatestFiniteMagnitude
        
        for alarm in enabledAlarms {
            if let timeUntil = alarm.nextTriggerTime(from: now) {
                if timeUntil < shortestTimeUntil {
                    shortestTimeUntil = timeUntil
                    nextAlarm = alarm
                }
            }
        }
        
        nextScheduledAlarm = nextAlarm
    }
    
    func scheduleAllAlarmsOnESP32() {
        guard isConnected, let peripheral = peripheral, let characteristic = alarmCharacteristic else {
            print("❌ Cannot schedule alarms: Not connected")
            return
        }
        
        // First clear all alarms on ESP32
        if let data = "CLEAR".data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("✅ Cleared all alarms on ESP32")
        }
        
        // Schedule each enabled alarm
        let enabledAlarms = localAlarms.filter { $0.isEnabled }
        for (index, alarm) in enabledAlarms.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                self.scheduleAlarmOnESP32(alarm)
            }
        }
    }
    
    func scheduleAlarmOnESP32(_ alarm: LocalAlarm) {
        guard isConnected, let peripheral = peripheral, let characteristic = alarmCharacteristic else {
            return
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: alarm.time)
        
        // Format: ADD:HH:MM:SS:RepeatDays:Name
        let alarmCommand = String(format: "ADD:%02d:%02d:%02d:%d:%@",
                                 components.hour ?? 0,
                                 components.minute ?? 0,
                                 components.second ?? 0,
                                 alarm.repeatDays.rawValue,
                                 alarm.name.replacingOccurrences(of: ":", with: ""))
        
        if let data = alarmCommand.data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("✅ Scheduled alarm on ESP32: \(alarmCommand)")
        }
    }
    
    // MARK: - Timer Methods
    
    func setTimer(hours: Int, minutes: Int, seconds: Int) {
        guard isConnected, let peripheral = peripheral, let characteristic = timerCharacteristic else {
            statusMessage = "Not connected or timer characteristic not found"
            return
        }
        
        let command = String(format: "SET:%02d:%02d:%02d", hours, minutes, seconds)
        if let data = command.data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("✅ Timer set: \(command)")
        }
    }
    
    func startTimer() {
        guard isConnected, let peripheral = peripheral, let characteristic = timerCharacteristic else {
            statusMessage = "Not connected or timer characteristic not found"
            return
        }
        
        if let data = "START".data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("✅ Timer started")
        }
    }
    
    func pauseTimer() {
        guard isConnected, let peripheral = peripheral, let characteristic = timerCharacteristic else {
            statusMessage = "Not connected or timer characteristic not found"
            return
        }
        
        if let data = "PAUSE".data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("✅ Timer paused")
        }
    }
    
    func resetTimer() {
        guard isConnected, let peripheral = peripheral, let characteristic = timerCharacteristic else {
            statusMessage = "Not connected or timer characteristic not found"
            return
        }
        
        if let data = "RESET".data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("✅ Timer reset")
        }
    }
    
    func dismissTimer() {
        guard isConnected, let peripheral = peripheral, let characteristic = timerCharacteristic else {
            statusMessage = "Not connected or timer characteristic not found"
            return
        }
        
        if let data = "DISMISS".data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("✅ Timer dismissed")
        }
    }
    
    // MARK: - Stopwatch Methods
    
    func startStopwatch() {
        guard isConnected, let peripheral = peripheral, let characteristic = stopwatchCharacteristic else {
            statusMessage = "Not connected or stopwatch characteristic not found"
            return
        }
        
        if let data = "START".data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("✅ Stopwatch started")
        }
    }
    
    func pauseStopwatch() {
        guard isConnected, let peripheral = peripheral, let characteristic = stopwatchCharacteristic else {
            statusMessage = "Not connected or stopwatch characteristic not found"
            return
        }
        
        if let data = "PAUSE".data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("✅ Stopwatch paused")
        }
    }
    
    func resetStopwatch() {
        guard isConnected, let peripheral = peripheral, let characteristic = stopwatchCharacteristic else {
            statusMessage = "Not connected or stopwatch characteristic not found"
            return
        }
        
        if let data = "RESET".data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("✅ Stopwatch reset")
        }
    }
    
    func dismissStopwatch() {
        guard isConnected, let peripheral = peripheral, let characteristic = stopwatchCharacteristic else {
            statusMessage = "Not connected or stopwatch characteristic not found"
            return
        }
        
        if let data = "DISMISS".data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("✅ Stopwatch dismissed")
        }
    }
    
    // MARK: - Buzzer Methods
    
    func sendBuzzerState() {
        guard isConnected, let peripheral = peripheral, let characteristic = buzzerCharacteristic else {
            statusMessage = "Not connected or buzzer characteristic not found"
            return
        }
        
        let command = buzzerEnabled ? "ON" : "OFF"
        if let data = command.data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("✅ Buzzer \(command)")
        }
    }
    
    func sendBuzzerVolume() {
        guard isConnected, let peripheral = peripheral, let characteristic = buzzerCharacteristic else {
            statusMessage = "Not connected or buzzer characteristic not found"
            return
        }
        
        let command = "VOLUME:\(Int(buzzerVolume))"
        if let data = command.data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("✅ Buzzer volume set to \(Int(buzzerVolume))%")
        }
    }
    
    func testBuzzer() {
        guard isConnected, let peripheral = peripheral, let characteristic = buzzerCharacteristic else {
            statusMessage = "Not connected or buzzer characteristic not found"
            return
        }
        
        if let data = "TEST".data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("✅ Buzzer test")
        }
    }
    
    // MARK: - Ringtone Upload
    func uploadRingtone(_ ringtoneName: String) {
        guard isConnected, let peripheral = peripheral, let characteristic = ringtoneCharacteristic else {
            statusMessage = "Not connected or ringtone characteristic not found"
            return
        }
        
        // Find the ringtone by name
        guard let ringtone = RingtoneLibrary.shared.ringtones.first(where: { $0.name == ringtoneName }) else {
            print("❌ Ringtone not found: \(ringtoneName)")
            return
        }
        
        // Convert ringtone to binary data
        let melodyData = ringtone.toData()
        let totalBytes = melodyData.count
        let chunkSize = 180  // BLE safe chunk size (leave room for protocol overhead)
        let totalChunks = (totalBytes + chunkSize - 1) / chunkSize
        
        print("📤 Starting ringtone upload: \(ringtoneName)")
        print("   Total bytes: \(totalBytes), Chunks: \(totalChunks)")
        
        ringtoneUploading = true
        ringtoneUploadProgress = 0.0
        
        // Send START command
        let startCommand = "START:\(totalBytes):\(totalChunks)"
        if let data = startCommand.data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("✅ Sent START: \(startCommand)")
        }
        
        // Send chunks with delay
        var chunkIndex = 0
        var bytesSent = 0
        
        func sendNextChunk() {
            guard chunkIndex < totalChunks else {
                // All chunks sent, send END command
                if let endData = "END".data(using: .ascii) {
                    peripheral.writeValue(endData, for: characteristic, type: .withResponse)
                    print("✅ Sent END command")
                }
                
                DispatchQueue.main.async {
                    self.ringtoneUploading = false
                    self.ringtoneUploadProgress = 1.0
                    self.statusMessage = "Ringtone uploaded: \(ringtoneName)"
                }
                return
            }
            
            let start = bytesSent
            let end = min(start + chunkSize, totalBytes)
            let chunkData = melodyData.subdata(in: start..<end)
            let hexString = chunkData.map { String(format: "%02x", $0) }.joined()
            
            let chunkCommand = "CHUNK:\(chunkIndex):\(hexString)"
            if let data = chunkCommand.data(using: .ascii) {
                peripheral.writeValue(data, for: characteristic, type: .withResponse)
                print("✅ Sent chunk \(chunkIndex + 1)/\(totalChunks) (\(chunkData.count) bytes)")
            }
            
            bytesSent = end
            chunkIndex += 1
            
            DispatchQueue.main.async {
                self.ringtoneUploadProgress = Double(chunkIndex) / Double(totalChunks)
            }
            
            // Schedule next chunk
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                sendNextChunk()
            }
        }
        
        // Start sending chunks after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            sendNextChunk()
        }
    }
}

// MARK: - Hex Data Extension
extension Data {
    var hexDescription: String {
        return self.map { String(format: "%02hhx", $0) }.joined()
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            // Bluetooth is on, start scanning automatically
            startScanning()
        case .poweredOff:
            statusMessage = "Bluetooth is turned off"
            isConnected = false
        case .resetting:
            statusMessage = "Bluetooth is resetting"
            isConnected = false
        case .unauthorized:
            statusMessage = "Bluetooth is unauthorized"
        case .unsupported:
            statusMessage = "Bluetooth is not supported"
        case .unknown:
            statusMessage = "Bluetooth state unknown"
        @unknown default:
            statusMessage = "Unknown Bluetooth state"
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Add discovered device to the list regardless of name
        let existingDeviceIndex = discoveredDevices.firstIndex {
            $0.peripheral.identifier == peripheral.identifier
        }
        
        let device = DiscoveredDevice(
            id: UUID(),
            peripheral: peripheral,
            rssi: RSSI,
            advertisementData: advertisementData,
            timestamp: Date()
        )
        
        // Update existing entry or add new one
        if let index = existingDeviceIndex {
            discoveredDevices[index] = device
        } else {
            discoveredDevices.append(device)
        }
        
        // Process target device as before
        if let peripheralName = peripheral.name, peripheralName == targetDeviceName {
            self.peripheral = peripheral
            if !debugModeEnabled {
                stopScanning()
            }
            statusMessage = "Found \(peripheralName), connecting..."
            centralManager.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        statusMessage = "Connected to \(peripheral.name ?? "unknown device")"
        isConnected = true

        // Set peripheral delegate to receive callbacks
        peripheral.delegate = self

        // Discover services
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        statusMessage = "Failed to connect: \(error?.localizedDescription ?? "unknown error")"
        isConnected = false
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        statusMessage = "Disconnected from device"
        isConnected = false

        // Try to reconnect
        if error != nil {
            statusMessage = "Disconnected with error: \(error!.localizedDescription). Reconnecting..."
            central.connect(peripheral, options: nil)
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            statusMessage = "Error discovering services: \(error.localizedDescription)"
            return
        }

        guard let services = peripheral.services else { return }

        for service in services {
            // Discover characteristics for each service
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            statusMessage = "Error discovering characteristics: \(error.localizedDescription)"
            return
        }

        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            // Looking for our specific characteristics
            if characteristic.uuid == timeCharacteristicUUID {
                writeCharacteristic = characteristic
                print("✅ Found time characteristic: \(characteristic.uuid)")
            } else if characteristic.uuid == alarmCharacteristicUUID {
                alarmCharacteristic = characteristic
                print("✅ Found alarm characteristic: \(characteristic.uuid)")
            } else if characteristic.uuid == dateTimeCharacteristicUUID {
                dateTimeCharacteristic = characteristic
                print("✅ Found date/time characteristic: \(characteristic.uuid)")
            } else if characteristic.uuid == fontCharacteristicUUID {
                fontCharacteristic = characteristic
                print("✅ Found font characteristic: \(characteristic.uuid)")
            } else if characteristic.uuid == customFontCharacteristicUUID {
                customFontCharacteristic = characteristic
                print("✅ Found custom font characteristic: \(characteristic.uuid)")
            } else if characteristic.uuid == timerCharacteristicUUID {
                timerCharacteristic = characteristic
                print("✅ Found timer characteristic: \(characteristic.uuid)")
            } else if characteristic.uuid == stopwatchCharacteristicUUID {
                stopwatchCharacteristic = characteristic
                print("✅ Found stopwatch characteristic: \(characteristic.uuid)")
            } else if characteristic.uuid == buzzerCharacteristicUUID {
                buzzerCharacteristic = characteristic
                print("✅ Found buzzer characteristic: \(characteristic.uuid)")
            } else if characteristic.uuid == ringtoneCharacteristicUUID {
                ringtoneCharacteristic = characteristic
                print("✅ Found ringtone characteristic: \(characteristic.uuid)")
            } else {
                print("ℹ️ Found unknown characteristic: \(characteristic.uuid)")
            }

            // Subscribe to notifications if the characteristic supports it
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        
        // If we've found all characteristics, update the status and auto-sync
        if writeCharacteristic != nil && alarmCharacteristic != nil && dateTimeCharacteristic != nil && fontCharacteristic != nil {
            statusMessage = "All features ready"
            
            print("BLEManager: All characteristics found. automaticTimeSync = \(automaticTimeSync)")
            
            // Automatically send current date/time if enabled
            if automaticTimeSync {
                print("BLEManager: Scheduling automatic date/time sync in 0.5 seconds")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("BLEManager: Executing automatic date/time sync")
                    self.sendDateAndTime(autoSync: true)
                }
            } else {
                print("BLEManager: Automatic time sync is disabled")
            }
            
            // Send current font selection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                self.sendFontSelection()
            }
            
            // Send buzzer settings
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                self.sendBuzzerState()
                self.sendBuzzerVolume()
            }
            
            // Auto-sync all alarms to ESP32
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("BLEManager: Auto-syncing alarms to ESP32")
                self.scheduleAllAlarmsOnESP32()
            }
        } else {
            print("⚠️ Missing characteristics - time:\(writeCharacteristic != nil) alarm:\(alarmCharacteristic != nil) dateTime:\(dateTimeCharacteristic != nil) font:\(fontCharacteristic != nil)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            statusMessage = "Error writing value: \(error.localizedDescription)"
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            statusMessage = "Error receiving data: \(error.localizedDescription)"
            return
        }

        // Handle incoming data if needed
        if let data = characteristic.value, let string = String(data: data, encoding: .ascii) {
            statusMessage = "Received: \(string)"
        }
    }
}

// MARK: - Private Methods
extension BLEManager {
    private func sendBlinkCount(_ count: Int) {
        guard isConnected, let peripheral = peripheral, let characteristic = writeCharacteristic else {
            return
        }

        // Convert the blink count to an ASCII string then to Data
        let countString = String(count)
        if let data = countString.data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            statusMessage = "Sent: \(count) blinks"
        }
    }
    
    // Send current date and time to the connected device
    func sendDateAndTime(autoSync: Bool = false) {
        guard isConnected, let peripheral = peripheral, let characteristic = dateTimeCharacteristic else {
            statusMessage = "Not connected or date/time characteristic not found"
            print("❌ SendDateAndTime failed: Not connected or characteristic missing")
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .weekday], from: now)
        
        // Format: YYYY-MM-DD:HH:MM:SS:DayOfWeek (0=Sunday, 1=Monday, ..., 6=Saturday)
        let dayOfWeek = (components.weekday ?? 1) - 1  // Convert from 1-7 to 0-6
        let dateTimeString = String(format: "%04d-%02d-%02d:%02d:%02d:%02d:%d",
                                   components.year ?? 2025,
                                   components.month ?? 1,
                                   components.day ?? 1,
                                   components.hour ?? 0,
                                   components.minute ?? 0,
                                   components.second ?? 0,
                                   dayOfWeek)
        
        if let data = dateTimeString.data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd, yyyy HH:mm:ss"
            let formattedDateTime = formatter.string(from: now)
            
            if autoSync {
                statusMessage = "Auto-synced date/time: \(formattedDateTime)"
                print("✅ Automatic date/time sync completed: \(dateTimeString)")
            } else {
                statusMessage = "Sent date/time: \(formattedDateTime)"
                print("✅ Manual date/time sync completed: \(dateTimeString)")
            }
        } else {
            print("❌ Failed to encode date/time command: \(dateTimeString)")
        }
    }
    
    // Send font selection to the connected device
    func sendFontSelection() {
        guard isConnected, let peripheral = peripheral, let characteristic = fontCharacteristic else {
            print("❌ SendFontSelection failed: Not connected or characteristic missing")
            return
        }
        
        let fontString = String(selectedFont)
        if let data = fontString.data(using: .ascii) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            statusMessage = "Font changed to style \(selectedFont)"
            print("✅ Font selection sent: \(selectedFont)")
        } else {
            print("❌ Failed to encode font selection: \(selectedFont)")
        }
    }
    
    // Send custom font data to ESP32 with chunking
    func sendCustomFont(_ fontData: Data, completion: @escaping (Bool) -> Void) {
        guard let peripheral = peripheral,
              let characteristic = customFontCharacteristic else {
            print("❌ Cannot send custom font: Not connected or characteristic not found")
            completion(false)
            return
        }
        
        // BLE has a ~512 byte limit per write, so chunk the data
        let chunkSize = 400  // Use 400 to be safe
        let totalChunks = (fontData.count + chunkSize - 1) / chunkSize
        
        print("📤 Sending custom font: \(fontData.count) bytes in \(totalChunks) chunks")
        
        // Send header: "START:totalBytes:totalChunks"
        let header = "START:\(fontData.count):\(totalChunks)".data(using: .utf8)!
        peripheral.writeValue(header, for: characteristic, type: .withResponse)
        
        // Wait for ESP32 to process header
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.sendFontChunk(fontData, chunk: 0, total: totalChunks, chunkSize: chunkSize, characteristic: characteristic, peripheral: peripheral, completion: completion)
        }
    }
    
    private func sendFontChunk(_ data: Data, chunk: Int, total: Int, chunkSize: Int, characteristic: CBCharacteristic, peripheral: CBPeripheral, completion: @escaping (Bool) -> Void) {
        let start = chunk * chunkSize
        let end = min(start + chunkSize, data.count)
        let chunkData = data.subdata(in: start..<end)
        
        // Send chunk with index: "CHUNK:index:data"
        var packetData = "CHUNK:\(chunk):".data(using: .utf8)!
        packetData.append(chunkData)
        
        peripheral.writeValue(packetData, for: characteristic, type: .withResponse)
        print("📦 Sent chunk \(chunk + 1)/\(total) (\(chunkData.count) bytes)")
        
        if chunk + 1 < total {
            // Send next chunk after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.sendFontChunk(data, chunk: chunk + 1, total: total, chunkSize: chunkSize, characteristic: characteristic, peripheral: peripheral, completion: completion)
            }
        } else {
            // All chunks sent, send END command
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let endData = "END".data(using: .utf8)!
                peripheral.writeValue(endData, for: characteristic, type: .withResponse)
                print("✅ Custom font transfer complete")
                self.statusMessage = "Custom font uploaded successfully"
                completion(true)
            }
        }
    }
}

// MARK: - LocalAlarm Extensions
extension BLEManager.LocalAlarm {
    func nextTriggerTime(from date: Date) -> TimeInterval? {
        let calendar = Calendar.current
        let now = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .weekday], from: date)
        let alarmComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        
        guard let alarmHour = alarmComponents.hour,
              let alarmMinute = alarmComponents.minute,
              let alarmSecond = alarmComponents.second else {
            return nil
        }
        
        // If this is a one-time alarm (no repeat days)
        if repeatDays.rawValue == 0 {
            var triggerComponents = now
            triggerComponents.hour = alarmHour
            triggerComponents.minute = alarmMinute
            triggerComponents.second = alarmSecond
            
            if let triggerTime = calendar.date(from: triggerComponents) {
                if triggerTime > date {
                    return triggerTime.timeIntervalSince(date)
                }
            }
            return nil // One-time alarm in the past
        }
        
        // For repeating alarms, find the next occurrence
        let currentWeekday = (now.weekday ?? 1) - 1 // Convert to 0-6
        let currentTimeSeconds = (now.hour ?? 0) * 3600 + (now.minute ?? 0) * 60 + (now.second ?? 0)
        let alarmTimeSeconds = alarmHour * 3600 + alarmMinute * 60 + alarmSecond
        
        // Check today first
        if repeatDays.rawValue & (1 << currentWeekday) != 0 {
            if alarmTimeSeconds > currentTimeSeconds {
                return TimeInterval(alarmTimeSeconds - currentTimeSeconds)
            }
        }
        
        // Check the next 7 days
        for dayOffset in 1...7 {
            let checkDay = (currentWeekday + dayOffset) % 7
            if repeatDays.rawValue & (1 << checkDay) != 0 {
                let secondsUntilDay = dayOffset * 24 * 3600 - currentTimeSeconds + alarmTimeSeconds
                return TimeInterval(secondsUntilDay)
            }
        }
        
        return nil
    }
}
