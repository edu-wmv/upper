//
//  MinimalMediaView.swift
//  upper
//
//  Created by Eduardo Monteiro on 25/02/26.
//

import SwiftUI
import Defaults

struct MinimalMediaView: View {
    @EnvironmentObject var viewModel: UpperViewModel
    @ObservedObject var mediaManager = MediaManager.shared
    @State private var isHovering: Bool = false
    
    let albumArtNamespace: Namespace.ID
    
    var body: some View {
        if !mediaManager.hasActiveSession {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                
                VStack(spacing: 8) {
                    Image(systemName: "music.note.slash")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(.gray)
                    Text("Nothing Playing")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.gray)
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: calculateDynamicHeight())
        } else {
            VStack(spacing: 0) {
                GeometryReader { geo in
                    let albumArtSize: CGFloat = 50
                    let spacing: CGFloat = 10
                    let visualizerWidth: CGFloat = 24
                    let textWidth = max(0, geo.size.width - albumArtSize - spacing - (visualizerWidth + spacing))
                    
                    HStack(alignment: .center, spacing: spacing) {
                        MinimalAlbumArtView(viewModel: viewModel, albumArtNamespace: albumArtNamespace)
                            .frame(width: albumArtSize, height: albumArtSize)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            if !mediaManager.songTitle.isEmpty {
                                MarqueeText(
                                    $mediaManager.songTitle,
                                    font: .system(size: 12, weight: .semibold),
                                    nsFont: .subheadline,
                                    textColor: .white,
                                    frameWidth: textWidth
                                )
                            }
                            
                            Text(mediaManager.artistName)
                                .font(.system(size: 10, weight: .regular))
                                .foregroundStyle(.gray)
                                .lineLimit(1)
                        }
                        .frame(width: textWidth, alignment: .leading)
                        
                        MinimalVisualizer(albumArtNamespace: albumArtNamespace)
                            .frame(width: visualizerWidth)
                    }
                }
                .frame(height: 50)
                
                MinimalProgressBarView()
                    .padding(.top, 6)
                
                MinimalPlaybackControlsView()
                    .padding(.top, 4)
            }
            .padding(.horizontal, 12)
            .padding(.top, -5)
            .padding(.bottom, 3)
            .frame(maxWidth: .infinity)
            .frame(height: calculateDynamicHeight(), alignment: .top)
        }
        
    }
    
    private func calculateDynamicHeight() -> CGFloat {
        var height: CGFloat = 50
        
        height += 6 + 4 // Progress bar + top padding
        height += 40 + 2 // Controls + top padding
        height += 15 // top padding
        
        return height
    }
    
}

struct MinimalProgressBarView: View {
    @ObservedObject var mediaManager = MediaManager.shared
    @State private var sliderValue: Double = MediaManager.shared.estimatedPlaybackPosition()
    @State private var duration: Double = 200
    @State private var isDragging: Bool = false
    @State private var lastDragged: Date = .distantPast
    
    private var isProgressTimelinePaused: Bool {
        !mediaManager.isPlaying || mediaManager.playbackRate <= 0
    }
    
    var body: some View {
        TimelineView(
            .animation(minimumInterval: 0.1, paused: isProgressTimelinePaused)
        ) { timeline in
            MediaSliderView(
                value: $sliderValue,
                duration: Binding(
                    get: { mediaManager.songDuration },
                    set: { mediaManager.songDuration = $0 }
                ),
                isDragging: $isDragging,
                lastDragged: $lastDragged,
                color: mediaManager.avgColor,
                currentDate: timeline.date,
                timestampDate: mediaManager.timestampDate,
                elapsedTime: mediaManager.elapsedTime,
                playbackRate: mediaManager.playbackRate,
                isPlaying: mediaManager.isPlaying,
                labelLayout: .inline,
                trailingLabel: .remaining,
                onValueChange: { newValue in mediaManager.seek(to: newValue) },
                restingTrackHeight: 7,
                draggingTrackHeight: 11
            )
        }
    }
}

struct MinimalVisualizer: View {
    @ObservedObject var mediaManager = MediaManager.shared
    let albumArtNamespace: Namespace.ID
    
