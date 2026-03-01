//
//  MediaSliderView.swift
//  upper
//
//  Created by Eduardo Monteiro on 25/02/26.
//

import SwiftUI

struct MediaSliderView: View {
    @Binding var value: Double
    @Binding var duration: Double
    @Binding var isDragging: Bool
    @Binding var lastDragged: Date
    var restingTrackHeight: CGFloat = 5
    var draggingTrackHeight: CGFloat = 9
    
    var body: some View {
        Group {
            inlineContent
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
            
            Text("-\(timeString(from: max(duration - value, 0)))")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.gray)
                .frame(width: 48, alignment: .trailing)
                
        }
    }
    
    private var sliderFrameHeight: CGFloat {
        max(restingTrackHeight, draggingTrackHeight)
    }
    
    private var sliderCore: some View {
        CustomSlider(
            value: $value,
            range: 0 ... duration,
            isDragging: $isDragging,
            lastDragged: $lastDragged,
            restingTrackHeight: restingTrackHeight,
            draggingTrackHeight: draggingTrackHeight
        )
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
