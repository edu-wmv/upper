//
//  media.swift
//  upper
//
//  Created by Eduardo Monteiro on 03/03/26.
//

import Combine
import Defaults
import Foundation

enum SkipDirection: Equatable {
    case backward
    case forward
}

enum MediaCheckerError: Error {
    case missingResources
    case processExecutionFailed
    case timeout
}

enum MediaSkipBehavior: String, CaseIterable, Identifiable, Defaults.Serializable {
    case track
    case tenSecond
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .track:
            return String(localized: "Standard previous/next track controls")
        case .tenSecond:
            return String(localized: "Skip forward or backward by ten seconds")
        }
    }
}

enum MediaControllerType: String, CaseIterable, Identifiable, Defaults.Serializable {
    case nowPlaying = "Now Playing"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .nowPlaying: return String(localized: "Now Playing")
        }
    }
}
