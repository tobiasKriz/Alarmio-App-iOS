//
//  FontStorage.swift
//  TestBLE2
//
//  Font storage and management
//

import Foundation
import Combine

struct StoredFont: Identifiable, Codable {
    let id: UUID
    let name: String
    let dateAdded: Date
    let dataSize: Int
    
    var fileName: String {
        return "\(id.uuidString).fontdata"
    }
}

class FontStorage: ObservableObject {
    @Published var fonts: [StoredFont] = []
    
    private let fontsKey = "storedFonts"
    private let fontsDirectory: URL
    
    init() {
        // Create fonts directory in Documents
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fontsDirectory = documentsPath.appendingPathComponent("CustomFonts", isDirectory: true)
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: fontsDirectory, withIntermediateDirectories: true)
        
        loadFonts()
    }
    
    func loadFonts() {
        if let data = UserDefaults.standard.data(forKey: fontsKey),
           let decodedFonts = try? JSONDecoder().decode([StoredFont].self, from: data) {
            fonts = decodedFonts.sorted { $0.dateAdded > $1.dateAdded }
        }
    }
    
    func saveFonts() {
        if let data = try? JSONEncoder().encode(fonts) {
            UserDefaults.standard.set(data, forKey: fontsKey)
        }
    }
    
    func saveFont(name: String, fontData: Data) -> StoredFont? {
        let font = StoredFont(
            id: UUID(),
            name: name,
            dateAdded: Date(),
            dataSize: fontData.count
        )
        
        let fileURL = fontsDirectory.appendingPathComponent(font.fileName)
        
        do {
            try fontData.write(to: fileURL)
            fonts.append(font)
            saveFonts()
            print("✅ Saved font '\(name)' (\(fontData.count) bytes)")
            return font
        } catch {
            print("❌ Failed to save font: \(error)")
            return nil
        }
    }
    
    func loadFontData(_ font: StoredFont) -> Data? {
        let fileURL = fontsDirectory.appendingPathComponent(font.fileName)
        return try? Data(contentsOf: fileURL)
    }
    
    func deleteFont(_ font: StoredFont) {
        let fileURL = fontsDirectory.appendingPathComponent(font.fileName)
        try? FileManager.default.removeItem(at: fileURL)
        
        fonts.removeAll { $0.id == font.id }
        saveFonts()
        print("🗑️ Deleted font '\(font.name)'")
    }
    
    func renameFont(_ font: StoredFont, newName: String) {
        if let index = fonts.firstIndex(where: { $0.id == font.id }) {
            fonts[index] = StoredFont(
                id: font.id,
                name: newName,
                dateAdded: font.dateAdded,
                dataSize: font.dataSize
            )
            saveFonts()
        }
    }
}