    var body: some View {
        Rectangle()
            .fill(Color(nsColor: mediaManager.avgColor).gradient)
            .mask {
                AudioSpectrumView(isPlaying: .constant(mediaManager.isPlaying))
                    .frame(width: 20, height: 16)
            }
            .frame(width: 20, height: 16)
            .matchedGeometryEffect(id: "spectrum", in: albumArtNamespace)
    }
}

struct MinimalAlbumArtView: View {
    @ObservedObject var mediaManager = MediaManager.shared
    @ObservedObject var viewModel: UpperViewModel
    let albumArtNamespace: Namespace.ID
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .background(
                    Image(nsImage: mediaManager.albumArt)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                )
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .scaleEffect(x: 2.5, y: 2.4)
                .rotationEffect(.degrees(45))
                .blur(radius: 35)
                .opacity(min(0.6, 1 - max(mediaManager.albumArt.getBrightness(), 0.3)))
            
            Button {
                mediaManager.openMediaApp()
            } label: {
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .background(
                        Image(nsImage: mediaManager.albumArt)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    )
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .matchedGeometryEffect(id: "albumArt", in: albumArtNamespace)
                    .albumArtFlip(angle: mediaManager.flipAngle, direction: mediaManager.flipDirection)
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(mediaManager.isPlaying ? 1 : 0.4)
            .scaleEffect(mediaManager.isPlaying ? 1 : 0.85)
            .focusable(false)
        }
    }
}

struct MinimalPlaybackControlsView: View {
//    @Default(.mediaControlSlots) private var slotConfig
    private var slotConfig = MediaControlButton.minimalLayout
    @ObservedObject var mediaManager = MediaManager.shared
    
    private let skipMagnitude: CGFloat = 8
    
