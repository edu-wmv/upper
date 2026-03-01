//
//  upperApp.swift
//  upper
//
//  Created by Eduardo Monteiro on 24/02/26.
//

import SwiftUI
import Defaults

@main
struct upperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) var openWindow

    var body: some Scene {
        Settings {
            Text("upper Settings")
                .frame(width: 400, height: 300)
        }

        MenuBarExtra("upper", systemImage: "sparkle") {
            SettingsLink {
                Text("Settings")
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Open Debug Window") {
               openWindow(id: "debug-window")
            }

            Divider()
  
            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("Q", modifiers: .command)
        }
        
        Window("upper-debug", id: "debug-window") {
            DebugView(viewModel: appDelegate.viewModel)
        }
    }

    @ViewBuilder
    private var stateMenu: some View {
        let vm = appDelegate.viewModel

        Button("Open") { Task { @MainActor in vm.open() } }
        Button("Close") { Task { @MainActor in vm.close() } }
        Button("Minimal Mode: \(Defaults[.enableMinimalMode] ? "On" : "Off")") {
            Defaults[.enableMinimalMode].toggle()
        }

        Menu("Sneak Peek") {
            Button("AirPods Connected") {
                Task { @MainActor in
                    vm.showSneakPeek(SneakPeekConfig(
                        type: .airpods, icon: "airpodspro",
                        title: "Connected", duration: 3.0
                    ))
                }
            }
            Button("Battery 80%") {
                Task { @MainActor in
                    vm.showSneakPeek(SneakPeekConfig(
                        type: .battery, icon: "battery.75percent",
                        title: "80%", value: 80, duration: 3.0
                    ))
                }
            }
            Button("Volume") {
                Task { @MainActor in
                    vm.showSneakPeek(SneakPeekConfig(
                        type: .volume, icon: "speaker.wave.2.fill",
                        title: "Volume", value: 0.65, duration: 2.0
                    ))
                }
            }
            Button("Generic") {
                Task { @MainActor in
                    vm.showSneakPeek(SneakPeekConfig(
                        type: .generic, icon: "info.circle",
                        title: "Hello", duration: 2.0
                    ))
                }
            }
        }

        Divider()

        Text("State: \(vm.state.description)")
            .font(.caption)
    }
}
