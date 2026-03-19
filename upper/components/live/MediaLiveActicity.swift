//
//  MediaLiveActicity.swift
//  upper
//
//  Created by Eduardo Monteiro on 13/03/26.
//

import SwiftUI
import Defaults

struct MediaLiveActicity: View {
    let isHovering: Bool
    let gestureProgress: CGFloat
    var albumArtNamespace: Namespace.ID

    @ObservedObject var viewModel: UpperViewModel
    @ObservedObject private var mediaManager = MediaManager.shared

    // MARK: - Sizing

    private var wingBaseWidth: CGFloat {
        max(0, viewModel.effectiveClosedNotchHeight - (isHovering ? 0 : 12) + gestureProgress / 2)
    }

    private var notchContentHeight: CGFloat {
        max(0, viewModel.effectiveClosedNotchHeight - (isHovering ? 0 : 12))
    }

    private var centerBaseWidth: CGFloat {
        max(96, (viewModel.closedNotchSize.width + (isHovering ? 8 : 0)))
    }

    // MARK: - Body

    var body: some View {
        Group {
            if !mediaManager.isPlayerIdle {
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
        .animation(.smooth(duration: 0.2), value: isHovering)
    }

    // MARK: - Live Activity

    @ViewBuilder
    private var liveActivityContent: some View {
        HStack(spacing: 0) {
            leftWing
                .frame(width: wingBaseWidth, height: notchContentHeight)

            Rectangle()
                .fill(.black)
                .frame(width: centerBaseWidth, height: notchContentHeight)

            rightWing
                .frame(width: wingBaseWidth, height: notchContentHeight)
        }
        .frame(height: viewModel.effectiveClosedNotchHeight + (isHovering ? 2 : 0))
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
                .clipShape(
                    RoundedRectangle(cornerRadius: MediaPlayerImageSizes.cornerRadiusInset.closed)
                )
                .matchedGeometryEffect(id: "albumArt", in: albumArtNamespace)
                .albumArtFlip(angle: mediaManager.flipAngle, direction: mediaManager.flipDirection)
        }
        .padding(isHovering ? 6 : 0)
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

#Preview("Media Live Activity") {
    @Previewable @State var hovering: Bool = false
    let vm = makePreviewViewModel()
    
    MediaLiveActicity(
        isHovering: hovering,
        gestureProgress: 0,
        albumArtNamespace: Namespace().wrappedValue,
        viewModel: vm
    )
    .background(.black)
    .frame(width: 500, height: 60)
    .onHover { isHovering in
        hovering = isHovering
    }
}
