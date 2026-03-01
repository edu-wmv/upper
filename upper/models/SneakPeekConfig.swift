//
//  SneakPeekConfig.swift
//  upper
//

import SwiftUI

enum SneakContentType: String {
    case airpods
    case battery
    case volume
    case brightness
    case generic
}

struct SneakPeekConfig: Equatable {
    var type: SneakContentType = .generic
    var icon: String = "info.circle"
    var title: String = ""
    var value: CGFloat = 0
    var accentColor: Color? = nil
    var duration: TimeInterval = 2.0

    static func == (lhs: SneakPeekConfig, rhs: SneakPeekConfig) -> Bool {
        lhs.type == rhs.type
        && lhs.icon == rhs.icon
        && lhs.title == rhs.title
        && lhs.value == rhs.value
        && lhs.duration == rhs.duration
    }
}
