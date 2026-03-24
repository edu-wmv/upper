//
//  WelcomeExperience.swift
//  upper
//

import SwiftUI
import Combine

@MainActor
class WelcomeExperience: ObservableObject {
    static let shared = WelcomeExperience()

    @AppStorage("hasCompletedWelcome") private(set) var hasCompleted: Bool = false
    @Published private(set) var phase: WelcomePhase = .idle
    @Published var contentHeight: CGFloat = 0

    weak var primaryViewModel: UpperViewModel?

    private var narrationContinuation: CheckedContinuation<Void, Never>?

    enum WelcomePhase: Equatable {
        case idle
        case dimming
        case notchOpening
        case narrating
        case notchClosing
        case burst
        case finished
    }

    var isActive: Bool {
        switch phase {
        case .idle, .finished: false
        default: true
        }
    }

    var shouldShowWelcome: Bool { !hasCompleted }

    func isTarget(_ viewModel: UpperViewModel) -> Bool {
        isActive && viewModel === primaryViewModel
    }

    // MARK: - Sequence

    func runSequence(viewModel: UpperViewModel) async {
        primaryViewModel = viewModel

        phase = .dimming
        try? await Task.sleep(for: .seconds(1.2))

        phase = .notchOpening
        viewModel.open()
        try? await Task.sleep(for: .seconds(0.5))

        phase = .narrating

        await withCheckedContinuation { continuation in
            narrationContinuation = continuation
        }

        withAnimation(.smooth(duration: 0.35)) {
            phase = .notchClosing
        }

        viewModel.close()
        try? await Task.sleep(for: .seconds(0.8))

        phase = .burst
        try? await Task.sleep(for: .seconds(2.8))

        complete()
    }

    func finishNarration() {
        narrationContinuation?.resume()
        narrationContinuation = nil
    }

    func complete() {
        hasCompleted = true
        phase = .finished
    }

    func reset() {
        narrationContinuation?.resume()
        narrationContinuation = nil
        hasCompleted = false
        contentHeight = 0
        phase = .idle
    }
}
