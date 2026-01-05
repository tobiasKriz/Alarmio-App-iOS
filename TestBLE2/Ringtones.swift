import Foundation

// Ringtone data structure
struct Ringtone {
    let name: String
    let tempo: Int
    let notes: [Int16]      // Frequencies in Hz (0 = REST)
    let durations: [Int8]   // Duration values (4=quarter, 8=eighth, negative=dotted)
    
    // Convert to binary data for BLE transfer
    // Format: tempo (2 bytes) + noteCount (2 bytes) + notes array (2 bytes each) + durations array (1 byte each)
    func toData() -> Data {
        var data = Data()
        
        // Add tempo (2 bytes, little endian)
        withUnsafeBytes(of: UInt16(tempo).littleEndian) { data.append(contentsOf: $0) }
        
        // Add note count (2 bytes, little endian)
        withUnsafeBytes(of: UInt16(notes.count).littleEndian) { data.append(contentsOf: $0) }
        
        // Add all notes (2 bytes each, little endian)
        for note in notes {
            withUnsafeBytes(of: note.littleEndian) { data.append(contentsOf: $0) }
        }
        
        // Add all durations (1 byte each)
        for duration in durations {
            data.append(UInt8(bitPattern: duration))
        }
        
        return data
    }
}

// Note definitions (frequencies in Hz)
let NOTE_REST: Int16 = 0
let NOTE_B0: Int16 = 31
let NOTE_C1: Int16 = 33
let NOTE_CS1: Int16 = 35
let NOTE_D1: Int16 = 37
let NOTE_DS1: Int16 = 39
let NOTE_E1: Int16 = 41
let NOTE_F1: Int16 = 44
let NOTE_FS1: Int16 = 46
let NOTE_G1: Int16 = 49
let NOTE_GS1: Int16 = 52
let NOTE_A1: Int16 = 55
let NOTE_AS1: Int16 = 58
let NOTE_B1: Int16 = 62
let NOTE_C2: Int16 = 65
let NOTE_CS2: Int16 = 69
let NOTE_D2: Int16 = 73
let NOTE_DS2: Int16 = 78
let NOTE_E2: Int16 = 82
let NOTE_F2: Int16 = 87
let NOTE_FS2: Int16 = 93
let NOTE_G2: Int16 = 98
let NOTE_GS2: Int16 = 104
let NOTE_A2: Int16 = 110
let NOTE_AS2: Int16 = 117
let NOTE_B2: Int16 = 123
let NOTE_C3: Int16 = 131
let NOTE_CS3: Int16 = 139
let NOTE_D3: Int16 = 147
let NOTE_DS3: Int16 = 156
let NOTE_E3: Int16 = 165
let NOTE_F3: Int16 = 175
let NOTE_FS3: Int16 = 185
let NOTE_G3: Int16 = 196
let NOTE_GS3: Int16 = 208
let NOTE_A3: Int16 = 220
let NOTE_AS3: Int16 = 233
let NOTE_B3: Int16 = 247
let NOTE_C4: Int16 = 262
let NOTE_CS4: Int16 = 277
let NOTE_D4: Int16 = 294
let NOTE_DS4: Int16 = 311
let NOTE_E4: Int16 = 330
let NOTE_F4: Int16 = 349
let NOTE_FS4: Int16 = 370
let NOTE_G4: Int16 = 392
let NOTE_GS4: Int16 = 415
let NOTE_A4: Int16 = 440
let NOTE_AS4: Int16 = 466
let NOTE_B4: Int16 = 494
let NOTE_C5: Int16 = 523
let NOTE_CS5: Int16 = 554
let NOTE_D5: Int16 = 587
let NOTE_DS5: Int16 = 622
let NOTE_E5: Int16 = 659
let NOTE_F5: Int16 = 698
let NOTE_FS5: Int16 = 740
let NOTE_G5: Int16 = 784
let NOTE_GS5: Int16 = 831
let NOTE_A5: Int16 = 880
let NOTE_AS5: Int16 = 932
let NOTE_B5: Int16 = 988
let NOTE_C6: Int16 = 1047
let NOTE_CS6: Int16 = 1109
let NOTE_D6: Int16 = 1175
let NOTE_DS6: Int16 = 1245
let NOTE_E6: Int16 = 1319
let NOTE_F6: Int16 = 1397
let NOTE_FS6: Int16 = 1480
let NOTE_G6: Int16 = 1568
let NOTE_GS6: Int16 = 1661
let NOTE_A6: Int16 = 1760
let NOTE_AS6: Int16 = 1865
let NOTE_B6: Int16 = 1976
let NOTE_C7: Int16 = 2093
let NOTE_CS7: Int16 = 2217
let NOTE_D7: Int16 = 2349
let NOTE_DS7: Int16 = 2489
let NOTE_E7: Int16 = 2637
let NOTE_F7: Int16 = 2794
let NOTE_FS7: Int16 = 2960
let NOTE_G7: Int16 = 3136
let NOTE_GS7: Int16 = 3322
let NOTE_A7: Int16 = 3520
let NOTE_AS7: Int16 = 3729
let NOTE_B7: Int16 = 3951
let NOTE_C8: Int16 = 4186
let NOTE_CS8: Int16 = 4435
let NOTE_D8: Int16 = 4699
let NOTE_DS8: Int16 = 4978

