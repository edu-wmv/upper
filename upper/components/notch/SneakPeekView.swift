//
//  SneakPeekView.swift
//  upper
//

import SwiftUI

struct SneakPeekView: View {
    let config: SneakPeekConfig
    let currentNotchWidth: CGFloat
    let notchHeight: CGFloat

    @ObservedObject private var mediaManager = MediaManager.shared

    var body: some View {
        HStack {
            Spacer()
            contentRow
//                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            Spacer()
        }
        .frame(width: currentNotchWidth, alignment: .center)
    }

    // MARK: - Content row

    @ViewBuilder
    private var contentRow: some View {
        switch config.type {
        case .airpods:
            airpodsContent
        case .battery:
            batteryContent
        case .volume, .brightness:
            sliderContent
        case .generic:
            genericContent
        case .media:
            mediaContent
        }
    }

    // MARK: - Media (direction-aware)

    private var accentColor: Color {
        Color(nsColor: mediaManager.avgColor).ensureMinimumBrightness(factor: 0.7)
    }

    @ViewBuilder
    private var mediaContent: some View {
        switch config.direction {
        case .horizontal:
            mediaHorizontalContent
        case .vertical, .none:
            mediaVerticalContent
        }
    }

    @ViewBuilder
    private var mediaVerticalContent: some View {
         MarqueeText(
             .constant(config.title + " — " + config.subtitle),
             font: .system(size: 12, weight: .medium),
             nsFont: .caption1,
             textColor: accentColor,
             minDuration: 0.5,
             frameWidth: currentNotchWidth - 14,
             alignment: .center
         )
    }

    @ViewBuilder
    private var mediaHorizontalContent: some View {
        HStack(spacing: 5) {
            Text(config.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(accentColor)
            Text("·")
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(accentColor.opacity(0.45))
            Text(config.subtitle)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(accentColor.opacity(0.7))
        }
        .lineLimit(1)
        .truncationMode(.tail)
    }

    // MARK: - Per-type content

    @ViewBuilder
    private var airpodsContent: some View {
        HStack(spacing: 8) {
            Image(systemName: config.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(config.accentColor ?? .white.opacity(0.85))

            Text(config.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var batteryContent: some View {
        HStack(spacing: 8) {
            Image(systemName: config.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(config.accentColor ?? .green)

            Text(config.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)

            GeometryReader { geo in
                let fillWidth = geo.size.width * min(max(config.value / 100, 0), 1)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.white.opacity(0.15))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(config.accentColor ?? .green)
                        .frame(width: fillWidth)
                }
            }
            .frame(width: 32, height: 8)
        }
    }

    @ViewBuilder
    private var sliderContent: some View {
        HStack(spacing: 8) {
            Image(systemName: config.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))

            GeometryReader { geo in
                let fillWidth = geo.size.width * min(max(config.value, 0), 1)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.white.opacity(0.15))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(.white.opacity(0.7))
                        .frame(width: fillWidth)
                }
            }
            .frame(width: 80, height: 6)
        }
    }

    @ViewBuilder
    private var genericContent: some View {
        HStack(spacing: 8) {
            Image(systemName: config.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(config.accentColor ?? .white.opacity(0.85))

            Text(config.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
        }
    }
}
