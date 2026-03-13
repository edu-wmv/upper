//
//  NowPlayingController.swift
//  upper
//
//  Created by Eduardo Monteiro on 01/03/26.
//

import Combine
import Foundation

final class NowPlayingController: ObservableObject, MediaControllerProtocol {
    
    // MARK: - Properties
    @Published private(set) var playbackState: PlaybackState = .init(
        bundleIdentifier: "com.apple.Music"
    )
    
    var playbackStatePublisher: AnyPublisher<PlaybackState, Never> {
        $playbackState.eraseToAnyPublisher()
    }
    
    var isWorking: Bool { return process != nil && process?.isRunning == true }
    
    private var lastMediaItem: (title: String, artist: String, album: String, duration: TimeInterval, artworkData: Data?)?
    
    // MARK: - Media Remote Functions
    private let mediaRemoteBundle: CFBundle
    private let MRMediaRemoteSendCommandFunction: @convention(c) (Int, AnyObject?) -> Void
    private let MRMediaRemoteSetElapsedTimeFunction: @convention(c) (Double) -> Void
    private let MRMediaRemoteShuffleModeFunction: @convention(c) (Int) -> Void
    private let MRMediaRemoteRepeatModeFunction: @convention(c) (Int) -> Void
    
    private var process: Process?
    private var pipeHandler: JSONLinesPipeHandler?
    private var streamTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init?() {
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")),
              let MRMediaRemoteSendCommandPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSendCommand" as CFString),
              let MRMediaRemoteSetElapsedTimePointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSetElapsedTime" as CFString),
              let MRMediaRemoteShuffleModePointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSetShuffleMode" as CFString),
              let MRMediaRemoteRepeatModePointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSetRepeatMode" as CFString)
        else { return nil }
        
        mediaRemoteBundle = bundle
        MRMediaRemoteSendCommandFunction = unsafeBitCast(MRMediaRemoteSendCommandPointer, to: (@convention(c) (Int, AnyObject?) -> Void).self)
        MRMediaRemoteSetElapsedTimeFunction = unsafeBitCast(MRMediaRemoteSetElapsedTimePointer, to: (@convention(c) (Double) -> Void).self)
        MRMediaRemoteShuffleModeFunction = unsafeBitCast(MRMediaRemoteShuffleModePointer, to: (@convention(c) (Int) -> Void).self)
        MRMediaRemoteRepeatModeFunction = unsafeBitCast(MRMediaRemoteRepeatModePointer, to: (@convention(c) (Int) -> Void).self)
        
        Task { await setupNowPlayingObserver()}
    }
    
    deinit {
        streamTask?.cancel()
        
        if let pipeHandler = self.pipeHandler {
            Task { await pipeHandler.close() }
        }
        
        if let process = self.process {
            if process.isRunning {
                process.terminate()
                process.waitUntilExit()
            }
        }
        
        self.process = nil
        self.pipeHandler = nil
    }
    
    // MARK: - Setup
    private func setupNowPlayingObserver() async {
        let process = Process()
        guard let scriptURL = Bundle.main.url(forResource: "mediaremote-adapter", withExtension: "pl"),
              let frameworkPath = Bundle.main.resourceURL?.appending(path: "MediaRemoteAdapter.framework")
        else {
            assertionFailure("Failed to locate mediaremote-adapter.pl or MediaRemoteAdapter.framework in the app bundle.")
            return
        }
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        process.arguments = [scriptURL.path, frameworkPath.path, "stream"]
        
        let pipeHandler = JSONLinesPipeHandler()
        process.standardOutput = await pipeHandler.getPipe()
        
        self.process = process
        self.pipeHandler = pipeHandler
        
        do {
            try process.run()
            streamTask = Task { [weak self] in await self?.processJSONStream() }
        } catch {
            assertionFailure("Failed to start mediaremote-adapter.pl: \(error)")
        }
    }
    
    private func processJSONStream() async {
        guard let pipeHandler = self.pipeHandler else { return }
        
        await pipeHandler.readJsonLines(as: NowPlayingUpdate.self) { [weak self] update in
            await self?.handleAdapterUpdate(update)
        }
    }
    
    // MARK: - Protocol
     
