//
//  NotchShape.swift
//  upper
//
//  Created by Eduardo Monteiro on 24/02/26.
//

import SwiftUI

struct NotchShape: Shape {
    var topCornerRadius: CGFloat
    var bottomCornerRadius: CGFloat

    init(topRadius: CGFloat = 6, bottomRadius: CGFloat = 10) {
        self.topCornerRadius = topRadius
        self.bottomCornerRadius = bottomRadius
    }

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { .init(topCornerRadius, bottomCornerRadius) }
        set {
            topCornerRadius = newValue.first
            bottomCornerRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let top = topCornerRadius
        let bot = bottomCornerRadius

        // Start at top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))

        // Top-left inner curve
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + top, y: top),
            control: CGPoint(x: rect.minX + top, y: rect.minY)
        )

        // Left vertical edge
        path.addLine(to: CGPoint(x: rect.minX + top, y: rect.maxY - bot))

        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + top + bot, y: rect.maxY),
            control: CGPoint(x: rect.minX + top, y: rect.maxY)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: rect.maxX - top - bot, y: rect.maxY))

        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - top, y: rect.maxY - bot),
            control: CGPoint(x: rect.maxX - top, y: rect.maxY)
        )

        // Right vertical edge
        path.addLine(to: CGPoint(x: rect.maxX - top, y: top))

        // Top-right inner curve
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.maxX - top, y: rect.minY)
        )

        // Top edge back to start
        path.closeSubpath()

        return path
    }
}
