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
