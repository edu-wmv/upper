//
//  MediaState.swift
//  upper
//
//  Created by Eduardo Monteiro on 01/03/26.
//

import Foundation

struct PlaybackState {
    var bundleIdentifier: String
    var isPlaying: Bool = false
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var artwork: Data?
    var currentTime: Double = 0
    var duration: Double = 0
    var playbackRate: Double = 1
    var isShuffled: Bool = false
    var repeatMode: RepeatMode = .off
    var lastUpdated: Date = .distantPast
}

enum RepeatMode: Int, Codable {
    case off = 1
    case one = 2
    case all = 3
}

extension PlaybackState: Equatable {
    static func == (lhs: PlaybackState, rhs: PlaybackState) -> Bool {
        return lhs.bundleIdentifier == rhs.bundleIdentifier
        && lhs.isPlaying == rhs.isPlaying
        && lhs.title == rhs.title
        && lhs.artist == rhs.artist
        && lhs.album == rhs.album
        && lhs.artwork == rhs.artwork
        && lhs.currentTime == rhs.currentTime
        && lhs.duration == rhs.duration
        && lhs.isShuffled == rhs.isShuffled
        && lhs.repeatMode == rhs.repeatMode
    }
}
