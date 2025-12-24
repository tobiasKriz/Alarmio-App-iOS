//
//  FontSizeSelector.swift
//  TestBLE2
//
//  Font size picker for custom font conversion
//

import SwiftUI

struct FontSizeSelector: View {
    @Binding var selectedSize: Double
    @Environment(\.dismiss) var dismiss
    let onConfirm: (Double) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("Select Font Size")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Larger sizes = thicker/bolder digits")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    // Size preview
                    VStack(spacing: 8) {
                        Text("12:34")
                            .font(.system(size: selectedSize, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("\(Int(selectedSize))pt")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.15))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Size slider
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Font Size: \(Int(selectedSize))pt")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                        
                        Slider(value: $selectedSize, in: 20...60, step: 2)
                            .tint(.orange)
                        
                        HStack {
                            Text("20pt")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Spacer()
                            Text("40pt")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Spacer()
                            Text("60pt")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // Quick size presets
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Presets")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            ForEach([30, 35, 40, 45, 50], id: \.self) { size in
                                Button {
                                    selectedSize = Double(size)
                                } label: {
                                    Text("\(size)pt")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Int(selectedSize) == size ? .black : .white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Int(selectedSize) == size ? Color.orange : Color(white: 0.2))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Confirm button
                    Button {
                        onConfirm(selectedSize)
                    } label: {
                        Text("Convert & Send")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                }
                .padding(.top, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
        }
    }
}

#Preview {
    FontSizeSelector(selectedSize: .constant(40)) { _ in }
}