    var body: some View {
        HStack(spacing: 16) {
            
            ForEach(Array(displayedSlots.enumerated()), id: \.offset) { _, slot in
                slotView(for: slot)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 2)
    }
    
    private var displayedSlots: [MediaControlButton] {
        let normalized = slotConfig.normalized(allowingMediaOutput: true)
        return normalized.contains(where: { $0 != .none }) ? normalized : MediaControlButton.defaultLayout
    }
    
    @ViewBuilder
    private func slotView(for control: MediaControlButton) -> some View {
        switch control {
        case .favorite:
            controlButton(
                icon: mediaManager.isFavorite ? "star.fill" : "star",
                size: 18,
                isActive: mediaManager.isFavorite,
                activeColor: Color(red: 1.0, green: 0.75, blue: 0.0),
                pressEffect: .wiggle(.clockwise),
                symbolEffect: .replaceAndBounce,
                action: { mediaManager.toggleFavorite() }
            )
            .opacity(mediaManager.supportsFavorite ? 1.0 : 0.3)
            .allowsHitTesting(mediaManager.supportsFavorite)
        case .shuffle:
            controlButton(icon: "shuffle", isActive: mediaManager.isShuffled) {
                Task { await mediaManager.toggleShuffle() }
            }
        case .backward:
            controlButton(
                icon: "backward.fill",
                size: 18,
                pressEffect: .nudge(-skipMagnitude),
                symbolEffect: .replace,
                trigger: skipGestureTrigger(for: .backward),
                action: { mediaManager.previous() }
            )
        case .playPause:
            MinimalSquircleButton(
                icon: mediaManager.isPlaying ? "pause.fill" : "play.fill",
                fontSize: 28,
                fontWeidth: .semibold,
                frameSize: CGSize(width: 50, height: 50),
                cornerRadius: 22,
                foregroundColor: .white,
                pressEffect: .none,
                symbolEffectStyle: .replace,
                action: { mediaManager.togglePlay() }
            )
        case .forward:
            controlButton(
                icon: "forward.fill",
                size: 18,
                pressEffect: .nudge(skipMagnitude),
                symbolEffect: .replace,
                trigger: skipGestureTrigger(for: .backward),
                action: { mediaManager.next() }
            )
        case .output:
            MinimalMediaOutputButton()
        case .repeatMode:
            controlButton(icon: repeatIcon, isActive: mediaManager.repeatMode != .off, symbolEffect: .replace) {
                Task { await mediaManager.toggleRepeat() }
            }
        case .none:
            Spacer(minLength: 0)
        }
    }
    
    private struct SkipTrigger {
        let token: Int
        let pressEffect: MinimalSquircleButton.PressEffect
    }
    
    private func skipGestureTrigger(for control: MediaControlButton) -> SkipTrigger? {
        guard let pulse = mediaManager.skipGesturePulse else { return nil }
        
        switch control {
        case .backward where pulse.behavior == .track && pulse.direction == .backward:
            return SkipTrigger(token: pulse.token, pressEffect: .nudge(-skipMagnitude))
        case .forward where pulse.behavior == .track && pulse.direction == .forward:
            return SkipTrigger(token: pulse.token, pressEffect: .nudge(skipMagnitude))
        default:
            return nil
        }
    }
    
    private func controlButton(
        icon: String,
        size: CGFloat = 18,
        isActive: Bool = false,
        activeColor: Color? = nil,
        pressEffect: MinimalSquircleButton.PressEffect = .none,
        symbolEffect: MinimalSquircleButton.SymbolEffectStyle = .none,
        trigger: SkipTrigger? = nil,
        action: @escaping () -> Void
    ) -> some View {
        let resolvedActiveColor: Color = activeColor ?? .red
        return MinimalSquircleButton(
            icon: icon,
            fontSize: size,
            fontWeidth: .medium,
            frameSize: CGSize(width: 40, height: 40),
            cornerRadius: 16,
            foregroundColor: isActive ? resolvedActiveColor : .white.opacity(0.85),
            pressEffect: pressEffect,
            symbolEffectStyle: symbolEffect,
            externalTriggerToken: trigger?.token,
            externalTriggerEffect: trigger?.pressEffect,
            action: action
        )
    }
    
    private var repeatIcon: String {
        switch mediaManager.repeatMode {
        case .off: return "repeat"
        case .one: return "repeat.1"
        case .all: return "repeat"
        }
    }
    
    private struct MinimalMediaOutputButton: View {
        @ObservedObject private var routeManager = AudioRouteManager.shared
        @StateObject private var volumeModel = MediaOutputVolumeViewModel()
        @EnvironmentObject private var viewModel: UpperViewModel
        @State private var isPopoverPresented = false
        @State private var isHoveringPopover = false
        
        var body: some View {
            MinimalSquircleButton(
                icon: routeManager.activeDevice?.iconName ?? "speaker.wave.2",
                fontSize: 18,
                fontWeidth: .medium,
                frameSize: CGSize(width: 40, height: 30),
                cornerRadius: 16,
                foregroundColor: .white.opacity(0.85),
                symbolEffectStyle: .replace
            ) {
                isPopoverPresented.toggle()
                if isPopoverPresented { routeManager.refreshDevices() }
            }
            .accessibilityLabel("Media output")
            .popover(isPresented: $isPopoverPresented, arrowEdge: .bottom) {
                MediaOutputSelectorPopover(
                    routeManager: routeManager,
                    volumeModel: volumeModel,
                    onHoverChanged: { hovering in
                        isHoveringPopover = hovering
                        updateActivity()
                    }
                ) {
                    isPopoverPresented = false
                    isHoveringPopover = false
                    updateActivity()
                }
            }
            .onChange(of: isPopoverPresented) { _, presented in
                if !presented { isHoveringPopover = false }
                updateActivity()
            }
            .onAppear {
                routeManager.refreshDevices()
            }
            .onDisappear {
                viewModel.isMediaOutputPopoverActive = false
            }
        }
        
        private func updateActivity() {
            viewModel.isMediaOutputPopoverActive = isPopoverPresented && isHoveringPopover
        }
    }
}

private struct MinimalSquircleButton: View {
    let icon: String
    let fontSize: CGFloat
    let fontWeigth: Font.Weight
    let frameSize: CGSize
    let cornerRadius: CGFloat
    let foregroundColor: Color
    let pressEffect: PressEffect
    let symbolEffectStyle: SymbolEffectStyle
    let externalTriggerToken: Int?
    let externalTriggerEffect: PressEffect?
    let action: () -> Void
    
