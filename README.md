# Alarmio

A minimalist iOS clock app that connects to an ESP32-powered OLED display via Bluetooth.

## Features

- **Clock Display** - Real-time sync with custom font support
- **Multiple Alarms** - Set up to 5 alarms with repeat schedules
- **Timer** - Visual countdown with progress ring
- **Stopwatch** - Precise time tracking
- **Custom Fonts** - Paint and upload your own digit designs
- **Hardware Control** - Physical button on ESP32 to dismiss alarms/timer

## Requirements

- iOS device with Bluetooth
- ESP32 with SH1107 128x128 OLED display
- Arduino IDE for ESP32 programming

## Setup

1. Upload `arduinoCode` to your ESP32
2. Install the iOS app on your device
3. Connect via Bluetooth in Settings
4. Sync time and date

## Hardware

- **Display**: SH1107 128x128 OLED (SPI)
- **Button**: GPIO 9 (dismiss alarms/timer)
- **Board**: ESP32

## App Tabs

- **Clock** - Main time display with alarm indicators
- **Alarms** - Manage your alarms
- **Timer** - Countdown timer with visual ring
- **Stopwatch** - Count-up timer
- **World Clock** - Time zones (coming soon)

---

Built with SwiftUI and Arduino
