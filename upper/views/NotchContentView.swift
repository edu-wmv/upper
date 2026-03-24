//
//  NotchContentView.swift
//  upper
//
//  Created by Eduardo Monteiro on 24/02/26.
//

import SwiftUI
import Defaults

@MainActor
struct NotchContentView: View {
    @EnvironmentObject var viewModel: UpperViewModel
    
    @ObservedObject var coordinator = UpperViewCoordinator.shared
    @ObservedObject var mediaManager = MediaManager.shared
    @ObservedObject var welcome = WelcomeExperience.shared
    
    @State private var gestureProgress: CGFloat = .zero
    @State private var hoverTask: Task<Void, Never>?
    @State private var isHovering: Bool = false
    @State private var hoverClickMonitor: Any?
    
    @State private var haptics: Bool = false
    @State private var lastHapticTime: Date = Date()
    
    @Namespace var albumArtNamespace
    
    @Default(.enableMinimalMode) var enableMinimalMode

    // MARK: - Pre-computed values
    
    var dynamicNotchSize: CGSize {
        let baseSize = enableMinimalMode ? minimalOpenNotchSize : openNotchSize
        if isWelcomeTarget && viewModel.state == .open {
            let headerHeight = max(32, viewModel.effectiveClosedNotchHeight)
            let verticalPadding: CGFloat = 12 + 12 + 6
            let needed = headerHeight + welcome.contentHeight + verticalPadding
            return CGSize(width: baseSize.width, height: max(baseSize.height, needed))
        }
        return baseSize
    }

