//
//  MediaChecker.swift
//  upper
//
//  Created by Eduardo Monteiro on 03/03/26.
//

import Foundation

@MainActor
final class MediaChecker: Sendable {
    func checkDeprecationStatus() async throws -> Bool {
        guard let scriptURL = Bundle.main.url(forResource: "mediaremote-adapter", withExtension: "pl"),
              let nowPlayingTestClientPath = Bundle.main.url(forResource: "MediaRemoteAdapterTestClient", withExtension: nil)?.path,
              let frameworkPath = Bundle.main.resourceURL?
            .appendingPathComponent("MediaRemoteAdapter.framework")
            .path
        else { throw MediaCheckerError.missingResources }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        process.arguments = [scriptURL.path, frameworkPath, nowPlayingTestClientPath, "test"]
        
        do { try process.run() }
        catch { throw MediaCheckerError.processExecutionFailed }
        
        let didExit: Bool = try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                process.waitUntilExit()
                return true
            }
            group.addTask {
                try await Task.sleep(for: .seconds(10))
                if process.isRunning {
                    process.terminate()
                }
                return false
            }
            for try await exited in group {
                if exited {
                    group.cancelAll()
                    return true
                }
            }
            throw MediaCheckerError.timeout
        }
        
        if !didExit {
            throw MediaCheckerError.timeout
        }
        
        let isDeprecated = process.terminationStatus == 1
        return isDeprecated
    }
}
