//
//  SneakPeekView.swift
//  upper
//

import SwiftUI

struct SneakPeekView: View {
    let config: SneakPeekConfig
    let closedNotchWidth: CGFloat
    let notchHeight: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.clear)
                .frame(width: closedNotchWidth - 20, height: notchHeight)

            contentRow
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
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
        }
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
