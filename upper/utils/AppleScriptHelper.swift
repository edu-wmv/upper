//
//  AppleScriptHelper.swift
//  upper
//
//  Created by Eduardo Monteiro on 13/03/26.
//

import Foundation

class AppleScriptHelper {
    @discardableResult
    class func execute(_ scriptText: String) async throws -> NSAppleEventDescriptor? {
        try await withCheckedThrowingContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let script = NSAppleScript(source: scriptText)
                var error: NSDictionary?
                
                if let descriptor = script?.executeAndReturnError(&error) {
                    continuation.resume(returning: descriptor)
                } else if let error = error {
                    continuation.resume(throwing: NSError(domain: "AppleScriptError", code: 1, userInfo: error as? [String: Any]))
                } else {
                    continuation.resume(throwing: NSError(domain: "AppleScriptError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown error ocurred."]))
                }
            }
        }
    }
    
    class func executeVoid(_ scriptText: String) async throws {
        _ = try await execute(scriptText)
    }

    /// Sends a minimal Apple Event to Music to trigger the TCC automation permission dialog.
    /// Returns the granted status and the underlying error if the request failed.
    class func requestMusicAutomationPermission() async -> (granted: Bool, error: Error?) {
        do {
            try await executeVoid("""
                tell application "Music"
                    get version
                end tell
                """)
            return (true, nil)
        } catch {
            return (false, error)
        }
    }
}
