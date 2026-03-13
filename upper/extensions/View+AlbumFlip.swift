//
//  View+AlbumFlip.swift
//  upper
//
//  Created by Eduardo Monteiro on 04/03/26.
//

import SwiftUI

private struct AlbumArtFlipModifier: ViewModifier {
    let angle: Double
    let direction: SkipDirection
    
    private var normalizedAngle: Double {
        var value = angle.truncatingRemainder(dividingBy: 360)
        if value < 0 { value += 360 }
        return value
    }
    
    private var mirrorScale: CGFloat {
        (normalizedAngle > 90 && normalizedAngle < 270) ? -1 : 1
    }
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(angle),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.65
            )
            .scaleEffect(x: mirrorScale, y: 1)
    }
}

extension View {
    func albumArtFlip(angle: Double, direction: SkipDirection = .forward) -> some View {
        modifier(AlbumArtFlipModifier(angle: angle, direction: direction))
    }
}
