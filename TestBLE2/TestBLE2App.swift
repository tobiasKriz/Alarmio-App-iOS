//
//  TestBLE2App.swift
//  TestBLE2
//
//  Created by Tobias Krizansky on 18.10.2025.
//

import SwiftUI

@main
struct TestBLE2App: App {
    // Create a shared instance of BLEManager that will persist through the app lifecycle
    @StateObject private var bleManager = BLEManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(bleManager)
                .onAppear {
                    // Request permission and start scanning when app appears
                    bleManager.startScanning()
                }
        }
    }
}
