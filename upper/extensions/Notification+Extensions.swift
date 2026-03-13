//
//  Notification.swift
//  upper
//
//  Created by Eduardo Monteiro on 03/03/26.
//

import Foundation

extension Notification.Name {
    // MARK: - Media Controller
    static let mediaControllerChanged = Notification.Name("mediaControllerChanged")
    
    // MARK: - Audio Route
    static let systemAudioRouteDidChange = Notification.Name("systemAudioRouteDidChange")
    static let systemVolumeDidChange = Notification.Name("systemVolumeDidChange")
}
