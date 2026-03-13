//
//  MediaSliderView.swift
//  upper
//
//  Created by Eduardo Monteiro on 25/02/26.
//

import SwiftUI
import Defaults

struct MediaSliderView: View {
    // MARK: - Properties
    @Binding var value: Double
    @Binding var duration: Double
    @Binding var isDragging: Bool
    @Binding var lastDragged: Date
    var color: NSColor
    var currentDate: Date
    let timestampDate: Date
    let elapsedTime: Double
    let playbackRate: Double
    let isPlaying: Bool
    var labelLayout: TimeLabelLayout = .stacked
    var trailingLabel: TrailingLabel = .duration
    var onValueChange: (Double) -> Void
    var restingTrackHeight: CGFloat = 5
    var draggingTrackHeight: CGFloat = 9
    
    // MARK: - Enums
    enum TimeLabelLayout {
        case stacked
        case inline
    }
    
    enum TrailingLabel {
        case duration
        case remaining
    }
    
    var body: some View {
        Group {
            switch labelLayout {
            case .stacked:
                stackedContent
            case .inline:
                inlineContent
            }
        }
        .onChange(of: currentDate) { _, newDate in
            guard !isDragging, timestampDate.timeIntervalSince(lastDragged) > -1 else { return }
            value = MediaManager.shared.estimatedPlaybackPosition(at: newDate)
        }
        .onChange(of: isPlaying) { _, playing in
            if !playing { value = MediaManager.shared.estimatedPlaybackPosition() }
        }
    }
    
    // MARK: - Content view
    private var stackedContent: some View {
        VStack(spacing: 6) {
            sliderCore
                .frame(height: sliderFrameHeight)
            
            HStack {
                Text(timeString(from: value))
                Spacer()
                Text(trailingTimeText)
            }
            .fontWeight(.medium)
            .foregroundStyle(.gray)
            .font(.caption)
        }
    }
    
    private var inlineContent: some View {
        HStack(spacing: 10) {
            Text(timeString(from: value))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.gray)
                .frame(width: 42, alignment: .leading)
            
            sliderCore
                .frame(height: sliderFrameHeight)
                .frame(maxWidth: .infinity)
            
            Text(trailingTimeText)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.gray)
                .frame(width: 48, alignment: .trailing)
            
        }
    }
    
    private var sliderCore: some View {
        CustomSlider(
            value: $value,
            range: 0 ... duration,
            color: sliderTint,
            isDragging: $isDragging,
            lastDragged: $lastDragged,
            onValueChange: onValueChange,
            restingTrackHeight: restingTrackHeight,
            draggingTrackHeight: draggingTrackHeight
        )
        .animation(
            !isDragging && isPlaying
            ? .linear(duration: 1.0)
            : nil,
            value: value
        )
    }
    
    // MARK: - Helpers
    private var sliderFrameHeight: CGFloat {
        max(restingTrackHeight, draggingTrackHeight)
    }
    
    func timeString(from seconds: Double) -> String {
        let totalMinutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
    
    private var sliderTint: Color {
        switch Defaults[.sliderColor] {
        case .albumArt:
            return Color(nsColor: color).ensureMinimumBrightness(factor: 0.8)
        case .accent:
            return .accentColor
        case .white:
            return .white
        }
    }
    
    private var trailingTimeText: String {
        switch trailingLabel {
        case .duration:
            return timeString(from: duration)
        case .remaining:
            let remaining = max(duration - value, 0)
            return "-\(timeString(from: remaining))"
        }
    }
}

struct CustomSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var color: Color = .white
    @Binding var isDragging: Bool
    @Binding var lastDragged: Date
    var onValueChange: ((Double) -> Void)?
    var thumbSize: CGFloat = 12
    var restingTrackHeight: CGFloat = 5
    var draggingTrackHeight: CGFloat = 9
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let trackHeight = CGFloat(isDragging ? draggingTrackHeight : restingTrackHeight)
            let rangeSpan = range.upperBound - range.lowerBound
            
            let progress = rangeSpan == .zero ? 0 : (value - range.lowerBound) / rangeSpan
            let filledTrackWidth = min(1, max(0, progress)) * width
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .frame(height: trackHeight)
                
                Rectangle()
                    .fill(color)
                    .frame(width: filledTrackWidth, height: trackHeight)
            }
            .cornerRadius(trackHeight / 2)
            .frame(height: max(restingTrackHeight, draggingTrackHeight))
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        withAnimation {
                            isDragging = true
                        }
                        
                        let newValue = range.lowerBound + Double(gesture.location.x / width) * rangeSpan
                        value = min(max(newValue, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        onValueChange?(value)
                        isDragging = false
                        lastDragged = Date()
                    }
            )
            .animation(.bouncy.speed(1.4), value: isDragging)
        }
    }
}
