//
//  NSScreen+Notch.swift
//  upper
//
//  Created by Eduardo Monteiro on 24/02/26.
//

import AppKit

extension NSScreen {

    var hasNotch: Bool {
        auxiliaryTopLeftArea != nil && auxiliaryTopRightArea != nil
    }

    var notchSize: NSSize? {
        guard let leftPadding = auxiliaryTopLeftArea?.width,
              let rightPadding = auxiliaryTopRightArea?.width else {
            return nil
        }

        let width = frame.width - leftPadding - rightPadding + 10
        let height = safeAreaInsets.top

        guard height > 0 else { return nil }
        return NSSize(width: width, height: height)
    }

    var notchFrame: NSRect? {
        guard let size = notchSize else { return nil }
        return NSRect(
            x: frame.midX - size.width / 2,
            y: frame.maxY - size.height,
            width: size.width,
            height: size.height
        )
    }

    var menuBarHeight: CGFloat {
        frame.maxY - visibleFrame.maxY
    }

    static var notchScreen: NSScreen? {
        screens.first(where: { $0.hasNotch }) ?? main
    }
}
