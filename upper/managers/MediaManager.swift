//
//  MusicManager.swift
//  upper
//
//  Created by Eduardo Monteiro on 03/03/26.
//

import Combine
import Defaults
import Foundation
import SwiftUI

let defaultImage: NSImage = .init(
    systemSymbolName: "music.note",
    accessibilityDescription: "Default music note icon"
)!

struct SkipGesturePulse: Equatable {
    let token: Int
    let direction: SkipDirection
    let behavior: MediaSkipBehavior
}

class MediaManager: ObservableObject {
    
    // MARK: - Properties
    static let shared = MediaManager()
    private var cancellables = Set<AnyCancellable>()
    private var controllerCancelables = Set<AnyCancellable>()
    private var debounceIdleTask: Task<Void, Never>?
    @MainActor private var pendingOptimisticPlayState: Bool?
    
    private let mediaChecker = MediaChecker()
    private var activeController: (any MediaControllerProtocol)?
    
    @ObservedObject var coordinator = UpperViewCoordinator.shared
    
    // Song data
    @Published var songTitle: String = ""
    @Published var artistName: String = ""
    @Published var albumName: String = ""
    @Published var albumArt: NSImage = defaultImage
    @Published var isPlaying: Bool = false
    @Published var isPlayerIdle: Bool = true
    @Published var avgColor: NSColor = .clear
    @Published var bundleIdentifier: String? = nil
    @Published var songDuration: TimeInterval = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var timestampDate: Date = .init()
    @Published var playbackRate: Double = 1.0
    @Published var isShuffled: Bool = false
    @Published var repeatMode: RepeatMode = .off
    @Published var usingAppIconForArtwork: Bool = false
    @Published private(set) var skipGesturePulse: SkipGesturePulse?
    
    private var artworkData: Data? = nil
    private var workItem: DispatchWorkItem?
    
    private var lastArtworkTitle: String = ""
    private var lastArtworkArtist: String = ""
    private var lastArtworkAlbum: String = ""
    private var lastArtworkBundleIdentifier: String? = nil
    
    @Published var flipAngle: Double = 0
    @Published var flipDirection: SkipDirection = .forward
    private let flipAnimationDuration: TimeInterval = 0.45
    private var pendingFlipAnimation: SkipDirection?
    
    @Published var isTransitioning: Bool = false
    private var transitionWorkItem: DispatchWorkItem?
    private var skipGestureToken: Int = 0
    
    private static let placeholderTitles: Set<String> = [
        "unknown", "not playing"
    ]
    
    private static let placeholderArtists: Set<String> = [
        "unknown"
    ]
    
    var hasActiveSession: Bool {
        if isPlaying { return true }
        let trimmedTitle = songTitle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedArtist = artistName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let hasRealTitle = !trimmedTitle.isEmpty && !Self.placeholderTitles.contains(trimmedTitle)
        let hasRealArtist = !trimmedArtist.isEmpty && !Self.placeholderArtists.contains(trimmedArtist)
        return hasRealTitle || hasRealArtist
    }
    
    // MARK: - Initialization
    init() {
        NotificationCenter.default.publisher(for: Notification.Name.mediaControllerChanged)
            .sink { [weak self] _ in
                if let controller = self?.createController(for: .nowPlaying) {
                    self?.setActiveController(controller)
                }
            }
            .store(in: &cancellables)
        
        Task { @MainActor in
            if let controller = self.createController(for: .nowPlaying) {
                self.setActiveController(controller)
            }
        }
    }
    
    deinit {
        destroy()
    }
    
    public func destroy() {
        debounceIdleTask?.cancel()
        cancellables.removeAll()
        controllerCancelables.removeAll()
        transitionWorkItem?.cancel()
        
        activeController = nil
    }
    
    // MARK: - Setup
    private func createController(for type: MediaControllerType) -> (any MediaControllerProtocol)? {
        if activeController != nil {
            controllerCancelables.removeAll()
            activeController = nil
        }
        
        let newController: (any MediaControllerProtocol)?
        
        switch type {
        case .nowPlaying:
            newController = NowPlayingController()
        }
        
        if let controller = newController {
            controller.playbackStatePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    guard let self = self,
                          self.activeController === controller else { return }
                    self.updateFromPlaybackState(state)
                }
                .store(in: &controllerCancelables)
        }
        
