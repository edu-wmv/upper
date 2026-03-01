//
//  matters.swift
//  upper
//
//  Created by Eduardo Monteiro on 24/02/26.
//

import Foundation
import SwiftUI
import Defaults

var openNotchSize: CGSize {
    let width = Defaults[.openNotchWidth]
    return CGSize(width: width, height: 200)
}

private let minimalBaseOpenNotchSize: CGSize = CGSize(width: 420, height: 180)

@MainActor
var minimalOpenNotchSize: CGSize {
    return minimalBaseOpenNotchSize
}


let cornerRadiusInsets: (opened: (top: CGFloat, bottom: CGFloat), closed: (top: CGFloat, bottom: CGFloat)) = (
    opened: (top: 19, bottom: 24),
    closed: (top: 6, bottom: 14)
)

let minimalCornerRadiusInsets: (opened: (top: CGFloat, bottom: CGFloat), closed: (top: CGFloat, bottom: CGFloat)) = (
    opened: (top: 35, bottom: 35),
    closed: cornerRadiusInsets.closed
)
    


let sneakPeekCornerRadiusInsets: (top: CGFloat, bottom: CGFloat) = (top: 6, bottom: 16)

func getSneakPeekSize(screen: String? = nil, for type: SneakContentType = .generic) -> CGSize {
    let closed = getClosedNotchSize(screen: screen)
    let extraHeight: CGFloat = switch type {
    case .airpods:    36
    case .battery:    40
    case .volume, .brightness: 36
    case .generic:    36
    }
    
    // Minimal or no extra width to keep it looking like the original notch shape.
    // Adding just a tiny bit (10) to make the bottom radii look natural.
    return CGSize(width: closed.width + 10, height: closed.height + extraHeight)
}

func addShadowPadding(to size: CGSize, isMinimal: Bool) -> CGSize {
    CGSize(width: size.width, height: size.height + (isMinimal ? 12 : 18))
}

func getClosedNotchSize(screen: String? = nil) -> CGSize {
    var notchHeight: CGFloat = Defaults[.nonNotchHeight]
    var notchWidth: CGFloat = 185
    
    var selectedScreen = NSScreen.main
    
    if let customScren = screen {
        selectedScreen = NSScreen.screens.first(where: { $0.localizedName == customScren })
    }
    
    if let screen = selectedScreen {
        if let topLeftNotchPadding: CGFloat = screen.auxiliaryTopLeftArea?.width,
           let topRightNotchPadding: CGFloat = screen.auxiliaryTopRightArea?.width
        {
            notchWidth = screen.frame.width - topLeftNotchPadding - topRightNotchPadding + 4
        }
        
        if screen.safeAreaInsets.top > 0 {
            notchHeight = Defaults[.notchHeight]
            if Defaults[.notchHeightMode] == .matchRealNotch {
                notchHeight = screen.safeAreaInsets.top
            } else if Defaults[.notchHeightMode] == .matchMenuBar {
                notchHeight = screen.frame.maxY - screen.visibleFrame.maxY
            }
        } else {
            notchHeight = Defaults[.nonNotchHeight]
            if Defaults[.nonNotchHeightMode] == .matchMenuBar {
                notchHeight = screen.frame.maxY - screen.visibleFrame.maxY
            }
        }
    }
    
    return CGSize(width: notchWidth, height: notchHeight)
}

func getScreenFrame(_ screen: String? = nil) -> CGRect? {
    var selectedScreen = NSScreen.main
    
    if let customScreen = screen {
        selectedScreen = NSScreen.screens.first(where: { $0.localizedName == customScreen })
    }
    
    if let screen = selectedScreen {
        return screen.frame
    }
    
    return nil

}
