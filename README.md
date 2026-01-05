# Alarmio

A minimalist iOS clock app that connects to an ESP32-powered OLED display via Bluetooth.

## Features

- **Clock Display** - Real-time sync with custom font support
- **Multiple Alarms** - Set up to 5 alarms with repeat schedules and custom ringtones
- **Timer** - Visual countdown with progress ring
- **Stopwatch** - Precise time tracking
- **Custom Fonts** - Paint and upload your own digit designs
- **Ringtones** - 7 classic melodies: Nokia, Super Mario Bros, Imperial March, Keyboard Cat, Für Elise, Never Gonna Give You Up, Zelda Theme
- **Buzzer Control** - Volume adjustment and melody playback
- **Hardware Control** - Physical button on ESP32 to dismiss alarms/timer

## Requirements

- iOS device with Bluetooth
- ESP32 with SH1107 128x128 OLED display
- Piezo buzzer (GPIO 20)
- Push button (GPIO 9)
- Arduino IDE for ESP32 programming

## Setup

1. Upload `arduinoCode` to your ESP32
2. Install the iOS app on your device
3. Connect via Bluetooth in Settings
4. Sync time and date
5. Choose a ringtone and upload to ESP32

## Hardware

- **Display**: SH1107 128x128 OLED (SPI)
- **Button**: GPIO 9 (dismiss alarms/timer)
- **Buzzer**: GPIO 20 (piezo speaker)
- **Board**: ESP32

## App Tabs

- **Clock** - Main time display with alarm indicators
- **Alarms** - Manage your alarms with ringtone selection
- **Timer** - Countdown timer with visual ring and buzzer alert
- **Stopwatch** - Count-up timer
- **World Clock** - Time zones (coming soon)
- **Settings** - Font customization, buzzer control, ringtone upload, BLE connection

## Credits

### Ringtone Melodies
All ringtone melodies are based on arrangements from the [arduino-songs](https://github.com/robsoncouto/arduino-songs) repository by Robson Couto. The melodies include:
- Nokia Ringtone
- Super Mario Bros Theme
- Star Wars Imperial March
- Keyboard Cat
- Für Elise (Beethoven)
- Never Gonna Give You Up (Rick Astley)
- The Legend of Zelda Theme`

### Display Setup
The basic SH1107 OLED display setup and initialization code is based on [transparent_oled_128x128px_sh1107](https://github.com/upiir/transparent_oled_128x128px_sh1107) by upiir.

### AI
**Claude Sonnet 4.5** was used to help build this project

---

Built with SwiftUI and Arduino


nothing possible without lil b the based god
