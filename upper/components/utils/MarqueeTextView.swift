//
//  MarqueeTextView.swift
//  upper
//
//  Created by Eduardo Monteiro on 08/03/26.
//

import SwiftUI

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct MeasureSizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geometry in
                Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        )
    }
}

struct MarqueeText: View {
    @Binding var text: String
    let font: Font
    let nsFont: NSFont.TextStyle
    let textColor: Color
    let backgroundColor: Color
    let minDuration: Double
    let frameWidth: CGFloat
    let alignment: Alignment

    @State private var animate: Bool = false
    @State private var offset: CGFloat = 0

    init(
        _ text: Binding<String>,
        font: Font = .body,
        nsFont: NSFont.TextStyle = .body,
        textColor: Color = .primary,
        backgroundColor: Color = .clear,
        minDuration: Double = 3.0,
        frameWidth: CGFloat = 200,
        alignment: Alignment = .leading
    ) {
        _text = text
        self.font = font
        self.nsFont = nsFont
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.minDuration = minDuration
        self.frameWidth = frameWidth
        self.alignment = alignment
    }

    private var resolvedFont: NSFont {
        NSFont.preferredFont(forTextStyle: nsFont)
    }

    private var intrinsicTextWidth: CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: resolvedFont]
        return (text as NSString).size(withAttributes: attributes).width
    }

    private var needsScrolling: Bool {
        intrinsicTextWidth > frameWidth
    }

    private var textHeight: CGFloat {
        resolvedFont.pointSize * 1.3
    }

    var body: some View {
        ZStack {
            if needsScrolling {
                scrollingContent
            } else {
                staticContent
            }
        }
        .frame(width: frameWidth, height: textHeight)
        .clipped()
    }

    @ViewBuilder
    private var staticContent: some View {
        Text(text)
            .font(font)
            .foregroundStyle(textColor)
            .lineLimit(1)
            .background(backgroundColor)
            .frame(width: frameWidth, alignment: alignment)
    }

    @ViewBuilder
    private var scrollingContent: some View {
        HStack(spacing: 20) {
            Text(text)
            Text(text)
        }
        .font(font)
        .foregroundStyle(textColor)
        .fixedSize(horizontal: true, vertical: false)
        .background(backgroundColor)
        .offset(x: animate ? offset : 0)
        .animation(
            animate
                ? .linear(duration: Double(intrinsicTextWidth / 30))
                  .delay(minDuration)
                  .repeatForever(autoreverses: false)
                : .none,
            value: animate
        )
        .frame(width: frameWidth, alignment: .leading)
        .onAppear { startScrollIfNeeded() }
        .onChange(of: text) { _, _ in startScrollIfNeeded() }
    }

    private func startScrollIfNeeded() {
        animate = false
        offset = 0
        guard needsScrolling else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            animate = true
            offset = -(intrinsicTextWidth + 20)
        }
    }
}
