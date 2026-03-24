//
//  WelcomeNarrationView.swift
//  upper
//
//  Typewriter-style welcome text shown inside the open notch
//  during the first-launch sequence.
//

import SwiftUI

struct WelcomeNarrationView: View {
    @ObservedObject var welcome = WelcomeExperience.shared

    @State private var visibleCount: Int = 0
    @State private var showCTA: Bool = false

    private let lines: [(text: String, pause: Duration)] = [
        ("hey!", .milliseconds(1800)),
        ("\nif you're seeing this, you were invited to be a beta tester of upper", .milliseconds(600)),
        ("\nyour notch, reimagined.", .milliseconds(600)),
        ("\n", .zero),
        ("\nit's a work in progress, so please report any issues you find.", .milliseconds(600)),
        ("\n", .zero),
        ("\nnow, let's start! :D", .zero)
    ]

    private var fullText: String {
        lines.map(\.text).joined()
    }

    private var displayedText: String {
        String(fullText.prefix(visibleCount))
    }

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text(displayedText)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

            if showCTA {
                ctaButtons
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: NarrationHeightKey.self, value: geo.size.height)
            }
        )
        .onPreferenceChange(NarrationHeightKey.self) { height in
            welcome.contentHeight = height
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .task {
            await runTypewriter()
        }
    }

    private var ctaButtons: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    _ = await AppleScriptHelper.requestMusicAutomationPermission()
                    welcome.finishNarration()
                }
            } label: {
                Text("Look Up")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.12), in: .capsule)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.85))
        }
    }

    private func runTypewriter() async {
        try? await Task.sleep(for: .milliseconds(300))

        var totalChars = 0
        for line in lines {
            for _ in line.text {
                guard !Task.isCancelled else { return }
                totalChars += 1
                visibleCount = totalChars
                try? await Task.sleep(for: .milliseconds(40))
            }
            if line.pause > .zero {
                try? await Task.sleep(for: line.pause)
            }
        }

        try? await Task.sleep(for: .milliseconds(500))
        withAnimation(.easeOut(duration: 0.3)) {
            showCTA = true
        }
    }
}

private struct NarrationHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    WelcomeNarrationView()
        .frame(width: 300, height: 500, alignment: .center)
}
