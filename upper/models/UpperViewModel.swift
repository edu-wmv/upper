//
//  UpperViewModel.swift
//  upper
//
//  Created by Eduardo Monteiro on 24/02/26.
//

import SwiftUI
import Defaults
import Combine

@MainActor
class UpperViewModel: NSObject, ObservableObject {
    @ObservedObject var coordinator = UpperViewCoordinator.shared
    var cancellables: Set<AnyCancellable> = []

    // MARK: - State

    @Published private(set) var state: NotchState = .closed
    @Published var notchSize: CGSize = getClosedNotchSize()
    @Published var closedNotchSize: CGSize = getClosedNotchSize()
    @Published var isHovering: Bool = false
    
    @Published var screen: String?
    
    @Published var shouldRecheckHover: Bool = false
    
    @Published var isMediaOutputPopoverActive: Bool = false

    // MARK: - Sneak Peek

    @Published var activeSneakPeek: SneakPeekConfig? = nil
    private var sneakPeekTask: Task<Void, Never>?

    @AppStorage("hoverDuration") var hoverDuration: Double = 0.3

    // MARK: - Gesture tracking

    @Published var gestureProgress: CGFloat = .zero

    // MARK: - Internal

    @State private var hoverTask: Task<Void, Never>?

    // MARK: - Init

    init(screen: String? = nil) {
        super.init()
        
        self.screen = screen
        notchSize = getClosedNotchSize()
        closedNotchSize = notchSize

        coordinator.sneakPeekSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] config in
                self?.showSneakPeek(config)
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    deinit {
        destroy()
    }
    
    func destroy() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }

    // MARK: - State transitions

    func open() {
        sneakPeekTask?.cancel()
        sneakPeekTask = nil
        activeSneakPeek = nil

        withAnimation(AnimationLibrary.notchOpen) {
            let targetSize = calculateDynamicNotchSize()
            
            let applyWindowResize: () -> Void = {
                guard let delegate = AppDelegate.shared else { return }
                delegate.ensureWindowSize(
                    addShadowPadding(to: targetSize, isMinimal: Defaults[.enableMinimalMode]),
                    animated: false,
                    force: true
                )
            }
            
            if Thread.isMainThread {
                applyWindowResize()
            } else {
                DispatchQueue.main.async(execute: applyWindowResize)
            }
            
            notchSize = targetSize
            state = .open
        }
    }
    
    func close() {
        sneakPeekTask?.cancel()
        sneakPeekTask = nil
        activeSneakPeek = nil

        withAnimation(AnimationLibrary.notchClose) {
            let targetSize = getClosedNotchSize(screen: screen)
            notchSize = targetSize
            closedNotchSize = targetSize
            state = .closed
        }
    }

    // MARK: - Sneak Peek

    func showSneakPeek(_ config: SneakPeekConfig) {
        guard state != .open else { return }
        sneakPeekTask?.cancel()

        let sneakSize = getSneakPeekSize(screen: screen, for: config)

        withAnimation(AnimationLibrary.sneakPeekOpen) {
            activeSneakPeek = config
            notchSize = sneakSize
            state = .sneakPeek
        }

        guard config.duration.isFinite else { return }

        sneakPeekTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(config.duration))
            guard let self, !Task.isCancelled else { return }
            if self.state == .sneakPeek {
                withAnimation(AnimationLibrary.sneakPeekClose) {
                    self.dismissSneakPeek()
                }
            }
        }
    }

    func dismissSneakPeek() {
        sneakPeekTask?.cancel()
        sneakPeekTask = nil
        activeSneakPeek = nil
        close()
    }
    
    // MARK: - Hover

    func isMouseHovering(position: NSPoint = NSEvent.mouseLocation) -> Bool {
        let screenFrame = getScreenFrame(screen)
        
        if let frame = screenFrame {
            let baseY = frame.maxY - notchSize.height
            let baseX = frame.midX - notchSize.width / 2
            
            return position.y >= baseY && position.x >= baseX && position.x <= baseX + notchSize.width
        }
        
        return false
    }


    // MARK: - Sizing helpers
    
    private func calculateDynamicNotchSize() -> CGSize {
        let baseSize = Defaults[.enableMinimalMode] ? minimalOpenNotchSize : openNotchSize
        let adjustedSize = baseSize
        
        return adjustedSize
    }

    /// Override used exclusively by SwiftUI previews so the notch
    /// renders correctly on machines without a physical notch display.
    var _previewNotchHeight: CGFloat? = nil

    var effectiveClosedNotchHeight: CGFloat {
        if let preview = _previewNotchHeight { return preview }
        let currentScreen = NSScreen.screens.first { $0.localizedName == screen }
        let noNotchAndFullscreen = currentScreen?.safeAreaInsets.top ?? 0 <= 0 || currentScreen == nil
        return noNotchAndFullscreen ? 0 : closedNotchSize.height
    }

}
