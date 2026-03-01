//
//  Logger.swift
//  upper
//
//  Created by Eduardo Monteiro on 24/02/26.
//

import Foundation
import OSLog
import SwiftUI

enum LogType: String {
    case info = "ℹ️"
    case lifecycle = "🔄"
    case memory = "💾"
    case performance = "⚡️"
    case ui = "🎨"
    case network = "🌐"
    case warning = "⚠️"
    case error = "❌"
    case debug = "🐛"
    case sucess = "✅"
    
    var osCategoryName: String {
        switch self {
        case .info: return "info"
        case .lifecycle: return "lifecycle"
        case .memory: return "memory"
        case .performance: return "performance"
        case .ui: return "ui"
        case .network: return "network"
        case .warning: return "warning"
        case .error: return "error"
        case .debug: return "debug"
        case .sucess: return "success"
        }
    }
}

struct Logger {
    private static let subsystem = "com.whosedu.upper"
    private static var osLoggerCache: [LogType: OSLog] = [:]
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private static func osLogger(for type: LogType) -> OSLog {
        if let cached = osLoggerCache[type] {
            return cached
        }
        
        let logger = OSLog(subsystem: subsystem, category: type.osCategoryName)
        osLoggerCache[type] = logger
        return logger
    }
    
    static func log(
        _ message: String,
        type: LogType,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let filename = (file as NSString).lastPathComponent
        let timestamp = dateFormatter.string(from: Date())
        let entry = "\(type.rawValue) [\(timestamp)] [\(filename):\(line)] \(function) -> \(message)"
        let logger = osLogger(for: type)
        
        os_log("%{public}@", log: logger, type: .default, entry)
        
#if DEBUG
        Swift.print(entry)
#endif
    }
    
    static func trackMemoryUsage(
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerResult: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerResult == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size) / 1024.0 / 1024.0
            log(
                String(
                    format: "Memory used: %.2f MB", usedMemory),
                type: .memory,
                file: file,
                function: function,
                line: line
            )
        }
    }
}

struct ViewLifecycleTracker: ViewModifier {
    let identifier: String
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                Logger.log("\(identifier) appeared", type: .lifecycle)
                Logger.trackMemoryUsage()
            }
            .onDisappear {
                Logger.log("\(identifier) disappeared", type: .lifecycle)
                Logger.trackMemoryUsage()
            }
    }
}

extension View {
    func trackLifecycle(_ identifier: String) -> some View {
        self.modifier(ViewLifecycleTracker(identifier: identifier))
    }
}
