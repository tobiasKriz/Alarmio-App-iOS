//
//  FontConverter.swift
//  TestBLE2
//
//  Converts TTF fonts to XBM bitmap format for ESP32
//

import UIKit
import CoreText
import CoreGraphics

class FontConverter {
    static func convertTTFFileToBitmap(fontURL: URL, fontSize: CGFloat = 40) -> Data? {
        var fontBytes: [UInt8] = []
        
        // U8g2 font format header (simplified)
        fontBytes.append(contentsOf: [10, 0, 4, 5, 5, 5, 6, 6, 1, 19, 19, 48, 57, 0, 40, 1])
        
        let digitWidth = 24
        let digitHeight = 40
        
        // Load the custom font from file
        guard let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
              let cgFont = CGFont(fontDataProvider),
              let fontName = cgFont.postScriptName as String? else {
            print("❌ Could not load font from file: \(fontURL.lastPathComponent)")
            return nil
        }
        
        // Register the font temporarily (ignore error if already registered)
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(cgFont, &error) {
            if let error = error?.takeRetainedValue() {
                let errorDesc = CFErrorCopyDescription(error) as String
                // Ignore "already registered" errors
                if !errorDesc.contains("already") {
                    print("❌ Font registration failed: \(errorDesc)")
                    return nil
                }
            }
        }
        
        defer {
            // Unregister font after use
            CTFontManagerUnregisterGraphicsFont(cgFont, nil)
        }
        
        guard let font = UIFont(name: fontName, size: fontSize) else {
            print("❌ Could not create UIFont from: \(fontName)")
            return nil
        }
        
        print("✅ Converting font: \(fontName) at size \(fontSize)pt")
        print("📂 Source: \(fontURL.lastPathComponent)")
        
        // Convert each digit 0-9 to bitmap
        for digit in 0...9 {
            let digitString = "\(digit)"
            let bitmap = renderCharacterToBitmap(
                character: digitString,
                font: font,
                width: digitWidth,
                height: digitHeight
            )
            
            // Pack bitmap into bytes (XBM format: LSB-first)
            let bytesPerRow = (digitWidth + 7) / 8
            for row in 0..<digitHeight {
                for byteIndex in 0..<bytesPerRow {
                    var byte: UInt8 = 0
                    for bit in 0..<8 {
                        let x = byteIndex * 8 + bit
                        if x < digitWidth && bitmap[row][x] {
                            byte |= (1 << bit)  // LSB-first for XBM format
                        }
                    }
                    fontBytes.append(byte)
                }
            }
        }
        
        print("✅ Generated font data: \(fontBytes.count) bytes")
        print("📊 First 32 bytes: \(fontBytes.prefix(32).map { String(format: "%02X", $0) }.joined(separator: " "))")
        
        return Data(fontBytes)
    }
    
    static func convertTTFToBitmap(fontName: String, fontSize: CGFloat = 40) -> Data? {
        var fontBytes: [UInt8] = []
        
        // U8g2 font format header (simplified)
        fontBytes.append(contentsOf: [10, 0, 4, 5, 5, 5, 6, 6, 1, 19, 19, 48, 57, 0, 40, 1])
        
        let digitWidth = 24
        let digitHeight = 40
        
        // Try to load the custom font
        guard let font = UIFont(name: fontName, size: fontSize) else {
            print("❌ Font '\(fontName)' not found. Using system font.")
            return nil
        }
        
        print("✅ Converting font: \(fontName) at size \(fontSize)")
        
        // Convert each digit 0-9 to bitmap
        for digit in 0...9 {
            let digitString = "\(digit)"
            let bitmap = renderCharacterToBitmap(
                character: digitString,
                font: font,
                width: digitWidth,
                height: digitHeight
            )
            
            // Pack bitmap into bytes (XBM format: LSB-first)
            let bytesPerRow = (digitWidth + 7) / 8
            for row in 0..<digitHeight {
                for byteIndex in 0..<bytesPerRow {
                    var byte: UInt8 = 0
                    for bit in 0..<8 {
                        let x = byteIndex * 8 + bit
                        if x < digitWidth && bitmap[row][x] {
                            byte |= (1 << bit)  // LSB-first for XBM format
                        }
                    }
                    fontBytes.append(byte)
                }
            }
        }
        
        print("✅ Generated font data: \(fontBytes.count) bytes")
        print("📊 First 32 bytes: \(fontBytes.prefix(32).map { String(format: "%02X", $0) }.joined(separator: " "))")
        
        return Data(fontBytes)
    }
    
    private static func renderCharacterToBitmap(character: String, font: UIFont, width: Int, height: Int) -> [[Bool]] {
        // Create bitmap array
        var bitmap = Array(repeating: Array(repeating: false, count: width), count: height)
        
        // Use UIGraphicsImageRenderer for reliable rendering
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Fill white background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Draw black text
            UIColor.black.setFill()
            
            // Calculate text size and position for centering
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black
            ]
            let textSize = (character as NSString).size(withAttributes: attributes)
            let x = (CGFloat(width) - textSize.width) / 2
            let y = (CGFloat(height) - textSize.height) / 2
            
            // Draw the character
            let textRect = CGRect(x: x, y: y, width: textSize.width, height: textSize.height)
            (character as NSString).draw(in: textRect, withAttributes: attributes)
        }
        
        // Convert image to bitmap
        guard let cgImage = image.cgImage else {
            print("❌ Failed to get CGImage")
            return bitmap
        }
        
        // Create a grayscale context to read pixel values
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bytesPerRow = width
        var pixelData = [UInt8](repeating: 0, count: width * height)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            print("❌ Failed to create read context")
            return bitmap
        }
        
        // Draw the image into our grayscale context
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Convert to boolean bitmap (threshold at 128)
        for y in 0..<height {
            for x in 0..<width {
                let pixelValue = pixelData[y * width + x]
                bitmap[y][x] = pixelValue < 128  // Black pixels (< 128) are true
            }
        }
        
        return bitmap
    }
    
    // Helper to list all available fonts
    static func listAvailableFonts() {
        print("📋 Available fonts:")
        for family in UIFont.familyNames.sorted() {
            let fonts = UIFont.fontNames(forFamilyName: family)
            print("  \(family): \(fonts.joined(separator: ", "))")
        }
    }
}
