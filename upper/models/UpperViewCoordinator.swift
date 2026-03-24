//
//  UpperViewCoordinator.swift
//  upper
//
//  Created by Eduardo Monteiro on 24/02/26.
//

import Foundation
import Combine
import Defaults
import SwiftUI

class UpperViewCoordinator: ObservableObject {
    static let shared = UpperViewCoordinator()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Sneak Peek

    let sneakPeekSubject = PassthroughSubject<SneakPeekConfig, Never>()

    func requestSneakPeek(_ config: SneakPeekConfig) {
        sneakPeekSubject.send(config)
    }

    // MARK: - View routing

    @Published var currentView: NotchViews = .home {
        didSet {
            if Defaults[.enableMinimalMode] && currentView != .home {
                currentView = .home
                return
            }
        }
    }
    
    @AppStorage("preferred_screen_name") var preferredScreen = NSScreen.main?.localizedName ?? "Unknown" {
        didSet {
            selectedScreen = preferredScreen
        }
    }
    
    @Published var selectedScreen: String = NSScreen.main?.localizedName ?? "Unknown"
    
    private init() {
        Defaults.publisher(.enableMinimalMode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                self?.handleMinimalModeChange(change.newValue)
            }
            .store(in: &cancellables)
    }
    
    private func handleMinimalModeChange(_ newValue: Bool) {
        guard newValue else { return }
        if currentView != .home {
            withAnimation(.smooth) {
                currentView = .home
            }
        }
    }
    
}

