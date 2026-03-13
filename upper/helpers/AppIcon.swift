//
//  AppIcon.swift
//  upper
//
//  Created by Eduardo Monteiro on 08/03/26.
//

import SwiftUI

func AppIconAsNSImage(for bundleId: String) -> NSImage? {
    let workspace = NSWorkspace.shared
    
    if let appUrl = workspace.urlForApplication(withBundleIdentifier: bundleId) {
        let appIcon = workspace.icon(forFile: appUrl.path)
        return appIcon
    }
    
    return nil
}
