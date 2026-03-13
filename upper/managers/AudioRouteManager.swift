//
//  AudioRouteManager.swift
//  upper
//
//  Created by Eduardo Monteiro on 12/03/26.
//

import Foundation
import Combine
import CoreAudio

final class AudioRouteManager: ObservableObject {
    static let shared = AudioRouteManager()
    
    // MARK: - Properties
    @Published private(set) var devices: [AudioOutputDevice] = []
    @Published private(set) var activeDeviceId: AudioDeviceID = 0
    
    private let queue = DispatchQueue(label: "com.upper.audioroute", qos: .userInitiated)
    
    var activeDevice: AudioOutputDevice? { devices.first { $0.id == activeDeviceId } }
    
    // MARK: - Initialization
    private init() {
        refreshDevices()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: .systemAudioRouteDidChange,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Methods
    
    func refreshDevices() {
        queue.async { [weak self] in
            guard let self else { return }
            
            let defaultId = self.fetchDefaultOutputDevice()
            let deviceInfos = self.fetchOutputDeviceIds().compactMap(self.makeDeviceInfo)
            let sortedDevices = deviceInfos.sorted { lhs, rhs in
                if lhs.id == defaultId { return true }
                if rhs.id == defaultId { return false }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            
            DispatchQueue.main.async {
                self.activeDeviceId = defaultId
                self.devices = sortedDevices
            }
        }
    }
    
    func select(device: AudioOutputDevice) {
        queue.async { [weak self] in
            guard let self else { return }
            self.setDefaultOutputDevice(device.id)
        }
    }
    
    // MARK: - Private
    @objc private func handleRouteChange() { refreshDevices() }
    
    private func fetchOutputDeviceIds() -> [AudioDeviceID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize
        ) == noErr else { return [] }
        
        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIds = [AudioDeviceID](repeating: 0, count: deviceCount)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &deviceIds
        )
        
        if status != noErr { return [] }
        
        return deviceIds
    }
    
    private func fetchDefaultOutputDevice() -> AudioDeviceID {
        var deviceId = AudioDeviceID()
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &deviceId
        )
        
        return status == noErr ? deviceId : 0
    }
    
    private func makeDeviceInfo(for deviceId: AudioDeviceID) -> AudioOutputDevice? {
        guard deviceHasOutputChannels(deviceId) else { return nil }
        let name = deviceName(for: deviceId) ?? "Unknown Device"
        let transport = transportType(for: deviceId)
        return AudioOutputDevice(id: deviceId, name: name, transportType: transport)
    }
    
    private func deviceHasOutputChannels(_ deviceId: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            deviceId,
            &address,
            0,
            nil,
            &dataSize
        ) == noErr else { return false }
        
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { buffer.deallocate() }
        
        guard AudioObjectGetPropertyData(
            deviceId,
            &address,
            0,
            nil,
            &dataSize,
            buffer
        ) == noErr else { return false }
        
        let audioBufferListPointer = buffer.assumingMemoryBound(to: AudioBufferList.self)
        let audioBuffers = UnsafeMutableAudioBufferListPointer(audioBufferListPointer)
        let channelCount = audioBuffers.reduce(0) { $0 + Int($1.mNumberChannels) }
        return channelCount > 0
    }
    
    private func deviceName(for deviceId: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var name: CFString = "" as CFString
        var dataSize = UInt32(MemoryLayout<CFString?>.size)
        let status = AudioObjectGetPropertyData(
            deviceId,
            &address,
            0,
            nil,
            &dataSize,
            &name
        )
        
        guard status == noErr else { return nil }
        return name as String
    }
    
    private func transportType(for deviceId: AudioDeviceID) -> UInt32 {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var type: UInt32 = kAudioDeviceTransportTypeUnknown
        var dataSize = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(
            deviceId,
            &address,
            0,
            nil,
            &dataSize,
            &type
        )
        
        return status == noErr ? type : kAudioDeviceTransportTypeUnknown
    }
    
    private func setDefaultOutputDevice(_ deviceId: AudioDeviceID) {
        var target = deviceId
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &target
        )
        
        if status == noErr {
            DispatchQueue.main.async { [weak self] in
                self?.activeDeviceId = deviceId
            }
            
            refreshDevices()
        }
    }
}

struct AudioOutputDevice: Identifiable, Equatable {
    let id: AudioDeviceID
    let name: String
    let transportType: UInt32
    
    var iconName: String {
        let normalizedName = name.lowercased()
        
        if normalizedName.contains("airpods") {
            return "airpods.pro"
        }
        
        if normalizedName.contains("macbook") {
            return "laptopcomputer"
        }
        
        if normalizedName.contains("headphone") || normalizedName.contains("headset") {
            return "headphones"
        }
        
        if normalizedName.contains("beats") {
            return "beats.headphones"
        }
        
        if normalizedName.contains("homepod") {
            return "hifispeaker"
        }
        
        switch transportType {
        case kAudioDeviceTransportTypeBluetooth:
            if normalizedName.contains("speaker") { return "speaker.wave.2" }
            return "headphones"
        case kAudioDeviceTransportTypeAirPlay:
            return "airplayaudio"
        case kAudioDeviceTransportTypeDisplayPort, kAudioDeviceTransportTypeHDMI:
            return "tv"
        case kAudioDeviceTransportTypeUSB, kAudioDeviceTransportTypeFireWire:
            return "hifispeaker.2"
        case kAudioDeviceTransportTypePCI, kAudioDeviceTransportTypeVirtual:
            return "speaker.wave.2"
        case kAudioDeviceTransportTypeBuiltIn:
            return normalizedName.contains("display") ? "tv" : "speaker.wave.2"
        default:
            return "speaker.wave.2"
        }
    }
}
