//
//  WelcomeOverlayView.swift
//  upper
//
//  Fullscreen overlay for the first-launch welcome sequence.
//  Renders a dim layer and an expanding radial burst shader
//  anchored at top-center (the notch position).
//

import SwiftUI

struct WelcomeOverlayView: View {
    @ObservedObject var welcome = WelcomeExperience.shared

    @State private var dimAlpha: CGFloat = 0
    @State private var burstProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(.black)
                .modifier(WelcomeBurstModifier(
                    dimAlpha: dimAlpha,
                    burstProgress: burstProgress,
                    size: geo.size,
                    anchor: CGPoint(x: geo.size.width / 2, y: 0)
                ))
        }
        .ignoresSafeArea()
        .onChange(of: welcome.phase) { _, newPhase in
            handlePhase(newPhase)
        }
        .onAppear {
            handlePhase(welcome.phase)
        }
    }

    private func handlePhase(_ phase: WelcomeExperience.WelcomePhase) {
        switch phase {
        case .dimming:
            withAnimation(.easeIn(duration: 1.0)) {
                dimAlpha = 0.7
            }
        case .burst:
            withAnimation(.easeInOut(duration: 2.5)) {
                burstProgress = 1.0
            }
        default:
            break
        }
    }
}

// MARK: - Animatable shader bridge

struct WelcomeBurstModifier: ViewModifier, Animatable {
    var dimAlpha: CGFloat
    var burstProgress: CGFloat
    var size: CGSize
    var anchor: CGPoint

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(dimAlpha, burstProgress) }
        set {
            dimAlpha = newValue.first
            burstProgress = newValue.second
        }
    }

    func body(content: Content) -> some View {
        content
            .colorEffect(
                ShaderLibrary.welcomeBurst(
                    .float2(size),
                    .float2(anchor),
                    .float(Float(burstProgress)),
                    .float(Float(dimAlpha))
                )
            )
    }
}
