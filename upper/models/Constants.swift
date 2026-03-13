//
//  Constants.swift
//  upper
//
//  Created by Eduardo Monteiro on 24/02/26.
//

import Defaults
import SwiftUI

extension Defaults.Keys {

    // MARK: Behavior
    static let enableHaptics = Key<Bool>("enableHaptics", default: true)
    static let nonNotchHeight = Key<CGFloat>("nonNotchHeight", default: 32)
    static let notchHeight = Key<CGFloat>("notchHeight", default: 32)
    static let openNotchWidth = Key<CGFloat>("openNotchWidth", default: 640)
    
    static let notchHeightMode = Key<NotchHeightMode>("notchHeightMode", default: .matchRealNotch)
    static let nonNotchHeightMode = Key<NotchHeightMode>("nonNotchHeightMode", default: .matchMenuBar)
    
    
    static let enableMinimalMode = Key<Bool>("enableMinimalMode", default: false)
    static let cornerRadiusScaling = Key<Bool>("cornerRadiusScaling", default: true)
    
    static let showOnAllDisplays = Key<Bool>("showOnAllDisplays", default: false)
    static let autoSwitchDisplay = Key<Bool>("autoSwitchDisplay", default: false)
    
    // MARK: Gestures
    static let mediaGestureBehavior = Key<MediaSkipBehavior>("mediaGestureBehavior", default: .track)
    
    // MARK: Appearance
    static let sliderColor = Key<SliderColorEnum>("sliderUIColor", default: .albumArt)
    
    // MARK: Media playback
    static let mediaControlSlots = Key<[MediaControlButton]>("mediaControlSlots", default: MediaControlButton.defaultLayout)
    
}
