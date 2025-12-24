//
//  WorldClockView.swift
//  TestBLE2
//
//  Created by Tobias Krizansky on 20.10.2025.
//

import SwiftUI

struct WorldClockView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var currentTime = Date()
    @State private var timer: Timer?
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Analog Clock
                    AnalogClockView(time: currentTime)
                        .frame(width: 280, height: 280)
                        .padding(.top, 20)
                    
                    // Date Display
                    Text(dateString(from: currentTime))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                        .padding(.bottom, 10)
                    
                    // City Time List
                    VStack(spacing: 12) {
                        CityTimeRow(cityName: "Dubai", time: offsetTime(hours: -1, minutes: -5))
                        CityTimeRow(cityName: "Cairo", time: offsetTime(hours: 1, minutes: 15))
                        CityTimeRow(cityName: "Calcutta", time: currentTime, isHome: true)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Clock")
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
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                currentTime = Date()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func offsetTime(hours: Int, minutes: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: currentTime)!
            .addingTimeInterval(TimeInterval(minutes * 60))
    }
}

struct CityTimeRow: View {
    let cityName: String
    let time: Date
    var isHome: Bool = false
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Text(cityName)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white)
                
                if isHome {
                    Image(systemName: "globe")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            Text(timeString(from: time))
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(white: 0.15))
        .cornerRadius(12)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct AnalogClockView: View {
    let time: Date
    
    var body: some View {
        ZStack {
            // Clock background with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.2), Color(white: 0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Hour markers
            ForEach([0, 3, 6, 9], id: \.self) { hour in
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: 12)
                    .offset(y: -120)
                    .rotationEffect(.degrees(Double(hour) * 90))
            }
            
            // Hour hand
            Rectangle()
                .fill(Color.white)
                .frame(width: 6, height: 70)
                .offset(y: -35)
                .rotationEffect(.degrees(hourAngle))
            
            // Minute hand
            Rectangle()
                .fill(Color.white)
                .frame(width: 4, height: 100)
                .offset(y: -50)
                .rotationEffect(.degrees(minuteAngle))
            
            // Second hand
            Rectangle()
                .fill(Color.red)
                .frame(width: 2, height: 110)
                .offset(y: -55)
                .rotationEffect(.degrees(secondAngle))
            
            // Center dot
            Circle()
                .fill(Color.white)
                .frame(width: 12, height: 12)
        }
    }
    
    private var hourAngle: Double {
        let calendar = Calendar.current
        let hour = Double(calendar.component(.hour, from: time) % 12)
        let minute = Double(calendar.component(.minute, from: time))
        return (hour * 30) + (minute * 0.5)
    }
    
    private var minuteAngle: Double {
        let calendar = Calendar.current
        let minute = Double(calendar.component(.minute, from: time))
        return minute * 6
    }
    
    private var secondAngle: Double {
        let calendar = Calendar.current
        let second = Double(calendar.component(.second, from: time))
        return second * 6
    }
}

#Preview {
    WorldClockView()
        .environmentObject(BLEManager())
}
