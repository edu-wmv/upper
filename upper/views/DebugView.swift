//
//  DebugView.swift
//  upper
//
//  Created by Eduardo Monteiro on 28/02/26.
//

import SwiftUI
import Defaults

struct DebugView: View {
    @ObservedObject var viewModel: UpperViewModel
    
    @Default(.enableMinimalMode) var enableMinimalMode: Bool
    @State private var musicPermissionGranted: Bool? = nil
    @State private var musicPermissionError: String? = nil
    
    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 10) {
                VStack(spacing: 5) {
                    Text("State: \(viewModel.state.description)")
                    Text("Selected Screen: \(viewModel.coordinator.selectedScreen)")
                }
                
                Divider()
                
                Text("Actions")
                HStack(spacing: 20) {
                    Button("Open") { Task { @MainActor in viewModel.open() } }
                    Button("Close") { Task { @MainActor in viewModel.close() } }
                }
                
                Divider()
                
                Text("UI")
                HStack(spacing: 20) {
                    Toggle("Minimal mode", isOn: $enableMinimalMode)
                        .onChange(of: enableMinimalMode) { _, newValue in
                            enableMinimalMode = newValue
                        }
                }
                
                Divider()
                
                Text("Permissions")
                VStack(spacing: 6) {
                    HStack(spacing: 12) {
                        Button("Request Music Automation") {
                            musicPermissionGranted = nil
                            musicPermissionError = nil
                            Task {
                                let result = await AppleScriptHelper.requestMusicAutomationPermission()
                                await MainActor.run {
                                    musicPermissionGranted = result.granted
                                    if let error = result.error {
                                        let nsError = error as NSError
                                        let message = nsError.userInfo["NSAppleScriptErrorMessage"] as? String
                                            ?? nsError.userInfo[NSLocalizedDescriptionKey] as? String
                                            ?? error.localizedDescription
                                        let code = nsError.userInfo["NSAppleScriptErrorNumber"] as? Int
                                        musicPermissionError = code != nil ? "[\(code!)] \(message)" : message
                                    }
                                }
                            }
                        }
                        
                        if let granted = musicPermissionGranted {
                            Label(
                                granted ? "Granted" : "Denied",
                                systemImage: granted ? "checkmark.circle.fill" : "xmark.circle.fill"
                            )
                            .foregroundStyle(granted ? .green : .red)
                            .font(.callout)
                            .transition(.opacity.animation(.easeIn(duration: 0.2)))
                        }
                    }
                    
                    if let errorMessage = musicPermissionError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }
                
                Divider()
                
                Text("Sneak Peek")
                HStack(spacing: 20) {
                    Button("AirPods Connected") {
                        Task { @MainActor in
                            viewModel.showSneakPeek(SneakPeekConfig(
                                type: .airpods, icon: "airpodspro",
                                title: "Connected", duration: 3.0
                            ))
                        }
                    }
                    Button("Battery 80%") {
                        Task { @MainActor in
                            viewModel.showSneakPeek(SneakPeekConfig(
                                type: .battery, icon: "battery.75percent",
                                title: "80%", value: 80, duration: 3.0
                            ))
                        }
                    }
                    Button("Volume") {
                        Task { @MainActor in
                            viewModel.showSneakPeek(SneakPeekConfig(
                                type: .volume, icon: "speaker.wave.2.fill",
                                title: "Volume", value: 0.65, duration: 2.0
                            ))
                        }
                    }
                    Button("Generic") {
                        Task { @MainActor in
                            viewModel.showSneakPeek(SneakPeekConfig(
                                type: .generic, icon: "info.circle",
                                title: "Hello", duration: 2.0
                            ))
                        }
                    }
                }
            }
        }
        .frame(width: 500)
    }
}

#Preview("Debug View") {
    DebugView(viewModel: UpperViewModel())
}
