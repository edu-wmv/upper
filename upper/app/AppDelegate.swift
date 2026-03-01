//
//  AppDelegate.swift
//  upper
//
//  Created by Eduardo Monteiro on 24/02/26.
//

import SwiftUI
import Defaults
import Combine

extension AppDelegate {
    static var shared: AppDelegate? {
        NSApplication.shared.delegate as? AppDelegate
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var viewModel: UpperViewModel = .init()
    var viewModels: [NSScreen: UpperViewModel] = [:]
    
    private var window: NSWindow?
    var windows: [NSScreen: NSWindow] = [:]
    private var previousScreens: [NSScreen]?
    
    @ObservedObject var coordinator = UpperViewCoordinator.shared
    
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(onScreenLocked),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil
        )

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(onScreenUnlocked),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )
        
        Defaults.publisher(.enableMinimalMode, options: [])
            .sink { [weak self] change in
                self?.updateWindowsSize()
            }
            .store(in: &cancellables)

        let window = createNotchWindow(
            for: NSScreen.main ?? NSScreen.screens.first!,
            with: viewModel
        )
        
        self.window = window
        adjustWindowPosition(changeAlpha: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - Window creation

    private func createNotchWindow(for screen: NSScreen, with viewModel: UpperViewModel) -> NSWindow {
        let size = calculateNotchSize()

        let window = UpperPanel(
            contentRect: NSRect(
                x: 0, y: 0, width: size.width, height: size.height
            ),
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow],
            backing: .buffered,
            defer: false
        )
        
        window.animationBehavior = .none
        
        window.contentView = NSHostingView(
            rootView: NotchContentView()
                .environmentObject(viewModel)
        )

        window.orderFrontRegardless()

        return window
    }
    
    private func cleanupWindows(shouldInvert: Bool = false) {
        if shouldInvert ? !Defaults[.showOnAllDisplays] : Defaults[.showOnAllDisplays] {
            for window in windows.values {
                window.close()
            }
            windows.removeAll()
            viewModels.removeAll()
        } else if let window = window {
            window.close()
            self.window = nil
        }
    }

    // MARK: - Positioning
    
    private func positionWindow(_ window: NSWindow, on screen: NSScreen, changeAlpha: Bool = false) {
        if changeAlpha { window.alphaValue = 0 }
        
        let screenFrame = screen.frame
        let centerX = screenFrame.origin.x + (screenFrame.width / 2)
        let newX = centerX - (window.frame.width / 2)
        let newY = screenFrame.origin.y + screenFrame.height - window.frame.height
        
        window.setFrame(NSRect(
            x: newX, y: newY, width: window.frame.width, height: window.frame.height
        ), display: true)
        
        if changeAlpha { window.alphaValue = 1 }
    }

    @objc func adjustWindowPosition(changeAlpha: Bool = false) {
        if Defaults[.showOnAllDisplays] {
            let currentScreens = Set(NSScreen.screens)
            
            for screen in windows.keys where !currentScreens.contains(screen) {
                if let window = windows[screen] {
                    window.close()
                    windows.removeValue(forKey: screen)
                    viewModels.removeValue(forKey: screen)
                }
            }
            
            for screen in currentScreens {
                if windows[screen] == nil {
                    let viewModel = UpperViewModel(screen: screen.localizedName)
                    let window = createNotchWindow(for: screen, with: viewModel)
                    
                    windows[screen] = window
                    viewModels[screen] = viewModel
                }
                
                if let window = windows[screen],
                   let viewModel = viewModels[screen] {
                    positionWindow(window, on: screen, changeAlpha: changeAlpha)
                    if viewModel.state == .closed { viewModel.close() }
                }
            }
            
        } else {
            let selectedScreen: NSScreen
            
            if let preferredScreen = NSScreen.screens.first(where: { $0.localizedName == coordinator.preferredScreen }) {
                coordinator.selectedScreen = coordinator.preferredScreen
                selectedScreen = preferredScreen
            } else if Defaults[.autoSwitchDisplay], let mainScreen = NSScreen.main {
                coordinator.selectedScreen = mainScreen.localizedName
                selectedScreen = mainScreen
            } else {
                if let window = window {
                    window.alphaValue = 0
                }
                return
            }
            
            viewModel.screen = selectedScreen.localizedName
            viewModel.notchSize = getClosedNotchSize(screen: selectedScreen.localizedName)
            
            if window == nil {
                 window = createNotchWindow(for: selectedScreen, with: viewModel)
            }
            
            if let window = window {
                positionWindow(window, on: selectedScreen, changeAlpha: changeAlpha)
                if viewModel.state == .closed { viewModel.close() }
            }
        }
    }

    // MARK: - Screen observers

    @objc private func screenConfigurationDidChange() {
        let currentScreens = NSScreen.screens

        let changed = currentScreens.count != previousScreens?.count
        || Set(currentScreens.map { $0.localizedName }) != Set(previousScreens?.map { $0.localizedName } ?? [])
        || Set(currentScreens.map { $0.frame }) != Set(previousScreens?.map { $0.frame } ?? [])
        
        previousScreens = currentScreens

        if changed {
            DispatchQueue.main.async { [weak self] in
                self?.cleanupWindows()
                self?.adjustWindowPosition()
            }
        }
    }

    @objc private func onScreenLocked(_ notification: Notification) {
        window?.orderOut(nil)
    }

    @objc private func onScreenUnlocked(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.window?.orderFrontRegardless()
            self?.adjustWindowPosition()
        }
    }
    
    // MARK: - Window resizing
    
    private func resizeWindow(_ window: NSWindow, on screen: NSScreen, to size: CGSize, animated: Bool) {
        let screenFrame = screen.frame
        let centerX = screenFrame.midX
        let newOrigin = CGPoint(
            x: centerX - size.width / 2,
            y: screenFrame.origin.y + screenFrame.height - size.height
        )
        let targetFrame = NSRect(x: newOrigin.x, y: newOrigin.y, width: size.width, height: size.height)
        
        window.setFrame(targetFrame, display: true)
    }
    
    private func resizeWindows(to size: CGSize, animated: Bool, force: Bool) {
        guard size.width > 0, size.height > 0 else { return }
        
        if Defaults[.showOnAllDisplays] {
            for (screen, window) in windows {
                if force || window.frame.size != size {
                    resizeWindow(window, on: screen, to: size, animated: animated)
                }
            }
        } else if let window {
            let screen = window.screen ?? NSScreen.screens.first { $0.frame.contains(window.frame) } ?? NSScreen.main ?? NSScreen.screens.first
            guard let screen else { return }
            
            if force || window.frame.size != size {
                resizeWindow(window, on: screen, to: size, animated: animated)
            }
        }
    }
    
    func ensureWindowSize(_ size: CGSize, animated: Bool, force: Bool = false) {
        resizeWindows(to: size, animated: animated, force: force)
    }
    
    private func calculateNotchSize() -> CGSize {
        var baseSize = Defaults[.enableMinimalMode] ? minimalOpenNotchSize : openNotchSize
        
        return addShadowPadding(to: baseSize, isMinimal: Defaults[.enableMinimalMode])
    }
        
    private func updateWindowsSize() {
        let size = calculateNotchSize()
        let animatedSize = shouldAnimateResize(for: size)
        resizeWindows(to: size, animated: animatedSize, force: false)
        
    }
    
    private func shouldAnimateResize(for newSize: CGSize) -> Bool {
        if Defaults[.enableMinimalMode] {
            return false
        }
        
        return true
    }
}
