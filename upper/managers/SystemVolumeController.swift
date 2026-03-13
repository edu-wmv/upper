//
//  SystemVolumeController.swift
//  upper
//
//  Created by Eduardo Monteiro on 12/03/26.
//

import Combine
import Foundation
import CoreAudio
import CoreGraphics
import IOKit

final class SystemVolumeController {
    static let shared = SystemVolumeController()
    
    var onVolumeChange: ((Float, Bool) -> Void)?
    var onRouteChange: (() -> Void)?
    
    // MARK: - Properties
    
    private let callbackQueue = DispatchQueue(label: "com.upper.volumelistener")
    private var currentDeviceId: AudioDeviceID = 0
    private var listenersInstalled = false
    private var volumeElement: AudioObjectPropertyElement?
    private var muteElement: AudioObjectPropertyElement?
    private let silenceThreshold: Float = 0.001
    
    private let candidateElements: [AudioObjectPropertyElement] = [
        kAudioObjectPropertyElementMain,
        AudioObjectPropertyElement(1),
        AudioObjectPropertyElement(2)
    ]
    
    // MARK: - Initialization
    
    private init() {
        currentDeviceId = resolveDefaultDevice()
        refreshPropertyElements()
        installDefaultDeviceListener()
        installVolumeListeners(for: currentDeviceId)
        notifyCurrentState()
    }
    
    func start() {}
    
    func stop() {
        onVolumeChange = nil
        onRouteChange = nil
    }
    
    // MARK: - Public Methods
    
    var currentVolume: Float { getVolume() }
    var isMuted: Bool { getMuteState() }
    
    func toggleMute() { setMuted(!isMuted) }
    
    func setVolume(_ value: Float) {
        let clamped = max(0, min(1, value))
        let currentlyMuted = isMuted
        
        if clamped <= silenceThreshold {
            if !currentlyMuted { setMuted(true) }
        } else if currentlyMuted {
            setMuted(false)
        }
        
        let elements = volumeElements()
        
        if elements.isEmpty {
            var volume = clamped
            let status = setData(selector: kAudioDevicePropertyVolumeScalar, data: &volume)
            if status != noErr { NSLog("Failed to set volume: \(status)") }
        } else {
            for element in elements {
                var volume = clamped
                let status = setData(selector: kAudioDevicePropertyVolumeScalar, element: element, data: &volume)
                if status != noErr {
                    NSLog("Failed to set volume for element \(element): \(status)")
                } else {
                    cache(element: element, for: kAudioDevicePropertyVolumeScalar)
                }
            }
        }
        
        notifyCurrentState()
    }
    
    func setMuted(_ muted: Bool) {
        var muteFlag: UInt32 = muted ? 1 : 0
        let elements = muteElements()
        
        if elements.isEmpty {
            let status = setData(selector: kAudioDevicePropertyMute, data: &muteFlag)
            if status != noErr { NSLog("Failed to set mute state: \(status)") }
            
            return
        }
        
        for element in elements {
            var value = muteFlag
            let status = setData(selector:kAudioDevicePropertyMute, element: element, data: &value)
            if status != noErr {
                NSLog("Failed to set mute state for element \(element): \(status)")
            } else {
                cache(element: element, for: kAudioDevicePropertyMute)
            }
        }
        
    }
    
    func adjust(by delta: Float) {
        guard delta != 0 else { return }
        if isMuted { setMuted(false) }
        
        var newValue = currentVolume + delta
        newValue = max(0, min(1, newValue))
        setVolume(newValue)
    }
    
    // MARK: - Private
    
    private func resolveDefaultDevice() -> AudioDeviceID {
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
        
        if status != noErr {
            NSLog("Unable to fecth default audio device: \(status)")
        }
        
        return deviceId
    }
    
    private func installDefaultDeviceListener() {
        guard !listenersInstalled else { return }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            callbackQueue
        ) { [weak self] _, _ in
            guard let self else { return }
            self.handleDefaultDeviceChanged()
        }
        
        if status != noErr { NSLog("Failed to install default device listener: \(status)") }
        
