//
//  MediaControlButtons.swift
//  upper
//
//  Created by Eduardo Monteiro on 10/03/26.
//

import Defaults

enum MediaControlButton: String, CaseIterable, Identifiable, Codable, Defaults.Serializable {
    case favorite
    case shuffle
    case backward
    case playPause
    case forward
    case output
    case repeatMode
    case none
    
    static let slotCount = 5
    
    static let defaultLayout: [MediaControlButton] = [
        .shuffle,
        .backward,
        .playPause,
        .forward,
        .repeatMode
    ]
    
    static let minimalLayout: [MediaControlButton] = [
        .favorite,
        .backward,
        .playPause,
        .forward,
        .output
    ]
    
    static let pickerOptions: [MediaControlButton] = [
        .favorite,
        .shuffle,
        .backward,
        .playPause,
        .forward,
        .output,
        .repeatMode
    ]
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .favorite:
            return "Favorite"
        case .shuffle:
            return "Shuffle"
        case .backward:
            return "Previous Track"
        case .playPause:
            return "Play / Pause"
        case .forward:
            return "Next Track"
        case .output:
            return "Change Media Output"
        case .repeatMode:
            return "Repeat"
        case .none:
            return "Empty Slot"
        }
    }
    
    var iconName: String {
        switch self {
        case .favorite:
            return "star"
        case .shuffle:
            return "shuffle"
        case .backward:
            return "backward.fill"
        case .playPause:
            return "playpause"
        case .forward:
            return "forward.fill"
        case .output:
            return "speaker.wave.2"
        case .repeatMode:
            return "repeat"
        case .none:
            return ""
        }
    }
    
    var prefersLargeScale: Bool { self == .playPause }
}

extension Array where Element == MediaControlButton {
    func normalized(allowingMediaOutput: Bool) -> [MediaControlButton] {
        var sanitized = map { button -> MediaControlButton in
            if button == .output && !allowingMediaOutput {
                return .none
            }
            
            return button
        }
        
        if sanitized.count < MediaControlButton.slotCount {
            sanitized.append(contentsOf: Array(repeating: .none, count: MediaControlButton.slotCount - sanitized.count))
        }
        
        if sanitized.count > MediaControlButton.slotCount {
            sanitized = Array(sanitized.prefix(MediaControlButton.slotCount))
        }
        
        return sanitized
    }
}
