//
//  SavedFontsView.swift
//  TestBLE2
//
//  Manage saved custom fonts
//

import SwiftUI

struct SavedFontsView: View {
    @EnvironmentObject var bleManager: BLEManager
    @StateObject var fontStorage = FontStorage()
    @Environment(\.dismiss) var dismiss
    @State private var editingFont: StoredFont?
    @State private var newName: String = ""
    @State private var showRenameAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if fontStorage.fonts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tray")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Saved Fonts")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Upload or paint fonts to save them")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(fontStorage.fonts) { font in
                            FontRow(font: font) {
                                loadAndSendFont(font)
                            } onRename: {
                                editingFont = font
                                newName = font.name
                                showRenameAlert = true
                            } onDelete: {
                                fontStorage.deleteFont(font)
                            }
                        }
                        .listRowBackground(Color(white: 0.15))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Saved Fonts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
            .alert("Rename Font", isPresented: $showRenameAlert) {
                TextField("Font Name", text: $newName)
                Button("Cancel", role: .cancel) {}
                Button("Rename") {
                    if let font = editingFont {
                        fontStorage.renameFont(font, newName: newName)
                    }
                }
            }
        }
    }
    
    private func loadAndSendFont(_ font: StoredFont) {
        guard let fontData = fontStorage.loadFontData(font) else {
            print("❌ Failed to load font data")
            return
        }
        
        print("📤 Sending saved font '\(font.name)' to ESP32...")
        bleManager.sendCustomFont(fontData) { success in
            if success {
                print("✅ Font sent successfully!")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    bleManager.selectedFont = 1
                    dismiss()
                }
            }
        }
    }
}

struct FontRow: View {
    let font: StoredFont
    let onLoad: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "textformat")
                .font(.system(size: 24))
                .foregroundColor(.orange)
                .frame(width: 40, height: 40)
                .background(Color(white: 0.2))
                .cornerRadius(8)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(font.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text(formatDate(font.dateAdded))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text("•")
                        .foregroundColor(.gray)
                    
                    Text(formatSize(font.dataSize))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Actions
            Menu {
                Button {
                    onLoad()
                } label: {
                    Label("Send to ESP32", systemImage: "arrow.up.circle")
                }
                
                Button {
                    onRename()
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatSize(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else {
            return "\(bytes / 1024) KB"
        }
    }
}

#Preview {
    SavedFontsView()
        .environmentObject(BLEManager())
}
