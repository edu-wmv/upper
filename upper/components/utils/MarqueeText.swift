//
//  MarqueeText.swift
//  upper
//
//  Created by Eduardo Monteiro on 16/03/26.
//

import SwiftUI

struct AlignMarqueeText: View {
    var text: String
    let font: Font
    let leftFade: CGFloat
    let rightFade: CGFloat
    let startDelay: Double
    var alignment: Alignment
    
    @State private var animate = false
    var isCompact = false
    
    init(
        _ text: String,
        font: Font,
        leftFade: CGFloat,
        rightFade: CGFloat,
        startDelay: Double,
        alignment: Alignment? = nil
    ) {
        self.text = text
        self.font = font
        self.leftFade = leftFade
        self.rightFade = rightFade
        self.startDelay = startDelay
        self.alignment = alignment ?? .topLeading
    }
    
    
    var body: some View {
        let textSize = text.stringSize(usingFont: font)
        
        let animation = Animation
            .linear(duration: Double(textSize.width) / 30)
            .delay(startDelay)
            .repeatForever(autoreverses: false)
        
        let nullAnimation = Animation.linear(duration: 0)
        
        GeometryReader { geo in
            let needsScrolling = (textSize.width > geo.size.width)
            
            ZStack {
                if needsScrolling {
                    makeMarqueeText(
                        textWidth: textSize.width,
                        textHeight: textSize.height,
                        geoWidth: geo.size.width,
                        animation: animation,
                        nullAnimation: nullAnimation
                    )
                    .frame(
                        minWidth: 0,
                        maxWidth: .infinity,
                        minHeight: 0,
                        maxHeight: .infinity,
                        alignment: .topLeading
                    )
                    .offset(x: leftFade)
                    .mask(
                        fadeMask(leftFade: leftFade, rightFade: rightFade)
                    )
                    .frame(width: geo.size.width + leftFade)
                    .offset(x: -leftFade)
                } else {
                    Text(text)
                        .font(font)
                        .onChange(of: text) { _, _ in
                            self.animate = false
                        }
                        .frame(
                            minWidth: 0,
                            maxWidth: .infinity,
                            minHeight: 0,
                            maxHeight: .infinity,
                            alignment: alignment
                        )
                }
            }
            .onAppear {
                self.animate = needsScrolling
            }
            .onChange(of: text) { newValue, _ in
                let newTextSize = newValue.stringSize(usingFont: font)
                if newTextSize.width > geo.size.width {
                    self.animate = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.animate = true
                    }
                } else {
                    self.animate = false
                }
            }
            .frame(height: textSize.height)
            .frame(maxWidth: isCompact ? textSize.width : nil)
            .onDisappear { self.animate = false }
        }
    }
    
    @ViewBuilder
    private func makeMarqueeText(
        textWidth: CGFloat,
        textHeight: CGFloat,
        geoWidth: CGFloat,
        animation: Animation,
        nullAnimation: Animation
    ) -> some View {
        Group {
            Text(text)
                .lineLimit(1)
                .font(font)
                .offset(x: animate ? -textWidth - textHeight * 2 : 0)
                .animation(animate ? animation : nullAnimation, value: animate)
                .fixedSize(horizontal: true, vertical: false)
            Text(text)
                .lineLimit(1)
                .font(font)
                .offset(x: animate ? 0 : textWidth + textHeight * 2 )
                .animation(animate ? animation : nullAnimation, value: animate)
                .fixedSize(horizontal: true, vertical: false)
        }
    }
    
    @ViewBuilder
    private func fadeMask(leftFade: CGFloat, rightFade: CGFloat) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .frame(width: 2)
                .opacity(0)
            
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0), Color.black]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: leftFade)
            
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.black]),
                startPoint: .leading,
                endPoint: .trailing
            )
            
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: rightFade)
            
            Rectangle()
                .frame(width: 2)
                .opacity(0)
        }
    }
}

extension AlignMarqueeText {
    func makeCompact(_ compact: Bool = true) -> Self {
        var copy = self
        copy.isCompact = compact
        return copy
    }
}
