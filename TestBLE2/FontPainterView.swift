//
//  FontPainterView.swift
//  TestBLE2
//
//  Custom font drawing interface
//

import SwiftUI

struct FontPainterView: View {
    @EnvironmentObject var bleManager: BLEManager
    @Environment(\.dismiss) var dismiss
    @StateObject var fontStorage = FontStorage()
    @State private var currentDigit = 0
    @State private var drawings: [Int: [CGPoint]] = [:]
    @State private var currentPath: [CGPoint] = []
    @State private var showingPreview = false
    @State private var isSending = false
    
    private let digits = Array(0...9)
    private let canvasSize: CGFloat = 280
    private let gridSize = 24 // 24x40 pixels for each digit
    private let gridHeight = 40
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Digit selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(digits, id: \.self) { digit in
                                Button {
                                    saveCurrentDrawing()
                                    currentDigit = digit
                                    currentPath = []
                                } label: {
                                    Text("\(digit)")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(currentDigit == digit ? .black : .white)
                                        .frame(width: 44, height: 44)
                                        .background(currentDigit == digit ? Color.orange : Color(white: 0.2))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(drawings[digit] != nil ? Color.green : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Drawing canvas
                    ZStack {
                        // Grid background
                        Canvas { context, size in
                            let cellWidth = size.width / CGFloat(gridSize)
                            let cellHeight = size.height / CGFloat(gridHeight)
                            
                            context.stroke(
                                Path { path in
                                    for i in 0...gridSize {
                                        let x = cellWidth * CGFloat(i)
                                        path.move(to: CGPoint(x: x, y: 0))
                                        path.addLine(to: CGPoint(x: x, y: size.height))
                                    }
                                    for i in 0...gridHeight {
                                        let y = cellHeight * CGFloat(i)
                                        path.move(to: CGPoint(x: 0, y: y))
                                        path.addLine(to: CGPoint(x: size.width, y: y))
                                    }
                                },
                                with: .color(.gray.opacity(0.2)),
                                lineWidth: 0.5
                            )
                        }
                        .frame(width: canvasSize, height: canvasSize * CGFloat(gridHeight) / CGFloat(gridSize))
                        
                        // Drawing layer
                        Canvas { context, size in
                            // Draw saved drawing for this digit
                            if let savedPath = drawings[currentDigit], !savedPath.isEmpty {
                                var bezierPath = Path()
                                bezierPath.move(to: savedPath[0])
                                for point in savedPath.dropFirst() {
                                    bezierPath.addLine(to: point)
                                }
                                context.stroke(bezierPath, with: .color(.white), lineWidth: 3)
                            }
                            
                            // Draw current stroke on top
                            if !currentPath.isEmpty {
                                var bezierPath = Path()
                                bezierPath.move(to: currentPath[0])
                                for point in currentPath.dropFirst() {
                                    bezierPath.addLine(to: point)
                                }
                                context.stroke(bezierPath, with: .color(.white), lineWidth: 3)
                            }
                        }
                        .frame(width: canvasSize, height: canvasSize * CGFloat(gridHeight) / CGFloat(gridSize))
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    currentPath.append(value.location)
                                }
                                .onEnded { _ in
                                    saveCurrentDrawing()
                                    currentPath = []  // Reset path so next touch starts fresh
                                }
                        )
                    }
                    .background(Color(white: 0.1))
                    .cornerRadius(12)
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button {
                            currentPath = []
                            drawings[currentDigit] = nil
                        } label: {
                            Text("Clear")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Button {
                            showingPreview = true
                        } label: {
                            Text("Preview")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(drawings.isEmpty)
                        
                        Button {
                            sendCustomFont()
                        } label: {
                            if isSending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                Text("Save & Send")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .disabled(drawings.count < 10 || isSending)
                    }
                    .padding(.horizontal)
                    
                    Text(drawings.count < 10 ? "Draw all 10 digits to enable saving" : "Ready to save & send!")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Paint Your Font")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
            .sheet(isPresented: $showingPreview) {
                FontPreviewView(drawings: drawings, gridSize: gridSize, gridHeight: gridHeight, canvasSize: canvasSize)
            }
        }
    }
    
    private func saveCurrentDrawing() {
        if !currentPath.isEmpty {
            if var existingPath = drawings[currentDigit] {
                existingPath.append(contentsOf: currentPath)
                drawings[currentDigit] = existingPath
            } else {
                drawings[currentDigit] = currentPath
            }
        }
    }
    
    private func sendCustomFont() {
        guard drawings.count == 10 else { return }
        
        isSending = true
        
        // Convert drawings to bitmap font data
        let fontData = convertDrawingsToBitmap()
        
        // Save font to storage with auto-generated name
        let fontName = "Painted \(Date().formatted(date: .abbreviated, time: .shortened))"
        if fontStorage.saveFont(name: fontName, fontData: fontData) != nil {
            print("✅ Font saved as '\(fontName)'")
        }
        
        // Send to ESP32 via BLE
        bleManager.sendCustomFont(fontData) { success in
            isSending = false
            if success {
                dismiss()
            }
        }
    }
    
    private func convertDrawingsToBitmap() -> Data {
        var fontBytes: [UInt8] = []
        
        // U8g2 font format header (simplified)
        fontBytes.append(contentsOf: [10, 0, 4, 5, 5, 5, 6, 6, 1, 19, 19, 48, 57, 0, 40, 1])
        
        let cellWidth = canvasSize / CGFloat(gridSize)
        let cellHeight = (canvasSize * CGFloat(gridHeight) / CGFloat(gridSize)) / CGFloat(gridHeight)
        
        // For each digit 0-9
        for digit in 0...9 {
            // Create empty bitmap
            var bitmap = Array(repeating: Array(repeating: false, count: gridSize), count: gridHeight)
            
            if let points = drawings[digit], !points.isEmpty {
                // Fill bitmap with drawn pixels (with thickness for better visibility)
                for point in points {
                    let centerX = Int(point.x / cellWidth)
                    let centerY = Int(point.y / cellHeight)
                    
                    // Draw with 2-pixel thickness
                    for dy in -1...1 {
                        for dx in -1...1 {
                            let x = centerX + dx
                            let y = centerY + dy
                            if x >= 0 && x < gridSize && y >= 0 && y < gridHeight {
                                bitmap[y][x] = true
                            }
                        }
                    }
                }
            }
            
            // Pack bitmap into bytes (XBM format: LSB-first, 8 pixels per byte, row by row)
            let bytesPerRow = (gridSize + 7) / 8
            for row in 0..<gridHeight {
                for byteIndex in 0..<bytesPerRow {
                    var byte: UInt8 = 0
                    for bit in 0..<8 {
                        let x = byteIndex * 8 + bit
                        if x < gridSize && bitmap[row][x] {
                            byte |= (1 << bit)  // LSB-first for XBM format
                        }
                    }
                    fontBytes.append(byte)
                }
            }
        }
        
        print("📝 Generated font data: \(fontBytes.count) bytes")
        print("First 32 bytes: \(fontBytes.prefix(32).map { String(format: "%02X", $0) }.joined(separator: " "))")
        
        return Data(fontBytes)
    }
}

struct FontPreviewView: View {
    let drawings: [Int: [CGPoint]]
    let gridSize: Int
    let gridHeight: Int
    let canvasSize: CGFloat
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("12:34:56")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                            ForEach(0...9, id: \.self) { digit in
                                VStack {
                                    if let points = drawings[digit] {
                                        Canvas { context, size in
                                            var path = Path()
                                            if !points.isEmpty {
                                                path.move(to: CGPoint(
                                                    x: points[0].x * size.width / canvasSize,
                                                    y: points[0].y * size.height / (canvasSize * CGFloat(gridHeight) / CGFloat(gridSize))
                                                ))
                                                for point in points.dropFirst() {
                                                    path.addLine(to: CGPoint(
                                                        x: point.x * size.width / canvasSize,
                                                        y: point.y * size.height / (canvasSize * CGFloat(gridHeight) / CGFloat(gridSize))
                                                    ))
                                                }
                                                context.stroke(path, with: .color(.white), lineWidth: 2)
                                            }
                                        }
                                        .frame(width: 80, height: 120)
                                        .background(Color(white: 0.1))
                                        .cornerRadius(8)
                                    }
                                    Text("\(digit)")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
        }
    }
}

#Preview {
    FontPainterView()
        .environmentObject(BLEManager())
}
