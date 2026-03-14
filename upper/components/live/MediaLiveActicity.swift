//
//  MediaLiveActicity.swift
//  upper
//
//  Created by Eduardo Monteiro on 13/03/26.
//

import SwiftUI

struct MediaLiveActicity: View {
    let isHovering: Bool
    let gestureProgress: CGFloat
    var albumArtNamespace: Namespace.ID

    @ObservedObject var viewModel: UpperViewModel
    @ObservedObject private var mediaManager = MediaManager.shared
    @ObservedObject private var coordinator = UpperViewCoordinator.shared

    // MARK: - Sizing

    private var wingBaseWidth: CGFloat {
        max(0, viewModel.effectiveClosedNotchHeight - (isHovering ? 0 : 12) + gestureProgress / 2)
    }

    private var notchContentHeight: CGFloat {
        max(0, viewModel.effectiveClosedNotchHeight - (isHovering ? 0 : 12))
    }

    private var centerBaseWidth: CGFloat {
        viewModel.closedNotchSize.width + (isHovering ? 8 : 0)
    }

    private var effectiveCenterWidth: CGFloat {
        isExpanding ? 380 : centerBaseWidth
    }

    private var isExpanding: Bool {
        !coordinator.musicExpandingTitle.isEmpty
    }

    private var accentColor: Color {
        Color(nsColor: mediaManager.avgColor).ensureMinimumBrightness(factor: 0.7)
    }

    // MARK: - Body

    var body: some View {
        Group {
            if mediaManager.hasActiveSession {
                liveActivityContent
            } else {
                Rectangle()
                    .fill(.clear)
                    .frame(
                        width: viewModel.closedNotchSize.width - 20,
                        height: viewModel.effectiveClosedNotchHeight
                    )
            }
        }
        .animation(.smooth(duration: 0.25), value: isExpanding)
        .animation(.smooth(duration: 0.2), value: isHovering)
    }

    // MARK: - Live Activity

    @ViewBuilder
    private var liveActivityContent: some View {
        HStack(spacing: 0) {
            leftWing
                .frame(width: wingBaseWidth, height: notchContentHeight)

            centerZone
                .frame(width: effectiveCenterWidth, height: notchContentHeight)

            rightWing
                .frame(width: wingBaseWidth, height: notchContentHeight)
        }
        .frame(height: viewModel.effectiveClosedNotchHeight + (isHovering ? 8 : 0))
    }

    // MARK: - Left wing (album art)

    @ViewBuilder
    private var leftWing: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .background(
                    Image(nsImage: mediaManager.albumArt)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                )
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: MediaPlayerImageSizes.cornerRadiusInset.closed))
                .matchedGeometryEffect(id: "albumArt", in: albumArtNamespace)
                .albumArtFlip(angle: mediaManager.flipAngle, direction: mediaManager.flipDirection)
        }
    }

    // MARK: - Center (hardware notch + optional expanding text)

    @ViewBuilder
    private var centerZone: some View {
        Rectangle()
            .fill(.black)
            .overlay(
                HStack(alignment: .center, spacing: 0) {
                    if isExpanding {
                        GeometryReader { _ in
                            MarqueeText(
                                .constant(coordinator.musicExpandingTitle),
                                font: .system(size: 11, weight: .medium),
                                nsFont: .caption1,
                                textColor: accentColor,
                                minDuration: 0.4,
                                frameWidth: max(0, (effectiveCenterWidth - viewModel.closedNotchSize.width) / 2 - 12)
                            )
                        }
                        .padding(.leading, 8)
                        .opacity(isExpanding ? 1 : 0)
                    }

                    Spacer(minLength: viewModel.closedNotchSize.width)

                    if isExpanding {
                        Text(coordinator.musicExpandingArtist)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(accentColor.opacity(0.8))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .padding(.trailing, 8)
                            .opacity(isExpanding ? 1 : 0)
                    }
                }
                .clipped()
            )
    }

    // MARK: - Right wing (spectrum)

    @ViewBuilder
    private var rightWing: some View {
        Rectangle()
            .fill(Color(nsColor: mediaManager.avgColor).gradient)
            .mask {
                AudioSpectrumView(isPlaying: .constant(mediaManager.isPlaying))
                    .frame(width: 16, height: 12)
            }
            .matchedGeometryEffect(id: "spectrum", in: albumArtNamespace)
    }
}

private func makePreviewViewModel(notchHeight: CGFloat = 38) -> UpperViewModel {
    let vm = UpperViewModel()
    vm.closedNotchSize = CGSize(width: 180, height: notchHeight)
    vm._previewNotchHeight = notchHeight
    return vm
}

#Preview("Live Activity – Playing") {
    let vm = makePreviewViewModel()
    return MediaLiveActicity(
        isHovering: false,
        gestureProgress: 0,
        albumArtNamespace: Namespace().wrappedValue,
        viewModel: vm
    )
    .background(.black)
    .frame(width: 420, height: 60)
    .onAppear {
        MediaManager.shared.songTitle = "Lover of Mine"
        MediaManager.shared.artistName = "5 Seconds of Summer"
        MediaManager.shared.isPlaying = true
        MediaManager.shared.isPlayerIdle = false
        MediaManager.shared.avgColor = NSColor.systemPurple
    }
}

#Preview("Live Activity – Expanding") {
    let vm = makePreviewViewModel()
    return MediaLiveActicity(
        isHovering: false,
        gestureProgress: 0,
        albumArtNamespace: Namespace().wrappedValue,
        viewModel: vm
    )
    .background(.black)
    .frame(width: 460, height: 60)
    .onAppear {
        MediaManager.shared.songTitle = "Lover of Mine"
        MediaManager.shared.artistName = "5 Seconds of Summer"
        MediaManager.shared.isPlaying = true
        MediaManager.shared.isPlayerIdle = false
        MediaManager.shared.avgColor = NSColor.systemPurple
        UpperViewCoordinator.shared.musicExpandingTitle = "Lover of Mine"
        UpperViewCoordinator.shared.musicExpandingArtist = "5 Seconds of Summer"
    }
}

#Preview("Live Activity – Hovering") {
    let vm = makePreviewViewModel()
    return MediaLiveActicity(
        isHovering: true,
        gestureProgress: 0,
        albumArtNamespace: Namespace().wrappedValue,
        viewModel: vm
    )
    .background(.black)
    .frame(width: 420, height: 60)
    .onAppear {
        MediaManager.shared.songTitle = "Lover of Mine"
        MediaManager.shared.artistName = "5 Seconds of Summer"
        MediaManager.shared.isPlaying = true
        MediaManager.shared.isPlayerIdle = false
        MediaManager.shared.avgColor = NSColor.systemBlue
    }
}
