//
//  MainTabView.swift
//  TestBLE2
//
//  Created by Tobias Krizansky on 20.10.2025.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WorldClockView()
                .tabItem {
                    Image(systemName: "globe")
                }
                .tag(0)
            
            AlarmView()
                .tabItem {
                    Image(systemName: "alarm")
                }
                .tag(1)
            
            TimerView()
                .tabItem {
                    Image(systemName: "hourglass")
                }
                .tag(2)
            
            StopwatchView()
                .tabItem {
                    Image(systemName: "stopwatch")
                }
                .tag(3)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
        .environmentObject(BLEManager())
}