    func play() async {
        MRMediaRemoteSendCommandFunction(0, nil)
    }
    
    func pause() async {
        MRMediaRemoteSendCommandFunction(1, nil)
    }
    
    func togglePlay() async {
        MRMediaRemoteSendCommandFunction(2, nil)
    }
    
    func next() async {
        MRMediaRemoteSendCommandFunction(4, nil)
    }
    
    func previous() async {
        MRMediaRemoteSendCommandFunction(5, nil)
    }
    
    func seek(to time: Double) async {
        MRMediaRemoteSetElapsedTimeFunction(time)
    }
    
    func isActive() -> Bool {
        return true
    }
    
    func toggleShuffle() async {
        MRMediaRemoteShuffleModeFunction(playbackState.isShuffled ? 1 : 3)
        playbackState.isShuffled.toggle()
    }
    
    func toggleRepeat() async {
        let newRepeatMode = (playbackState.repeatMode == .off) ? 3 : (playbackState.repeatMode.rawValue - 1)
        playbackState.repeatMode = RepeatMode(rawValue: newRepeatMode) ?? .off
        MRMediaRemoteRepeatModeFunction(newRepeatMode)
    }
    
    // MARK: - Update
    private func handleAdapterUpdate(_ update: NowPlayingUpdate) async {
        let payload = update.payload
        let diff = update.diff ?? false
        
        var newPlaybackState = PlaybackState(bundleIdentifier: playbackState.bundleIdentifier)
        
        newPlaybackState.title = payload.title ?? (diff ? self.playbackState.title : "")
        newPlaybackState.artist = payload.artist ?? (diff ? self.playbackState.artist : "")
        newPlaybackState.album = payload.album ?? (diff ? self.playbackState.album : "")
        newPlaybackState.duration = payload.duration ?? (diff ? self.playbackState.duration : 0)
        newPlaybackState.currentTime = payload.elapsedTime ?? (diff ? self.playbackState.currentTime : 0)
        
        if let shuffleMode = payload.shuffleMode {
            newPlaybackState.isShuffled = shuffleMode != 1
        } else if !diff {
            newPlaybackState.isShuffled = false
        } else {
            newPlaybackState.isShuffled = self.playbackState.isShuffled
        }
        
        if let repeatModeValue = payload.repeatMode {
            newPlaybackState.repeatMode = RepeatMode(rawValue: repeatModeValue) ?? .off
        } else if !diff {
            newPlaybackState.repeatMode = .off
        } else {
            newPlaybackState.repeatMode = self.playbackState.repeatMode
        }
        
        if let artworkDataString = payload.artworkData {
            newPlaybackState.artwork = Data(
                base64Encoded: artworkDataString.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        } else if !diff {
            newPlaybackState.artwork = nil
        }
        
        if let dateString = payload.timestamp,
           let date = ISO8601DateFormatter().date(from: dateString) {
            newPlaybackState.lastUpdated = date
        } else if !diff {
            newPlaybackState.lastUpdated = Date()
        } else {
            newPlaybackState.lastUpdated = self.playbackState.lastUpdated
        }
        
        newPlaybackState.playbackRate = payload.playbackRate ?? (diff ? self.playbackState.playbackRate : 1.0)
        newPlaybackState.isPlaying = payload.playing ?? (diff ? self.playbackState.isPlaying : false)
        newPlaybackState.bundleIdentifier = (
            payload.parentAppBundleIdentifier
            ?? payload.bundleIdentifier
            ?? (diff ? self.playbackState.bundleIdentifier : "")
        )
        
        self.playbackState = newPlaybackState
    }
    
    func updatePlaybackInfo() async {}
}

struct NowPlayingPayload: Codable {
    let title: String?
    let artist: String?
    let album: String?
    let artworkData: String?
    let duration: Double?
    let elapsedTime: Double?
    let timestamp: String?
    let repeatMode: Int?
    let shuffleMode: Int?
    let playbackRate: Double?
    let playing: Bool?
    let parentAppBundleIdentifier: String?
    let bundleIdentifier: String?
}

struct NowPlayingUpdate: Codable {
    let payload: NowPlayingPayload
    let diff: Bool?
}
