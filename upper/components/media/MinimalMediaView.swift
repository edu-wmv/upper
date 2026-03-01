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
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let albumArtSize: CGFloat = 50
                let spacing: CGFloat = 10
                let textWidth = max(0, geo.size.width - albumArtSize - spacing - 34)
                
                HStack(alignment: .center, spacing: spacing) {
                    RoundedRectangle(cornerRadius: 12)
                        .frame(width: albumArtSize, height: albumArtSize)
                    
                    VStack(alignment: .leading) {
                        Text("Song Title")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text("Artist Name")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(width: textWidth, alignment: .leading)
                }
            }
            .frame(height: 50)
            
            progressBar
                .padding(.top, 6)
        }
        .padding(.horizontal, 12)
        .padding(.top, -15)
        .frame(maxWidth: .infinity)
        .frame(height: 117, alignment: .bottom)
    }
    
    @State private var sliderValue: Double = 0
    @State private var duration: Double = 200
    @State private var isDragging: Bool = false
    @State private var lastDragged: Date = .distantPast
    
    private var progressBar: some View {
        TimelineView(
            .animation(minimumInterval: 0.1)
        ) { timeline in
            MediaSliderView(
                value: $sliderValue,
                duration: $duration,
                isDragging: $isDragging,
                lastDragged: $lastDragged
            )
        }
    }
        
    
}

#Preview {
    MinimalMediaView()
        .environmentObject(UpperViewModel())
}
