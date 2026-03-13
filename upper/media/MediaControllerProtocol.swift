//
//  MediaControllerProtocol.swift
//  upper
//
//  Created by Eduardo Monteiro on 01/03/26.
//

import Foundation
import Combine

protocol MediaControllerProtocol: ObservableObject {
    var playbackStatePublisher: AnyPublisher<PlaybackState, Never> { get }
    var isWorking: Bool { get }
    
    func play() async
    func pause() async
    func seek(to time: Double) async
    func next() async
    func previous() async
    func togglePlay() async
    func toggleShuffle() async
    func toggleRepeat() async
    func isActive() -> Bool
    func updatePlaybackInfo() async 
}
