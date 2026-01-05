//
//  SettingsView.swift
//  TestBLE2
//
//  Created by Tobias Krizansky on 20.10.2025.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var bleManager: BLEManager
    @Environment(\.dismiss) var dismiss
    @StateObject var fontStorage = FontStorage()
    @State private var automaticHomeClock = false
    @State private var showTimeZonePicker = false
    @State private var showFontPainter = false
    @State private var showFontImporter = false
    @State private var showSizeSelector = false
    @State private var selectedFontSize: Double = 40
    @State private var selectedFontURL: URL?
    @State private var showRenameAlert = false
    @State private var fontToRename: StoredFont?
    @State private var newFontName = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Automatic Home Clock Setting
                        VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Automatic Time Sync")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Toggle("", isOn: $bleManager.automaticTimeSync)
                                .labelsHidden()
                                .tint(.green)
                        }
                        
                        Text("Automatically sync time with ESP32 when connected.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(white: 0.15))
                    
                    Divider()
                        .background(Color(white: 0.3))
                    
                    // Font Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Clock Font Style")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Choose how the time appears on your ESP32 display")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // Default fonts
                                ForEach(0..<2) { fontIndex in
                                    FontPreviewButton(
                                        fontIndex: fontIndex,
                                        isSelected: bleManager.selectedFont == fontIndex
                                    ) {
                                        bleManager.selectedFont = fontIndex
                                    }
                                }
                                
                                // Saved custom fonts
                                ForEach(fontStorage.fonts) { font in
                                    SavedFontButton(
                                        font: font,
                                        isSelected: false,
                                        onSelect: {
                                            loadAndSendFont(font)
                                        },
                                        onRename: {
                                            fontToRename = font
                                            newFontName = font.name
                                            showRenameAlert = true
                                        },
                                        onDelete: {
                                            fontStorage.deleteFont(font)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Upload TTF Font Button
                        Button {
                            showFontImporter = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.badge.arrow.up")
                                Text("Upload TTF Font")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.6, green: 0.2, blue: 0.1), Color(red: 0.8, green: 0.3, blue: 0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Paint Custom Font Button
                        Button {
                            showFontPainter = true
                        } label: {
                            HStack {
                                Image(systemName: "paintbrush.fill")
                                Text("Paint Your Own Font")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.7, green: 0.25, blue: 0.1), Color(red: 0.9, green: 0.35, blue: 0.15)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 16)
                    .background(Color(white: 0.15))
                    
                    Divider()
                        .background(Color(white: 0.3))
                    
                    // Buzzer Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Buzzer Settings")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        
                        // Buzzer enable/disable
                        HStack {
                            Text("Enable Buzzer")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Toggle("", isOn: $bleManager.buzzerEnabled)
                                .labelsHidden()
                                .tint(.green)
                        }
                        
                        if bleManager.buzzerEnabled {
                            // Volume slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Volume")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Spacer()
                                    
                                    Text("\(Int(bleManager.buzzerVolume))%")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 50, alignment: .trailing)
                                }
                                
                                Slider(value: $bleManager.buzzerVolume, in: 0...100, step: 10)
                                    .tint(.blue)
                            }
                            .padding(.top, 8)
                            
                            // Test buzzer button
                            Button {
                                bleManager.testBuzzer()
                            } label: {
                                HStack {
                                    Image(systemName: "speaker.wave.2")
                                    Text("Test Buzzer")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.7), Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                            .padding(.top, 8)
                        }
                        
                        Text(bleManager.buzzerEnabled ? "Buzzer will sound for alarms and timer." : "Buzzer is disabled. Only visual alerts will show.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(white: 0.15))
                    
                    Divider()
                        .background(Color(white: 0.3))
                    
                    // Ringtone Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ringtone")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Select a ringtone for alarms and timer")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                        
                        // Ringtone picker
                        Picker("Ringtone", selection: $bleManager.selectedRingtone) {
                            ForEach(RingtoneLibrary.shared.ringtones, id: \.name) { ringtone in
                                Text(ringtone.name).tag(ringtone.name)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.blue)
                        
                        // Upload button
                        Button {
                            bleManager.uploadRingtone(bleManager.selectedRingtone)
                        } label: {
                            HStack {
                                if bleManager.ringtoneUploading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.up.circle")
                                }
                                
                                Text(bleManager.ringtoneUploading ? "Sending..." : "Send to ESP32")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: bleManager.ringtoneUploading ? 
                                        [Color.gray.opacity(0.7), Color.gray] :
                                        [Color.green.opacity(0.7), Color.green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .disabled(bleManager.ringtoneUploading || !bleManager.isConnected)
                        
                        // Upload progress
                        if bleManager.ringtoneUploading {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Progress:")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    Spacer()
                                    
                                    Text("\(Int(bleManager.ringtoneUploadProgress * 100))%")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                
                                ProgressView(value: bleManager.ringtoneUploadProgress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            }
                            .padding(.top, 8)
                        }
                        
                        Text("Ringtone will play when alarm or timer triggers.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(white: 0.15))
                    
                    Divider()
                        .background(Color(white: 0.3))
                    
                    // BLE Connection Status
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BLE Connection")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        
                        HStack {
                            Image(systemName: bleManager.isConnected ? "bluetooth.connected" : "bluetooth.slash")
                                .foregroundColor(bleManager.isConnected ? .blue : .gray)
                            
                            Text(bleManager.statusMessage)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                            
                            if bleManager.isConnected {
                                Button("Disconnect") {
                                    bleManager.disconnect()
                                }
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                            } else {
                                Button("Scan") {
                                    bleManager.startScanning()
                                }
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(white: 0.15))
                    
                    Spacer()
                }
                .padding(.top, 20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17, weight: .regular))
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showFontPainter) {
                FontPainterView()
                    .environmentObject(bleManager)
            }
            .alert("Rename Font", isPresented: $showRenameAlert) {
                TextField("Font Name", text: $newFontName)
                Button("Cancel", role: .cancel) { }
                Button("Rename") {
                    if let font = fontToRename, !newFontName.isEmpty {
                        fontStorage.renameFont(font, newName: newFontName)
                    }
                }
            } message: {
                Text("Enter a new name for this font")
            }
            .fileImporter(
                isPresented: $showFontImporter,
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { result in
                handleFontFileSelection(result)
            }
            .sheet(isPresented: $showSizeSelector) {
                if let fontURL = selectedFontURL {
                    FontSizeSelector(selectedSize: $selectedFontSize) { size in
                        selectedFontSize = size
                        showSizeSelector = false
                        convertAndSendCustomTTF(fontURL: fontURL, size: size)
                    }
                }
            }
        }
    }
    
    private func handleFontFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let fontURL = urls.first else { return }
            
            // Store the font URL and show size selector
            selectedFontURL = fontURL
            showSizeSelector = true
            
        case .failure(let error):
            print("❌ Font file selection failed: \(error.localizedDescription)")
        }
    }
    
    private func convertAndSendCustomTTF(fontURL: URL, size: Double) {
        guard fontURL.startAccessingSecurityScopedResource() else {
            print("❌ Could not access font file")
            return
        }
        
        defer { fontURL.stopAccessingSecurityScopedResource() }
        
        print("📂 Loading font from: \(fontURL.lastPathComponent)")
        print("📏 Using size: \(Int(size))pt")
        
        if let fontData = FontConverter.convertTTFFileToBitmap(
            fontURL: fontURL,
            fontSize: CGFloat(size)
        ) {
            // Save font to storage
            let fontName = fontURL.deletingPathExtension().lastPathComponent
            let savedName = "\(fontName) (\(Int(size))pt)"
            if fontStorage.saveFont(name: savedName, fontData: fontData) != nil {
                print("✅ Font saved as '\(savedName)'")
            }
            
            print("✅ Font converted successfully, sending to ESP32...")
            bleManager.sendCustomFont(fontData) { success in
                if success {
                    print("✅ Font sent successfully!")
                    // Auto-select font #1 (Painted)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        bleManager.selectedFont = 1
                    }
                } else {
                    print("❌ Failed to send font")
                }
            }
        } else {
            print("❌ Font conversion failed")
        }
    }
    
    private func loadAndSendFont(_ font: StoredFont) {
        guard let fontData = fontStorage.loadFontData(font) else {
            print("❌ Failed to load font data")
            return
        }
        
        print("📤 Sending saved font: \(font.name)")
        bleManager.sendCustomFont(fontData) { success in
            if success {
                print("✅ Font sent successfully!")
                // Auto-select font #1 (Painted)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    bleManager.selectedFont = 1
                }
            } else {
                print("❌ Failed to send font")
            }
        }
    }
}

struct FontPreviewButton: View {
    let fontIndex: Int
    let isSelected: Bool
    let action: () -> Void
    
    private let fontNames = [
        "Inline",
        "Painted"
    ]
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("12:34")
                    .font(.system(size: isSelected ? 20 : 18, weight: .medium, design: .monospaced))
                    .foregroundColor(isSelected ? .black : .white)
                
                Text(fontNames[fontIndex])
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .black : .white.opacity(0.7))
            }
            .frame(width: 85, height: 75)
            .background(isSelected ? Color.orange : Color(white: 0.2))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct SavedFontButton: View {
    let font: StoredFont
    let isSelected: Bool
    let onSelect: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Menu {
            Button(action: onSelect) {
                Label("Send to ESP32", systemImage: "arrow.up.circle")
            }
            
            Button(action: onRename) {
                Label("Rename", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "textformat")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .black : .white)
                
                Text(font.name)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 85, height: 75)
            .background(isSelected ? Color.orange : Color(white: 0.2))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(BLEManager())
}