// Available ringtones
class RingtoneLibrary {
    static let shared = RingtoneLibrary()
    
    let ringtones: [Ringtone] = [
        // Nokia Ringtone (full version)
        Ringtone(
            name: "Nokia",
            tempo: 180,
            notes: [
                NOTE_E5, NOTE_D5, NOTE_FS4, NOTE_GS4,
                NOTE_CS5, NOTE_B4, NOTE_D4, NOTE_E4,
                NOTE_B4, NOTE_A4, NOTE_CS4, NOTE_E4,
                NOTE_A4
            ],
            durations: [8, 8, 4, 4, 8, 8, 4, 4, 8, 8, 4, 4, 2]
        ),
        
        // Super Mario Bros Theme (full main theme)
        Ringtone(
            name: "Super Mario",
            tempo: 200,
            notes: [
                NOTE_E5, NOTE_E5, NOTE_REST, NOTE_E5,
                NOTE_REST, NOTE_C5, NOTE_E5, NOTE_REST,
                NOTE_G5, NOTE_REST, NOTE_REST, NOTE_REST,
                NOTE_G4, NOTE_REST, NOTE_REST, NOTE_REST,
                
                NOTE_C5, NOTE_REST, NOTE_REST, NOTE_G4,
                NOTE_REST, NOTE_REST, NOTE_E4, NOTE_REST,
                NOTE_REST, NOTE_A4, NOTE_REST, NOTE_B4,
                NOTE_REST, NOTE_AS4, NOTE_A4, NOTE_REST,
                
                NOTE_G4, NOTE_E5, NOTE_G5,
                NOTE_A5, NOTE_REST, NOTE_F5, NOTE_G5,
                NOTE_REST, NOTE_E5, NOTE_REST, NOTE_C5,
                NOTE_D5, NOTE_B4, NOTE_REST, NOTE_REST,
                
                NOTE_C5, NOTE_REST, NOTE_REST, NOTE_G4,
                NOTE_REST, NOTE_REST, NOTE_E4, NOTE_REST,
                NOTE_REST, NOTE_A4, NOTE_REST, NOTE_B4,
                NOTE_REST, NOTE_AS4, NOTE_A4, NOTE_REST,
                
                NOTE_G4, NOTE_E5, NOTE_G5,
                NOTE_A5, NOTE_REST, NOTE_F5, NOTE_G5,
                NOTE_REST, NOTE_E5, NOTE_REST, NOTE_C5,
                NOTE_D5, NOTE_B4, NOTE_REST, NOTE_REST
            ],
            durations: [
                8, 8, 8, 8,
                8, 8, 8, 8,
                4, 4, 4, 4,
                4, 4, 4, 4,
                
                4, 8, 8, 4,
                8, 8, 4, 8,
                8, 4, 8, 4,
                8, 8, 4, 8,
                
                -8, 8, 8,
                4, 8, 8, 4,
                8, 8, 8, 8,
                8, 8, 4, 4,
                
                4, 8, 8, 4,
                8, 8, 4, 8,
                8, 4, 8, 4,
                8, 8, 4, 8,
                
                -8, 8, 8,
                4, 8, 8, 4,
                8, 8, 8, 8,
                8, 8, 4, 4
            ]
        ),
        
        // Imperial March (full main theme)
        Ringtone(
            name: "Imperial March",
            tempo: 120,
            notes: [
                NOTE_A4, NOTE_A4, NOTE_A4,
                NOTE_F4, NOTE_C5,
                NOTE_A4, NOTE_F4, NOTE_C5, NOTE_A4,
                
                NOTE_E5, NOTE_E5, NOTE_E5,
                NOTE_F5, NOTE_C5,
                NOTE_GS4, NOTE_F4, NOTE_C5, NOTE_A4,
                
                NOTE_A5, NOTE_A4, NOTE_A4,
                NOTE_A5, NOTE_GS5, NOTE_G5,
                NOTE_FS5, NOTE_F5, NOTE_FS5,
                
                NOTE_REST, NOTE_AS4, NOTE_DS5, NOTE_D5, NOTE_CS5,
                NOTE_C5, NOTE_B4, NOTE_C5,
                
                NOTE_REST, NOTE_F4, NOTE_GS4, NOTE_F4, NOTE_A4,
                NOTE_C5, NOTE_A4, NOTE_C5, NOTE_E5,
                
                NOTE_A5, NOTE_A4, NOTE_A4,
                NOTE_A5, NOTE_GS5, NOTE_G5,
                NOTE_FS5, NOTE_F5, NOTE_FS5,
                
                NOTE_REST, NOTE_AS4, NOTE_DS5, NOTE_D5, NOTE_CS5,
                NOTE_C5, NOTE_B4, NOTE_C5,
                
                NOTE_REST, NOTE_F4, NOTE_GS4, NOTE_F4, NOTE_C5,
                NOTE_A4, NOTE_F4, NOTE_C5, NOTE_A4
            ],
            durations: [
                4, 4, 4,
                -8, 16,
                4, -8, 16, 2,
                
                4, 4, 4,
                -8, 16,
                4, -8, 16, 2,
                
                4, -8, 16,
                4, -8, 16,
                16, 16, 8,
                
                8, 8, 4, -8, 16,
                16, 16, 8,
                
                8, 8, 4, -8, 16,
                4, -8, 16, 2,
                
                4, -8, 16,
                4, -8, 16,
                16, 16, 8,
                
                8, 8, 4, -8, 16,
                16, 16, 8,
                
                8, 8, 4, -8, 16,
                4, -8, 16, 2
            ]
        ),
        
        // Keyboard Cat (full loop)
        Ringtone(
            name: "Keyboard Cat",
            tempo: 160,
            notes: [
                NOTE_C4, NOTE_E4, NOTE_G4, NOTE_E4,
                NOTE_C4, NOTE_E4, NOTE_G4, NOTE_E4,
                NOTE_A3, NOTE_C4, NOTE_E4, NOTE_C4,
                NOTE_A3, NOTE_C4, NOTE_E4, NOTE_C4,
                
                NOTE_G3, NOTE_B3, NOTE_D4, NOTE_B3,
                NOTE_G3, NOTE_B3, NOTE_D4, NOTE_B3,
                NOTE_G3, NOTE_G3, NOTE_B3, NOTE_D4,
                NOTE_B3, NOTE_D4, NOTE_G4,
                
                NOTE_C4, NOTE_E4, NOTE_G4, NOTE_E4,
                NOTE_C4, NOTE_E4, NOTE_G4, NOTE_E4,
                NOTE_A3, NOTE_C4, NOTE_E4, NOTE_C4,
                NOTE_A3, NOTE_C4, NOTE_E4, NOTE_C4,
                
                NOTE_G3, NOTE_B3, NOTE_D4, NOTE_B3,
                NOTE_G3, NOTE_B3, NOTE_D4, NOTE_B3,
                NOTE_G3, NOTE_G3, NOTE_B3, NOTE_D4,
                NOTE_B3, NOTE_D4, NOTE_G4
            ],
            durations: [
                4, 4, 4, 4,
                4, 8, -4, 4,
                4, 4, 4, 4,
                4, 8, -4, 4,
                
                4, 4, 4, 4,
                4, 8, -4, 4,
                4, 8, 8, 4,
                8, 8, 2,
                
                4, 4, 4, 4,
                4, 8, -4, 4,
                4, 4, 4, 4,
                4, 8, -4, 4,
                
                4, 4, 4, 4,
                4, 8, -4, 4,
                4, 8, 8, 4,
                8, 8, 2
            ]
        ),
        
        // Fur Elise (extended opening)
        Ringtone(
            name: "Fur Elise",
            tempo: 80,
            notes: [
                NOTE_E5, NOTE_DS5, NOTE_E5, NOTE_DS5, NOTE_E5, NOTE_B4, NOTE_D5, NOTE_C5,
                NOTE_A4, NOTE_REST, NOTE_C4, NOTE_E4, NOTE_A4,
                NOTE_B4, NOTE_REST, NOTE_E4, NOTE_GS4, NOTE_B4,
                NOTE_C5, NOTE_REST, NOTE_E4, NOTE_E5, NOTE_DS5,
                
                NOTE_E5, NOTE_DS5, NOTE_E5, NOTE_B4, NOTE_D5, NOTE_C5,
                NOTE_A4, NOTE_REST, NOTE_C4, NOTE_E4, NOTE_A4,
                NOTE_B4, NOTE_REST, NOTE_E4, NOTE_C5, NOTE_B4,
                NOTE_A4, NOTE_REST, NOTE_B4, NOTE_C5, NOTE_D5,
                
                NOTE_E5, NOTE_REST, NOTE_G4, NOTE_F5, NOTE_E5,
                NOTE_D5, NOTE_REST, NOTE_F4, NOTE_E5, NOTE_D5,
                NOTE_C5, NOTE_REST, NOTE_E4, NOTE_D5, NOTE_C5,
                NOTE_B4, NOTE_REST, NOTE_E4, NOTE_E5, NOTE_REST,
                
                NOTE_E5, NOTE_E6, NOTE_REST, NOTE_DS5, NOTE_E5, NOTE_REST,
                NOTE_REST, NOTE_DS5, NOTE_E5, NOTE_DS5, NOTE_E5, NOTE_DS5,
                NOTE_E5, NOTE_B4, NOTE_D5, NOTE_C5,
                NOTE_A4
            ],
            durations: [
                16, 16, 16, 16, 16, 16, 16, 16,
                4, 8, 16, 16, 16,
                4, 8, 16, 16, 16,
                4, 8, 16, 16, 16,
                
                16, 16, 16, 16, 16, 16,
                4, 8, 16, 16, 16,
                4, 8, 16, 16, 16,
                4, 8, 16, 16, 16,
                
                4, 8, 16, 16, 16,
                4, 8, 16, 16, 16,
                4, 8, 16, 16, 16,
                4, 8, 16, 16, 16,
                
                16, 16, 16, 16, 16, 16,
                16, 16, 16, 16, 16, 16,
                16, 16, 16, 16,
                2
            ]
        ),
        
        // Never Gonna Give You Up (Rick Astley)
        Ringtone(
            name: "Never Gonna Give You Up",
            tempo: 114,
            notes: [
                NOTE_D5, NOTE_E5, NOTE_A4,
                NOTE_E5, NOTE_FS5, NOTE_A5, NOTE_G5, NOTE_FS5,
                NOTE_D5, NOTE_E5, NOTE_A4,
                NOTE_A4, NOTE_A4, NOTE_B4, NOTE_D5, NOTE_D5,
                NOTE_D5, NOTE_E5, NOTE_A4,
                NOTE_E5, NOTE_FS5, NOTE_A5, NOTE_G5, NOTE_FS5,
                NOTE_D5, NOTE_E5, NOTE_A4,
                NOTE_A4, NOTE_A4, NOTE_B4, NOTE_D5, NOTE_D5,
                
                NOTE_REST, NOTE_B4, NOTE_CS5, NOTE_D5, NOTE_D5, NOTE_CS5, NOTE_B4,
                NOTE_A4, NOTE_A4, NOTE_A4, NOTE_E5, NOTE_E5,
                NOTE_E5, NOTE_FS5, NOTE_E5, NOTE_D5,
                NOTE_FS5, NOTE_FS5, NOTE_FS5, NOTE_E5, NOTE_A4,
                NOTE_A4, NOTE_D5, NOTE_D5, NOTE_D5, NOTE_FS5,
                NOTE_FS5, NOTE_FS5, NOTE_E5, NOTE_E5,
                NOTE_D5, NOTE_E5, NOTE_FS5, NOTE_D5,
                NOTE_E5, NOTE_E5, NOTE_E5, NOTE_FS5, NOTE_E5, NOTE_A4,
                
                NOTE_REST, NOTE_B4, NOTE_D5, NOTE_B4,
                NOTE_FS5, NOTE_FS5, NOTE_E5, NOTE_A4, NOTE_B4, NOTE_D5, NOTE_B4,
                NOTE_E5, NOTE_E5, NOTE_D5, NOTE_CS5, NOTE_B4, NOTE_A4, NOTE_B4, NOTE_D5, NOTE_B4,
                NOTE_D5, NOTE_E5, NOTE_CS5, NOTE_B4, NOTE_A4, NOTE_A4, NOTE_E5, NOTE_D5,
                NOTE_A4, NOTE_B4, NOTE_D5, NOTE_B4,
                NOTE_FS5, NOTE_FS5, NOTE_E5, NOTE_A4, NOTE_B4, NOTE_D5, NOTE_B4,
                NOTE_A5, NOTE_CS5, NOTE_D5, NOTE_CS5, NOTE_B4, NOTE_A4, NOTE_B4, NOTE_D5, NOTE_B4,
                NOTE_D5, NOTE_E5, NOTE_CS5, NOTE_B4, NOTE_A4, NOTE_A4, NOTE_E5, NOTE_D5,
                
                NOTE_REST, NOTE_REST, NOTE_B4, NOTE_D5, NOTE_B4, NOTE_D5, NOTE_E5,
                NOTE_REST, NOTE_CS5, NOTE_B4, NOTE_A4,
                NOTE_REST, NOTE_B4, NOTE_B4, NOTE_CS5, NOTE_D5, NOTE_B4, NOTE_A4,
                NOTE_REST, NOTE_A5, NOTE_A5, NOTE_E5, NOTE_FS5, NOTE_E5, NOTE_D5,
                NOTE_REST, NOTE_B4, NOTE_D5, NOTE_B4, NOTE_D5, NOTE_E5,
                NOTE_REST, NOTE_CS5, NOTE_B4, NOTE_A4,
                NOTE_REST, NOTE_B4, NOTE_B4, NOTE_CS5, NOTE_D5, NOTE_B4, NOTE_A4,
                
                NOTE_E5, NOTE_D5, NOTE_A4, NOTE_B4, NOTE_D5, NOTE_B4,
                NOTE_FS5, NOTE_FS5, NOTE_E5, NOTE_A4, NOTE_B4, NOTE_D5, NOTE_B4,
                NOTE_E5, NOTE_E5, NOTE_D5, NOTE_CS5, NOTE_B4, NOTE_A4, NOTE_B4, NOTE_D5, NOTE_B4,
                NOTE_D5, NOTE_E5, NOTE_CS5, NOTE_B4, NOTE_A4, NOTE_A4, NOTE_E5, NOTE_D5,
                NOTE_A4, NOTE_B4, NOTE_D5, NOTE_B4,
                NOTE_FS5, NOTE_FS5, NOTE_E5, NOTE_A4, NOTE_B4, NOTE_D5, NOTE_B4,
                NOTE_A5, NOTE_CS5, NOTE_D5, NOTE_CS5, NOTE_B4, NOTE_A4, NOTE_B4, NOTE_D5, NOTE_B4,
                NOTE_D5, NOTE_E5, NOTE_CS5, NOTE_B4, NOTE_A4, NOTE_A4, NOTE_E5, NOTE_D5,
                NOTE_A4, NOTE_B4, NOTE_D5, NOTE_B4,
                NOTE_FS5, NOTE_FS5, NOTE_E5, NOTE_A4, NOTE_B4, NOTE_D5, NOTE_B4,
                NOTE_A5, NOTE_CS5, NOTE_D5, NOTE_CS5, NOTE_B4, NOTE_A4, NOTE_B4, NOTE_D5, NOTE_B4,
                NOTE_D5, NOTE_E5, NOTE_CS5, NOTE_B4, NOTE_A4, NOTE_A4, NOTE_E5, NOTE_D5
            ],
            durations: [
                -4, -4, 4,
                -4, -4, 16, 16, 8,
                -4, -4, 2,
                16, 16, 16, 8, 16,
                -4, -4, 4,
                -4, -4, 16, 16, 8,
                -4, -4, 2,
                16, 16, 16, 8, 16,
                
                4, 8, 8, 8, 8, 8, 8,
                -4, 8, 8, 8, -4,
                8, 8, 4, -8, 8,
                8, 8, 8, -4, 16, 16,
                16, -4, 8, 16, 16,
                8, 8, 8, -4, 8,
                -8, 16, 4, -8, 8,
                8, 8, 8, 8, 4, 4,
                
                4, 8, 8, 8,
                -8, -8, -4, 16, 16, 16, 16,
                -8, -8, -8, 16, -8, 16, 16, 16, 16,
                4, 8, -8, 16, 4, 8, 4, 2,
                16, 16, 16, 16,
                -8, -8, -4, 16, 16, 16, 16,
                4, 8, -8, 16, 8, 16, 16, 16, 16,
                4, 8, -8, 16, 4, 8, 4, 2,
                
                4, 8, 8, 8, 8, 8, 4,
                8, 8, 8, -4, 4,
                8, 8, 8, 8, 8, 8, 4,
                8, 8, 8, 8, 4, -8, 8,
                8, 8, 8, 8, 8, 4,
                8, 8, 8, -4, 4,
                8, 8, 8, 8, 8, 8, 4,
                
                4, 2, 16, 16, 16, 16,
                -8, -8, -4, 16, 16, 16, 16,
                -8, -8, -8, 16, 8, 16, 16, 16, 16,
                4, 8, -8, 16, 4, 8, 4, 2,
                16, 16, 16, 16,
                -8, -8, -4, 16, 16, 16, 16,
                4, 8, -8, 16, 8, 16, 16, 16, 16,
                4, 8, -8, 16, 4, 8, 4, 2,
                16, 16, 16, 16,
                -8, -8, -4, 16, 16, 16, 16,
                4, 8, -8, 16, 8, 16, 16, 16, 16,
                4, 8, -8, 16, 4, 8, 4, 2
            ]
        ),
        
        // Zelda Theme (main theme extended)
        Ringtone(
            name: "Zelda Theme",
            tempo: 88,
            notes: [
                NOTE_AS4, NOTE_REST, NOTE_REST,
                NOTE_F4, NOTE_AS4, NOTE_REST,
                NOTE_AS4, NOTE_REST,
                NOTE_C5, NOTE_D5, NOTE_DS5,
                
                NOTE_F5, NOTE_REST, NOTE_REST,
                NOTE_F5, NOTE_FS5, NOTE_GS5,
                NOTE_AS5, NOTE_REST, NOTE_AS5,
                NOTE_GS5, NOTE_FS5,
                
                NOTE_F5, NOTE_REST, NOTE_F5,
                NOTE_DS5, NOTE_CS5,
                NOTE_DS5, NOTE_REST, NOTE_DS5,
                NOTE_CS5, NOTE_C5,
                
                NOTE_CS5, NOTE_REST, NOTE_CS5,
                NOTE_C5, NOTE_AS4,
                NOTE_AS4, NOTE_REST,
                NOTE_REST, NOTE_REST,
                
                NOTE_AS4, NOTE_REST, NOTE_REST,
                NOTE_F4, NOTE_AS4, NOTE_REST,
                NOTE_AS4, NOTE_REST,
                NOTE_C5, NOTE_D5, NOTE_DS5,
                
                NOTE_F5, NOTE_REST, NOTE_REST,
                NOTE_F5, NOTE_FS5, NOTE_GS5,
                NOTE_AS5, NOTE_REST, NOTE_CS6,
                NOTE_C6, NOTE_A5,
                
                NOTE_F5, NOTE_REST, NOTE_FS5,
                NOTE_F5, NOTE_E5,
                NOTE_DS5, NOTE_REST, NOTE_E5,
                NOTE_DS5, NOTE_CS5,
                
                NOTE_DS5, NOTE_REST, NOTE_DS5,
                NOTE_CS5, NOTE_C5,
                NOTE_AS4, NOTE_REST,
                NOTE_REST, NOTE_REST
            ],
            durations: [
                -2, -4, 8,
                8, -4, 8,
                -4, 8,
                8, 8, 8,
                
                -2, -4, 8,
                8, 8, 8,
                -2, 16, 16,
                16, 16,
                
                -2, 8, 8,
                8, 8,
                -2, 8, 8,
                8, 8,
                
                -2, 8, 8,
                8, 8,
                2, 8,
                8, 8,
                
                -2, -4, 8,
                8, -4, 8,
                -4, 8,
                8, 8, 8,
                
                -2, -4, 8,
                8, 8, 8,
                -2, 16, 16,
                16, 16,
                
                -2, 8, 8,
                8, 8,
                -2, 8, 8,
                8, 8,
                
                -2, 8, 8,
                8, 8,
                2, 8,
                8, 8
            ]
        )
    ]
}