    @State private var isHovering = false
    @State private var pressOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0
    @State private var wiggleToken: Int = 0
    @State private var lastExternalTriggerToken: Int?
    
    init(
        icon: String,
        fontSize: CGFloat,
        fontWeidth: Font.Weight,
        frameSize: CGSize,
        cornerRadius: CGFloat,
        foregroundColor: Color,
        pressEffect: PressEffect = .none,
        symbolEffectStyle: SymbolEffectStyle = .none,
        externalTriggerToken: Int? = nil,
        externalTriggerEffect: PressEffect? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.fontSize = fontSize
        self.fontWeigth = fontWeidth
        self.frameSize = frameSize
        self.cornerRadius = cornerRadius
        self.foregroundColor = foregroundColor
        self.pressEffect = pressEffect
        self.symbolEffectStyle = symbolEffectStyle
        self.externalTriggerToken = externalTriggerToken
        self.externalTriggerEffect = externalTriggerEffect
        self.action = action
    }
    
    var body: some View {
        Button {
            triggerPressEffect()
            action()
        } label: {
            iconView()
                .frame(width: frameSize.width, height: frameSize.height)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(isHovering ? Color.white.opacity(0.18) : .clear)
                )
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
        .focusable(false)
        .offset(x: pressOffset)
        .rotationEffect(.degrees(rotationAngle))
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.18)) { isHovering = hovering }
        }
        .onChange(of: externalTriggerToken) { _, newToken in
            guard let newToken, newToken != lastExternalTriggerToken else { return }
            lastExternalTriggerToken = newToken
            triggerPressEffect(override: externalTriggerEffect)
                
        }
    }
    
    private func triggerPressEffect(override: PressEffect? = nil) {
        let effect = override ?? pressEffect
        
        switch effect {
        case .none:
            return
        case .nudge(let amount):
            withAnimation(.spring(response: 0.16, dampingFraction: 0.72)) {
                pressOffset = amount
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.26, dampingFraction: 0.8)) {
                    pressOffset = 0
                }
            }
        case .wiggle(let direction):
            guard #available(macOS 14.0, *) else { return }
            
            wiggleToken += 1
            let angle: Double = direction == .clockwise ? 11 : -11
            
            withAnimation(.spring(response: 0.18, dampingFraction: 0.52)) {
                rotationAngle = angle
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
                    rotationAngle = 0
                }
            }
        }
    }
    
    @ViewBuilder
    private func iconView() -> some View {
        let image = Image(systemName: icon)
            .font(.system(size: fontSize, weight: fontWeigth))
            .foregroundColor(foregroundColor)
        
        switch symbolEffectStyle {
        case .none:
            image
        case .replace:
            if #available(macOS 14.0, *) {
                image.contentTransition(.symbolEffect(.replace))
            } else {
                image
            }
        case .bounce:
            if #available(macOS 14.0, *) {
                image.symbolEffect(.bounce, value: icon)
            } else {
                image
            }
        case .replaceAndBounce:
            if #available(macOS 14.0, *) {
                image
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: icon)
            } else {
                image
            }
        case .wiggle:
            if #available(macOS 15.0, *) {
                image.symbolEffect(
                    .wiggle.byLayer,
                    options: .nonRepeating,
                    value: wiggleToken
                )
            } else {
                image
            }
        }
    }
    
    enum PressEffect {
        case none
        case nudge(CGFloat)
        case wiggle(WiggleDirection)
    }
    
    enum SymbolEffectStyle {
        case none
        case replace
        case bounce
        case replaceAndBounce
        case wiggle
    }
    
    enum WiggleDirection {
        case clockwise
        case counterClockwise
    }
}

#Preview("Minimal Mode Media View") {
    MinimalMediaView(albumArtNamespace: Namespace().wrappedValue)
        .environmentObject(UpperViewModel())
        .frame(width: 300)
}
