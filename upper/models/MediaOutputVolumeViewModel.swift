//
//  MediaOutputVolumeViewModel.swift
//  upper
//
//  Created by Eduardo Monteiro on 12/03/26.
//

import Combine
import Foundation

final class MediaOutputVolumeViewModel: ObservableObject {
    // MARK: - Properties
    @Published var level: Float
    @Published var isMuted: Bool
    
    private let controller: SystemVolumeController
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Initialization
    init(controller: SystemVolumeController = .shared) {
        self.controller = controller
        controller.start()
        level = controller.currentVolume
        isMuted = controller.isMuted
        
        NotificationCenter.default.publisher(for: .systemVolumeDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self,
                      let value = notification.userInfo?["value"] as? Float,
                      let muted = notification.userInfo?["muted"] as? Bool
                else { return }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .systemAudioRouteDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncFromController()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Methods
    func setVolume(_ value: Float) {
        level = value
        if value > 0 { isMuted = false }
        controller.setVolume(value)
    }
    
    func toggleMute() {
        isMuted.toggle()
        controller.toggleMute()
    }
    
    // MARK: - Private methods
    private func syncFromController() {
        level = controller.currentVolume
        isMuted = controller.isMuted
    }
    
    
}