        listenersInstalled = true
    }
    
    private func installVolumeListeners(for deviceId: AudioDeviceID) {
        if let element = resolveElement(selector: kAudioDevicePropertyVolumeScalar, deviceId: deviceId) {
            volumeElement = element
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: element
            )
            
            AudioObjectAddPropertyListenerBlock(
                deviceId,
                &address,
                callbackQueue
            ) { [weak self] _, _ in
                self?.notifyCurrentState()
            }
        }
        
        if let element = resolveElement(selector: kAudioDevicePropertyMute, deviceId: deviceId) {
            muteElement = element
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyMute,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: element
            )
            
            AudioObjectAddPropertyListenerBlock(
                deviceId,
                &address,
                callbackQueue
            ) { [weak self] _, _ in
                self?.notifyCurrentState()
            }
        }
    }
    
    private func getVolume() -> Float {
        let elements = volumeElements()
        
        if elements.isEmpty {
            var volume = Float32(0)
            let status = getData(selector: kAudioDevicePropertyVolumeScalar, data: &volume)
            if status != noErr { NSLog("Unable to fetch volume: \(status)") }
            return volume
        }
        
        var masterVolume: Float?
        var accumulator: Float = 0
        var count: Float = 0
        
        for element in elements {
            var value = Float32(0)
            let status = getData(selector: kAudioDevicePropertyVolumeScalar, element: element, data: &value)
            if status == noErr {
                if element == kAudioObjectPropertyElementMain {
                    masterVolume = value
                }
                
                accumulator += value
                count += 1
            }
        }
        
        if let masterVolume { return masterVolume }
        
        if count > 0 { return accumulator / count }
        
        var fallback = Float32(0)
        let status = getData(selector: kAudioDevicePropertyVolumeScalar, data: &fallback)
        if status != noErr { NSLog("Unable to fetch fallback volume: \(status)") }
        
        return fallback
    }
    
    private func getMuteState() -> Bool {
        let elements = muteElements()
        
        if elements.isEmpty {
            var mute: UInt32 = 0
            let status = getData(selector: kAudioDevicePropertyMute, data: &mute)
            if status != noErr { return false }
            return mute != 0
        }
        
        var retrieved = false
        var allMuted = true
        
        for element in elements {
            var value: UInt32 = 0
            let status = getData(selector: kAudioDevicePropertyMute, element: element, data: &value)
            if status == noErr {
                retrieved = true
                if value == 0 { allMuted = false }
            }
        }
        
        if retrieved { return allMuted }
        
        var fallback: UInt32 = 0
        let status = getData(selector: kAudioDevicePropertyMute, data: &fallback)
        if status != noErr { return false }
        
        return fallback != 0
    }
    
    private func refreshPropertyElements() {
        volumeElement = resolveElement(selector: kAudioDevicePropertyVolumeScalar, deviceId: currentDeviceId)
        muteElement = resolveElement(selector: kAudioDevicePropertyMute, deviceId: currentDeviceId)
    }
    
    private func notifyCurrentState() {
        let volume = getVolume()
        let muted = getMuteState()
        
        DispatchQueue.main.async {
            self.onVolumeChange?(volume, muted)
            NotificationCenter.default.post(
                name: .systemVolumeDidChange,
                object: nil,
                userInfo: ["value": volume, "muted": muted]
            )
        }
    }
    
    private func handleDefaultDeviceChanged() {
        callbackQueue.async { [weak self] in
            guard let self else { return }
            self.currentDeviceId = self.resolveDefaultDevice()
            self.refreshPropertyElements()
            self.installVolumeListeners(for: self.currentDeviceId)
            self.notifyCurrentState()
            DispatchQueue.main.async {
                self.onRouteChange?()
                NotificationCenter.default.post(name: .systemAudioRouteDidChange, object: nil)
            }
        }
    }
    
    // MARK: - Helpers
    private func propertyExists(deviceId: AudioDeviceID, address: inout AudioObjectPropertyAddress) -> Bool {
        withUnsafePointer(to: &address) { pointer in
            AudioObjectHasProperty(deviceId, pointer)
        }
    }
    
    private func makeAddress(selector: AudioObjectPropertySelector, element: AudioObjectPropertyElement) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: selector, mScope: kAudioDevicePropertyScopeOutput, mElement: element
        )
    }
    
    private func cachedElement(for selector: AudioObjectPropertySelector) -> AudioObjectPropertyElement? {
        switch selector {
        case kAudioDevicePropertyVolumeScalar:
            return volumeElement
        case kAudioDevicePropertyMute:
            return muteElement
        default:
            return nil
        }
    }
    
    private func preferredElements(for selector: AudioObjectPropertySelector) -> [AudioObjectPropertyElement] {
        if let cached = cachedElement(for: selector) {
            return [cached] + candidateElements.filter { $0 != cached }
        }
        
        return candidateElements
    }
    
    private func resolveElement(selector: AudioObjectPropertySelector, deviceId: AudioDeviceID) -> AudioObjectPropertyElement? {
        for element in candidateElements {
            var address = makeAddress(selector: selector, element: element)
            if propertyExists(deviceId: deviceId, address: &address) {
                return element
            }
        }
        
        return nil
    }
    
    private func cache(element: AudioObjectPropertyElement, for selector: AudioObjectPropertySelector) {
        switch selector {
        case kAudioDevicePropertyVolumeScalar:
            volumeElement = element
        case kAudioDevicePropertyMute:
            muteElement = element
        default:
            break
        }
    }
    
    private func getData<T>(selector: AudioObjectPropertySelector, data: inout T) -> OSStatus {
        var lastStatus: OSStatus = kAudioHardwareUnspecifiedError
        for element in preferredElements(for: selector) {
            var address = makeAddress(selector: selector, element: element)
            guard propertyExists(deviceId: currentDeviceId, address: &address) else { continue }
            var dataSize = UInt32(MemoryLayout<T>.size)
            
            lastStatus = AudioObjectGetPropertyData(currentDeviceId, &address, 0, nil, &dataSize, &data)
            if lastStatus == noErr {
                cache(element: element, for: selector)
                return lastStatus
            }
        }
        
        return lastStatus
    }
    
    private func getData<T>(selector: AudioObjectPropertySelector, element: AudioObjectPropertyElement, data: inout T) -> OSStatus {
        var address = makeAddress(selector: selector, element: element)
        guard propertyExists(deviceId: currentDeviceId, address: &address) else {
            return kAudioHardwareUnknownPropertyError
        }
        
        var dataSize = UInt32(MemoryLayout<T>.size)
        return AudioObjectGetPropertyData(currentDeviceId, &address, 0, nil, &dataSize, &data)
    }
    
    private func setData<T>(selector: AudioObjectPropertySelector, data: inout T) -> OSStatus {
        var lastStatus: OSStatus = kAudioHardwareUnspecifiedError
        for element in preferredElements(for: selector) {
            var address = makeAddress(selector: selector, element: element)
            guard propertyExists(deviceId: currentDeviceId, address: &address) else { continue }
            var dataSize = UInt32(MemoryLayout<T>.size)
            
            lastStatus = AudioObjectSetPropertyData(currentDeviceId, &address, 0, nil, dataSize, &data)
            if lastStatus == noErr {
                cache(element: element, for: selector)
                return lastStatus
            }
        }
        
        return lastStatus
    }
    
    private func setData<T>(selector: AudioObjectPropertySelector, element: AudioObjectPropertyElement, data: inout T) -> OSStatus {
        var address = makeAddress(selector: selector, element: element)
        guard propertyExists(deviceId: currentDeviceId, address: &address) else {
            return kAudioHardwareUnknownPropertyError
        }
        
        var dataSize = UInt32(MemoryLayout<T>.size)
        return AudioObjectSetPropertyData(currentDeviceId, &address, 0, nil, dataSize, &data)
    }
    
    private func volumeElements() -> [AudioObjectPropertyElement] {
        candidateElements.filter { element in
            var address = makeAddress(selector: kAudioDevicePropertyVolumeScalar, element: element)
            return propertyExists(deviceId: currentDeviceId, address: &address)
        }
    }
    
    private func muteElements() -> [AudioObjectPropertyElement] {
        candidateElements.filter { element in
            var address = makeAddress(selector: kAudioDevicePropertyMute, element: element)
            return propertyExists(deviceId: currentDeviceId, address: &address)
        }
    }
}