    private var sneakPeekWidth: CGFloat {
        if viewModel.state == .sneakPeek, viewModel.activeSneakPeek?.type == .media {
            let wingWidth = max(0, viewModel.effectiveClosedNotchHeight - (isHovering ? 0 : 12) + gestureProgress / 2)
            return viewModel.closedNotchSize.width + wingWidth * 2
        }

        return viewModel.closedNotchSize.width
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            notchBody
                .environmentObject(viewModel)
                .frame(
                    maxWidth: dynamicNotchSize.width,
                    maxHeight: dynamicNotchSize.height,
                    alignment: .top
                )
                .onChange(of: dynamicNotchSize) { oldSize, newSize in
                    guard oldSize != newSize else { return }
                    if isWelcomeTarget && welcome.phase == .narrating {
                        withAnimation(.smooth(duration: 0.35)) {
                            viewModel.notchSize = newSize
                        }
                        AppDelegate.shared?.ensureWindowSize(
                            addShadowPadding(to: newSize, isMinimal: enableMinimalMode),
                            animated: true,
                            force: true
                        )
                    }
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(100))
                        viewModel.shouldRecheckHover.toggle()
                    }
                }
                .onDisappear {
                    hoverTask?.cancel()
                    stopHoverClickMonitor()
                }
        }
    }
    
    // MARK: - Notch body
    
    @ViewBuilder
    private var notchBody: some View {
        let notchHorizontalPadding: CGFloat = {
            switch viewModel.state {
            case .open:
                if Defaults[.cornerRadiusScaling] {
                    return activeCornerRadiusInset.opened.top - 5
                }
                return activeCornerRadiusInset.opened.bottom - 5
            case .sneakPeek:
                return sneakPeekCornerRadiusInsets.bottom
            default:
                return activeCornerRadiusInset.closed.bottom
            }
        }()
        
        
        let mainLayout = NotchLayout()
            .frame(alignment: .top)
            .padding(.horizontal, notchHorizontalPadding)
            .padding([.horizontal, .bottom], viewModel.state == .open ? 12 : 0)
            .background(.black)
            .clipShape(currentShape)
            .compositingGroup()
            .shadow(
                color: (viewModel.state == .open || viewModel.state == .sneakPeek || isHovering)
                ? .black.opacity(0.6)
                : .clear,
                radius: Defaults[.cornerRadiusScaling] ? 10 : 5
            )
            .padding(.bottom, 6)
        
        mainLayout
            .conditionalModifier(true) { view in // Placeholder for interactions disp
                view
                    .contentShape(currentShape)
                    .onHover { hovering in
                        guard !isWelcomeTarget else { return }
                        handleHover(hovering)
                    }
                    .onTapGesture {
                        guard !isWelcomeTarget else { return }
                        if canHoverOpen && Defaults[.enableHaptics] {
                            triggerHaptic()
                        }
                        viewModel.open()
                    }
            }
            .onChange(of: viewModel.state) { _, newState in
                if newState == .closed && isHovering {
                    withAnimation { isHovering = false }
                }
            }
            .sensoryFeedback(.alignment, trigger: haptics)
    }
    
    @ViewBuilder
    func NotchLayout() -> some View {
        let hasMediaMetadata = !mediaManager.songTitle.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty
                            || !mediaManager.artistName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty
        let hasMediaSnapshot: Bool = {
            if mediaManager.isPlaying { return true }
            return !mediaManager.isPlayerIdle && hasMediaMetadata
        }()
        let isMediaEligible = (viewModel.state == .closed || viewModel.state == .sneakPeek) && hasMediaSnapshot
        
        VStack(alignment: .leading, spacing: 0) {
            Group {
               if isWelcomeTarget && viewModel.state == .open {
                    Rectangle()
                        .fill(.clear)
                        .frame(height: max(32, viewModel.effectiveClosedNotchHeight))
               } else if viewModel.state == .open {
                    UpperHeaderView()
                        .frame(height: max(32, viewModel.effectiveClosedNotchHeight))
                } else if isMediaEligible {
                     MediaLiveActicity(
                         isHovering: isHovering,
                         gestureProgress: gestureProgress,
                         albumArtNamespace: albumArtNamespace,
                         viewModel: viewModel
                     )
                } else {
                    Rectangle()
                        .fill(.clear)
                        .frame(
                            width: viewModel.closedNotchSize.width - 20,
                            height: viewModel.effectiveClosedNotchHeight
                        )
                }
            }
            .zIndex(2)

            ZStack {
                if isWelcomeTarget && viewModel.state == .open && welcome.phase != .notchClosing {
                    WelcomeNarrationView()
                        .transition(.opacity)
                } else if viewModel.state == .open {
                    Group {
                        switch coordinator.currentView {
                        case .home:
                            UpperHomeView(albumArtNamespace: albumArtNamespace)
                        case .shelf:
                            EmptyView()
                        case .sharing:
                            EmptyView()
                        }
                    }
                    .id(coordinator.currentView)
                } else if viewModel.state == .sneakPeek, let config = viewModel.activeSneakPeek {
                    SneakPeekView(
                        config: config,
                        currentNotchWidth: sneakPeekWidth,
                        notchHeight: 0
                    )
                    .transition(
                        .move(edge: .top)
                        .combined(with: .blurReplace)
                    )
                    .animation(.bouncy, value: viewModel.activeSneakPeek)
                }
            }
            .zIndex(1)
        }
    }

    private func hasAnyActivePopovers() -> Bool {
        return viewModel.isMediaOutputPopoverActive
    }
    
    private var isWelcomeTarget: Bool {
        welcome.isTarget(viewModel)
    }

    private func shouldPreventAutoClose() -> Bool {
        isWelcomeTarget || hasAnyActivePopovers()
    }
    
    // MARK: - Shape
    
    private var activeCornerRadiusInset: (opened: (top: CGFloat, bottom: CGFloat), closed: (top: CGFloat, bottom: CGFloat)) {
        if enableMinimalMode {
            return (opened: minimalCornerRadiusInsets.opened, closed: minimalCornerRadiusInsets.closed)
        }
        
        return cornerRadiusInsets
    }
    
    private var currentShape: NotchShape {
        let topRadius: CGFloat
        let bottomRadius: CGFloat
        
        switch viewModel.state {
        case .open where Defaults[.cornerRadiusScaling]:
            topRadius = activeCornerRadiusInset.opened.top
            bottomRadius = activeCornerRadiusInset.opened.bottom
        case .sneakPeek:
            topRadius = sneakPeekCornerRadiusInsets.top
            bottomRadius = sneakPeekCornerRadiusInsets.bottom
        default:
            topRadius = activeCornerRadiusInset.closed.top
            bottomRadius = activeCornerRadiusInset.closed.bottom
        }
        
        return NotchShape(topRadius: topRadius, bottomRadius: bottomRadius)
    }
    
    // MARK: - Hover
    
    private var canHoverOpen: Bool {
        viewModel.state == .closed || viewModel.state == .sneakPeek
    }
    
    private func handleHover(_ hovering: Bool) {
        hoverTask?.cancel()
        
        if hovering {
            startHoverClickMonitor()
        } else {
            stopHoverClickMonitor()
        }
        
        if hovering {
            withAnimation(.smooth.speed(1.2)) {
                isHovering = true
            }
            
            if canHoverOpen && Defaults[.enableHaptics] {
                triggerHaptic()
            }
            
            guard canHoverOpen else { return }
            
            hoverTask = Task {
                try? await Task.sleep(for: .seconds(0.35))
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    guard self.canHoverOpen,
                          self.isHovering else { return }
                    
                    self.viewModel.open()
                }
            }
        } else {
            hoverTask = Task {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    withAnimation(.smooth) {
                        self.isHovering = false
                    }
                    
                    if self.viewModel.state == .open && !self.shouldPreventAutoClose() {
                        self.viewModel.close()
                    }
                }
                
            }
        }
    }
    
    private func startHoverClickMonitor() {
        guard hoverClickMonitor == nil else { return }
        hoverClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { _ in
            Task { @MainActor in
                guard canHoverOpen,
                      isHovering else { return }
                
                if Defaults[.enableHaptics] { triggerHaptic() }
                
                viewModel.open()
            }
        }
    }
    
    private func stopHoverClickMonitor() {
        if let hoverClickMonitor {
            NSEvent.removeMonitor(hoverClickMonitor)
            self.hoverClickMonitor = nil
        }
    }
    
    private func triggerHaptic() {
        let now = Date()
        if now.timeIntervalSince(lastHapticTime) > 0.3 {
            haptics.toggle()
            lastHapticTime = now
        }
    }
}

private func makeNotchPreviewViewModel() -> UpperViewModel {
    let vm = UpperViewModel()
    vm.closedNotchSize = CGSize(width: 180, height: 38)
    vm._previewNotchHeight = 38
    return vm
}

#Preview("Notch – Closed") {
    let vm = makeNotchPreviewViewModel()
    return NotchContentView()
        .environmentObject(vm)
        .frame(width: 600, height: 200)
        .background(.black.opacity(0.3))
}

#Preview("Notch – Open") {
    let vm = makeNotchPreviewViewModel()
    return NotchContentView()
        .environmentObject(vm)
        .frame(width: 640, height: 220)
        .background(.black.opacity(0.3))
        .onAppear {
            vm.open()
        }
}