        return newController
    }
    
    private func setActiveController(_ controller: any MediaControllerProtocol) {
        activeController = controller
        forceUpdate()
    }
    
    @MainActor
    private func applyPlayState(_ state: Bool, animation: Animation?) {
        if let animation {
            var transaction = Transaction()
            transaction.animation = animation
            withTransaction(transaction) {
                self.isPlaying = state
            }
        } else {
            self.isPlaying = state
        }
        
        self.updateIdleState(state: state)
    }
    
    // MARK: - Update
    @MainActor
    private func updateFromPlaybackState(_ state: PlaybackState) {
        let eventIsPlaying = state.isPlaying
        let expectedState = pendingOptimisticPlayState
        pendingOptimisticPlayState = nil
        
        if eventIsPlaying != self.isPlaying {
            let animation: Animation? = (expectedState == eventIsPlaying) ? .smooth(duration: 0.18) : .smooth
            applyPlayState(eventIsPlaying, animation: animation)
            
            if eventIsPlaying && !state.title.isEmpty && !state.artist.isEmpty {
                self.updateSneakPeek()
            }
        } else {
            self.updateIdleState(state: eventIsPlaying)
        }
        
        let titleChanged = state.title != self.lastArtworkTitle
        let artistsChanged = state.artist != self.lastArtworkArtist
        let albumChanged = state.album != self.lastArtworkAlbum
        let bundleChanged = state.bundleIdentifier != self.lastArtworkBundleIdentifier
        let artworkChanged = state.artwork != nil && state.artwork != self.artworkData
        let hasContentChanged = titleChanged || artistsChanged || albumChanged || artworkChanged || bundleChanged
        
        if hasContentChanged {
            self.triggerFlipAnimation()
            
            if artworkChanged, let artwork = state.artwork {
                self.updateArtwork(artwork)
            } else if state.artwork == nil {
                if let appIconImage = AppIconAsNSImage(for: state.bundleIdentifier) {
                    self.usingAppIconForArtwork = true
                    self.updateAlbumArt(newAlbumArt: appIconImage)
                }
            }
            
            self.artworkData = state.artwork
            
            self.lastArtworkTitle = state.title
            self.lastArtworkArtist = state.artist
            self.lastArtworkAlbum = state.album
            self.lastArtworkBundleIdentifier = state.bundleIdentifier
            
            // TODO: - update sneak peek
            
        }
        
        let timeChanged = state.currentTime != self.elapsedTime
        let durationChanged = state.duration != self.songDuration
        let playbackRateChanged = state.playbackRate != self.playbackRate
        let shuffleChanged = state.isShuffled != self.isShuffled
        let repeatModeChanged = state.repeatMode != self.repeatMode
        
        if state.title != self.songTitle { self.songTitle = state.title }
        if state.artist != self.artistName { self.artistName = state.artist }
        if state.album != self.albumName { self.albumName = state.album }
        if timeChanged { self.elapsedTime = state.currentTime }
        if durationChanged { self.songDuration = state.duration }
        if playbackRateChanged { self.playbackRate = state.playbackRate }
        if shuffleChanged { self.isShuffled = state.isShuffled }
        if state.bundleIdentifier != self.bundleIdentifier { self.bundleIdentifier = state.bundleIdentifier }
        if repeatModeChanged { self.repeatMode = state.repeatMode }
                
        self.timestampDate = state.lastUpdated
    }
    
    private func updateIdleState(state: Bool) {
        if state {
            isPlayerIdle = false
            debounceIdleTask?.cancel()
        } else {
            debounceIdleTask?.cancel()
            debounceIdleTask = Task { [weak self] in
                guard let self = self else { return }
                try? await Task.sleep(for: .seconds(3))
                withAnimation { self.isPlayerIdle = !self.isPlaying }
            }
        }
    }
    
    func updateAlbumArt(newAlbumArt: NSImage) {
        workItem?.cancel()
        workItem = DispatchWorkItem { [weak self] in
            withAnimation(.smooth) {
                self?.albumArt = newAlbumArt
                self?.calculateAverageColor()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: workItem!)
    }
    
    private func updateArtwork(_ artworkData: Data) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if let artworkImage = NSImage(data: artworkData) {
                DispatchQueue.main.async { [weak self] in
                    self?.usingAppIconForArtwork = false
                    self?.updateAlbumArt(newAlbumArt: artworkImage)
                }
            }
        }
    }
    
    private func updateSneakPeek() {
        guard !songTitle.isEmpty, !artistName.isEmpty else { return }
        
//        let config = SneakPeekConfig(
//            type: .generic,
//            title: "\(songTitle) - \(artistName)",
//            duration: 3.5
//        )
        
        //        coordinator.showSneakPeek(config) -> change into coordinator instead of viewmodel
    }
    
    func forceUpdate() {
        Task { [weak self] in
            if self?.activeController?.isActive() == true {
                await self?.activeController?.updatePlaybackInfo()
            }
        }
    }
    
    // MARK: - Helpers
    func calculateAverageColor() {
        albumArt.averageColor { [weak self] color in
            DispatchQueue.main.async {
                withAnimation(.smooth) { self?.avgColor = color ?? .white }
            }
        }
    }
    
    public func estimatedPlaybackPosition(at date: Date = Date()) -> TimeInterval {
        guard isPlaying else { return min(elapsedTime, songDuration) }
        
        let timeDiff = date.timeIntervalSince(timestampDate)
        let estimatedPosition = elapsedTime + (timeDiff * playbackRate)
        return min(max(0, estimatedPosition), songDuration)
    }
    
    @MainActor
    func handleSkipGestures(direction: SkipDirection) {
        guard !isPlayerIdle || bundleIdentifier != nil else { return }
        
        let behavior = Defaults[.mediaGestureBehavior]
        
        switch behavior {
        case .track:
            if direction == .forward { next() } else { previous() }
        case .tenSecond:
            let interval: TimeInterval = 10
            let offset = direction == .forward ? interval : -interval
            seek(by: offset)
        }
        
        skipGestureToken = skipGestureToken &+ 1
        skipGesturePulse = SkipGesturePulse(
            token: skipGestureToken,
            direction: direction,
            behavior: behavior
        )
    }
    
    func openMediaApp() {
        guard let bundleId = bundleIdentifier else {
            Logger.log("Error: appBundleIdentifier is nil", type: .error)
            return
        }
        
        let workspace = NSWorkspace.shared
        if let appURL = workspace.urlForApplication(withBundleIdentifier: bundleId) {
            let configuration = NSWorkspace.OpenConfiguration()
            workspace.openApplication(at: appURL, configuration: configuration) { (app, error) in
                if let error = error {
                    Logger.log("Failed to launch app with bundle ID: \(bundleId) | Error: \(error)", type: .error)
                } else {
                    Logger.log("Launched app with bundle ID: \(bundleId)", type: .info)
                }
            }
        } else {
            Logger.log("Failed to find app with bundle ID: \(bundleId)", type: .error)
        }
    }
    
    
    private func triggerFlipAnimation() {
        let direction: SkipDirection = pendingFlipAnimation ?? .forward
        pendingFlipAnimation = nil
        flipDirection = direction
        
        let delta: Double = (direction == .backward) ? 180 : -180
        
        withAnimation(.easeInOut(duration: flipAnimationDuration)) {
            flipAngle += delta
        }
    }
    
    // MARK: - Controls
    func play() { Task { await activeController?.play() } }
    func pause() { Task { await activeController?.pause() } }
    func playPause() { Task { await activeController?.togglePlay() } }
    func next() { 
        pendingFlipAnimation = .forward
        Task { await activeController?.next() } 
    }
    func previous() { 
        pendingFlipAnimation = .backward
        Task { await activeController?.previous() } 
    }
    func toggleShuffle() { Task { await activeController?.toggleShuffle() } }
    func toggleRepeat() { Task { await activeController?.toggleRepeat() } }
    func togglePlay() {
        guard let controller = activeController else { return }
        
        Task {
            await MainActor.run {
                let newState = !isPlaying
                pendingOptimisticPlayState = newState
                applyPlayState(newState, animation: .smooth(duration: 0.18))
            }
            
            await controller.togglePlay()
        }
    }
    func seek(to position: TimeInterval) { Task { await activeController?.seek(to: position ) } }
    func seek(by offset: TimeInterval) {
        let duration = songDuration
        guard duration > 0 else { return }
        
        let current = estimatedPlaybackPosition()
        let magnitude = abs(offset)
        
        if offset < 0, current <= magnitude {
            previous()
            return
        }
        
        if offset > 0, current >= duration - magnitude {
            next()
            return
        }
        
        let target = min(max(0, current + offset), duration)
        seek(to: target)
    }
    
}
