//
//  generic.swift
//  upper
//
//  Created by Eduardo Monteiro on 24/02/26.
//

import Foundation
import Defaults

enum NotchState: Equatable, CustomStringConvertible {
    case closed
    case sneakPeek
    case liveExpanded
    case open

    var description: String {
        switch self {
        case .closed: "Closed"
        case .sneakPeek: "Sneak Peek"
        case .liveExpanded: "Live Expanded"
        case .open: "Open"
        }
    }
}

public enum NotchViews {
    case home
    case shelf
    case sharing
}

enum NotchHeightMode: String, Defaults.Serializable {
    case matchMenuBar = "Match menubar height"
    case matchRealNotch = "Match real notch height"
    case custom = "Custom height"
}

enum SliderColorEnum: String, CaseIterable, Defaults.Serializable {
    case white = "White"
    case albumArt = "Match album art"
    case accent = "Accent color"
    
    var localizedName: String {
        switch self {
        case .white:
            return String(localized: "Standard")
        case .albumArt:
            return String(localized: "Match Album Art")
        case .accent:
            return String(localized: "Match Accent Color")
        }
    }
}
