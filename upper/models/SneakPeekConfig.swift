//
//  SneakPeekConfig.swift
//  upper
//

import SwiftUI
import Defaults

enum SneakContentType: Equatable {
    case airpods
    case battery
    case volume
    case brightness
    case generic
    case media
}

extension SneakContentType {
    static func == (lhs: SneakContentType, rhs: SneakContentType) -> Bool {
        switch (lhs, rhs) {
        case (.airpods, .airpods),
            (.battery, .battery),
            (.volume, .volume),
            (.brightness, .brightness),
            (.generic, .generic),
            (.media, .media):
            return true
        default:
            return false
            
        }
    }
}

enum SneakPeekStyle: String, CaseIterable, Identifiable, Defaults.Serializable {
    case standard = "Default"
    case inline = "Inline"
    
    var id: String { self.rawValue }
    
    var LocalizedName: String {
        switch self {
        case .standard:
            return String(localized: "Default")
        case .inline:
            return String(localized: "Inline")
        }
    }
}

struct SneakPeek {
    var show: Bool = false
    var type: SneakContentType = .media
    var value: CGFloat = 0
    var icon: String = ""
    var title: String = ""
    var subtitle: String = ""
    var accentColor: String = ""
    var styleOverride: SneakPeekStyle? = nil
}

struct SneakPeekConfig: Equatable {
    var type: SneakContentType = .generic
    var icon: String = "info.circle"
    var title: String = ""
    var subtitle: String = ""
    var value: CGFloat = 0
    var accentColor: Color? = nil
    var direction: MediaLiveSneakPeekDirection? = nil
    var duration: TimeInterval = 2.0
    
    static func == (lhs: SneakPeekConfig, rhs: SneakPeekConfig) -> Bool {
        lhs.type == rhs.type
        && lhs.icon == rhs.icon
        && lhs.title == rhs.title
        && lhs.subtitle == rhs.subtitle
        && lhs.value == rhs.value
        && lhs.direction == rhs.direction
        && lhs.duration == rhs.duration
    }
}
