#if os(macOS)
    import Combine
    import Foundation
    @preconcurrency import IOBluetooth
    @preconcurrency import IOBluetoothUI
    import os
    import SwiftUI

    /// macOS LE advertises BR/EDR and host may miss Classic profile
    @MainActor
    public final class HIDClassicDevice: NSObject, ObservableObject {
        @Published public private(set) var state: ControllerState = .unknown
        @Published public private(set) var pairedDevices: [PairedDevice] = []
        @Published public private(set) var connectedAddress: String?
        @Published public private(set) var lastError: String?
        @Published public private(set) var batteryLevel: UInt8 = 100
        @Published public private(set) var isSDPPublished = false
        @Published public private(set) var isReady = false

        private let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "HIDClassicDevice")

        public let profile: any HIDProfile
        private var identity: HIDIdentity {
            profile.identity
        }

        private var serviceRecords: [IOBluetoothSDPServiceRecord] = []
        private var device: IOBluetoothDevice?
        private var controlChannel: IOBluetoothL2CAPChannel?
        private var interruptChannel: IOBluetoothL2CAPChannel?
        @Published public private(set) var isConnecting = false

        /// seeded so early GET_REPORT is valid
        private var lastReports: [UInt8: Data]
        private var protocolMode: UInt8 = 0x01
        /// SET_IDLE rate not enforced
        private var idleRate: UInt8 = 0

        private let defaults: UserDefaults = .standard

        public enum ControllerState: Equatable {
            case unknown, poweredOff, poweredOn
        }

        public init(profile: any HIDProfile) {
            self.profile = profile
            lastReports = profile.identity.seedReports
            super.init()
        }

        public func start() {}

        public func stop() {
            disconnect()
            unpublishService()
        }

        public func publishService() {
            guard serviceRecords.isEmpty else { return }
            let dicts = [SDPRecord.buildHID(identity)] + (identity.classicDeviceID ? [SDPRecord.buildDeviceID(identity.pnp)] : [])
            for dict in dicts {
                guard let record = IOBluetoothSDPServiceRecord.publishedServiceRecord(with: dict) else {
                    lastError = L10n.ErrorMessage.sdpPublishFailed
                    log.error("publishedServiceRecord returned nil")
                    unpublishService()
                    return
                }
                serviceRecords.append(record)
                var handle: BluetoothSDPServiceRecordHandle = 0
                _ = record.getHandle(&handle)
                log.info("SDP service published; handle=\(handle, privacy: .public)")
            }
            isSDPPublished = true
        }

        public func unpublishService() {
            serviceRecords.forEach { $0.remove() }
            serviceRecords.removeAll()
            isSDPPublished = false
        }

        /// only show peers added via pair modal
        public func refreshPairedDevices() {
            var collected = _loadStoredDevices()
            for i in collected.indices {
                collected[i].isConnected = _isClassicAclUp(addressID: collected[i].id)
            }
            pairedDevices = collected
        }

        /// private getter via KVC
        fileprivate nonisolated static func _privateBool(_ object: AnyObject, key: String) -> Bool {
            guard let ns = object as? NSObject else { return false }
            let value = ns.value(forKey: key)
            return (value as? Bool) ?? ((value as? NSNumber)?.boolValue ?? false)
        }

        private func _loadStoredDevices() -> [PairedDevice] {
            guard let data = defaults.data(forKey: HIDSettings.classicDevicesKey) else { return [] }
            return (try? JSONDecoder().decode([PairedDevice].self, from: data)) ?? []
        }

        private func _saveStoredDevices(_ list: [PairedDevice]) {
            let data = try? JSONEncoder().encode(list)
            defaults.set(data, forKey: HIDSettings.classicDevicesKey)
        }

        private func _isClassicAclUp(addressID: String) -> Bool {
            guard let dev = _lookup(addressID: addressID) else { return false }
            return dev.isConnected()
        }

        private func _rememberDevice(_ entry: PairedDevice) {
            var list = _loadStoredDevices()
            if list.contains(where: { $0.id == entry.id }) { return }
            list.append(entry)
            _saveStoredDevices(list)
        }

        /// does not unpair at OS level
        public func forgetDevice(id: String) {
            var list = _loadStoredDevices()
            list.removeAll { $0.id == id }
            _saveStoredDevices(list)
            refreshPairedDevices()
        }

        /// temporarily flips CoD so scanners see HID device
        @discardableResult
        public func presentPairingPicker(title: String, message: String) -> PairedDevice? {
            guard let selector = IOBluetoothDeviceSelectorController.deviceSelector() else {
                lastError = L10n.ErrorMessage.sdpPublishFailed
                return nil
            }
            publishService()

            if let host = IOBluetoothHostController.default() {
                host.setClassOfDevice(identity.classOfDevice, forTimeInterval: 120.0)
            }
            selector.setTitle(title)
            selector.setHeader(L10n.Classic.pairWindowHeader)
            selector.setDescriptionText(message)
            let response = selector.runModal()
            guard response == kIOBluetoothUISuccess else {
                return nil
            }
            let results = selector.getResults() as? [IOBluetoothDevice] ?? []

            guard let picked = results.first else {
                return nil
            }
            let entry = PairedDevice(
                id: _canonicalAddress(picked.addressString ?? ""),
                name: picked.name ?? picked.addressString ?? L10n.Device.unknownName,
                isConnected: picked.isConnected()
            )
            _rememberDevice(entry)
            refreshPairedDevices()
            return entry
        }

        public func connect(to peer: PairedDevice) {
            guard !isConnecting else { return }
            publishService()
            guard let target = _lookup(addressID: peer.id) else {
                lastError = L10n.ErrorMessage.deviceNotPaired(peer.name)
                return
            }
            disconnect()
            device = target
            isConnecting = true
            let addressStr = target.addressString ?? "?"
            log.info("opening ACL to \(addressStr, privacy: .public)")

            if !target.isConnected() {
                let aclResult = target.openConnection()
                if aclResult != kIOReturnSuccess {
                    lastError = L10n.ErrorMessage.openConnectionFailed(Self._ioReturnCode(aclResult))
                    log.error("openConnection failed \(Self._ioReturnCode(aclResult), privacy: .public)")
                    isConnecting = false
                    device = nil
                    return
                }
            }

            var control: IOBluetoothL2CAPChannel?
            let controlResult = target.openL2CAPChannelSync(&control, withPSM: BluetoothL2CAPPSM(0x0011), delegate: self)
            if controlResult != kIOReturnSuccess || control == nil {
                lastError = L10n.ErrorMessage.openL2CAPFailed(0x0011, Self._ioReturnCode(controlResult))
                log.error("L2CAP PSM 0x0011 open failed \(Self._ioReturnCode(controlResult), privacy: .public)")
                target.closeConnection()
                device = nil
                isConnecting = false
                return
            }
            log.info("control L2CAP open")

            var interrupt: IOBluetoothL2CAPChannel?
            let interruptResult = target.openL2CAPChannelSync(&interrupt, withPSM: BluetoothL2CAPPSM(0x0013), delegate: self)
            if interruptResult != kIOReturnSuccess || interrupt == nil {
                lastError = L10n.ErrorMessage.openL2CAPFailed(0x0013, Self._ioReturnCode(interruptResult))
                log.error("L2CAP PSM 0x0013 open failed \(Self._ioReturnCode(interruptResult), privacy: .public)")
                control?.close()
                target.closeConnection()
                device = nil
                isConnecting = false
                return
            }
            log.info("interrupt L2CAP open")

            controlChannel = control
            interruptChannel = interrupt
            connectedAddress = Self._canonicalAddress(addressStr)
            isReady = true
            isConnecting = false
            profile.connect(host: addressStr) { [weak self] id, data in self?.send(id, data) }
            refreshPairedDevices()
        }

        public func disconnect() {
            profile.disconnect()
            controlChannel?.close()
            interruptChannel?.close()
            controlChannel = nil
            interruptChannel = nil
            device?.closeConnection()
            device = nil
            connectedAddress = nil
            isReady = false
            isConnecting = false
        }

        public func send(_ id: UInt8, _ data: Data) {
            _sendInputReport(id, payload: data)
        }

        public func updateBatteryLevel(_ level: UInt8) {
            let clamped = min(level, 100)
            batteryLevel = clamped
            profile.battery(clamped)
            if let id = identity.batteryReportID { _sendInputReport(id, payload: Data([clamped])) }
        }

        private func _refreshState() {
            let host = IOBluetoothHostController.default()
            guard let power = host?.powerState else { state = .unknown; return }
            if power == kBluetoothHCIPowerStateON {
                state = .poweredOn
            } else if power == kBluetoothHCIPowerStateOFF {
                state = .poweredOff
            } else {
                state = .unknown
            }
        }

        private nonisolated static func _canonicalAddress(_ raw: String) -> String {
            raw.lowercased().filter(\.isHexDigit)
        }

        private func _canonicalAddress(_ raw: String) -> String {
            Self._canonicalAddress(raw)
        }

        private func _lookup(addressID: String) -> IOBluetoothDevice? {
            // pairedDevices() can return stale reference
            let formatted = _formatAddressForLookup(addressID)
            return IOBluetoothDevice(addressString: formatted)
        }

        private func _formatAddressForLookup(_ canonical: String) -> String {
            canonical.groupedInPairs(separator: "-")
        }

        private func _sendInputReport(_ reportID: UInt8, payload: Data) {
            lastReports[reportID] = payload
            guard let interruptChannel else { return }
            var buffer = Data(capacity: 2 + payload.count)
            buffer.append(0xA1)
            buffer.append(reportID)
            buffer.append(payload)
            let length = UInt16(buffer.count)
            buffer.withUnsafeMutableBytes { raw in
                guard let base = raw.baseAddress else { return }
                let status = interruptChannel.writeAsync(base, length: length, refcon: nil)
                if status != kIOReturnSuccess {
                    lastError = L10n.ErrorMessage.writeFailed(Self._ioReturnCode(status))
                    log.error("writeAsync interrupt failed \(Self._ioReturnCode(status), privacy: .public)")
                }
            }
        }

        fileprivate nonisolated static func _ioReturnCode(_ code: IOReturn) -> String {
            String(format: "0x%08X", UInt32(bitPattern: code))
        }
    }

    extension HIDClassicDevice: @preconcurrency IOBluetoothL2CAPChannelDelegate {
        public func l2capChannelOpenComplete(_ channel: IOBluetoothL2CAPChannel!, status error: IOReturn) {
            if error != kIOReturnSuccess {
                lastError = L10n.ErrorMessage.openL2CAPFailed(UInt16(channel?.psm ?? 0), Self._ioReturnCode(error))
            }
        }

        public func l2capChannelClosed(_ channel: IOBluetoothL2CAPChannel!) {
            if channel === controlChannel { controlChannel = nil }
            if channel === interruptChannel { interruptChannel = nil }
            if controlChannel == nil, interruptChannel == nil {
                profile.disconnect()
                isReady = false
                connectedAddress = nil
            }
        }

        public func l2capChannelReconfigured(_ channel: IOBluetoothL2CAPChannel!) {}

        public func l2capChannelData(
            _ channel: IOBluetoothL2CAPChannel!,
            data dataPointer: UnsafeMutableRawPointer!,
            length dataLength: Int
        ) {
            let bytes = Data(bytes: dataPointer, count: dataLength)
            _handleHostMessage(on: channel, bytes: bytes)
        }

        public func l2capChannelWriteComplete(
            _ channel: IOBluetoothL2CAPChannel!,
            refcon: UnsafeMutableRawPointer!,
            status error: IOReturn
        ) {
            if error != kIOReturnSuccess {
                log.error("writeComplete error: \(Self._ioReturnCode(error), privacy: .public)")
            }
        }

        private func _handleHostMessage(on channel: IOBluetoothL2CAPChannel, bytes: Data) {
            guard let header = bytes.first else { return }
            switch header & 0xF0 {
            case 0x00:
                break
            case 0x10:
                if header & 0x0F == 0x05 { disconnect() }
            case 0x40:
                _handleGetReport(bytes)
            case 0x50:
                _applyOutputReport(bytes)
                _sendControlHandshake(status: .successful)
            case 0x60:
                _sendControlData(header: 0xA0, payload: Data([protocolMode]))
            case 0x70:
                protocolMode = header & 0x01
                _sendControlHandshake(status: .successful)
            case 0x80:
                _sendControlData(header: 0xA0, payload: Data([idleRate]))
            case 0x90:
                if bytes.count >= 2 { idleRate = bytes[1] }
                _sendControlHandshake(status: .successful)
            case 0xA0:
                _applyOutputReport(bytes)
            default:
                _sendControlHandshake(status: .errUnsupportedRequest)
            }
        }

        private func _handleGetReport(_ bytes: Data) {
            let reportType = bytes[0] & 0x03
            let reportID = bytes.count >= 2 ? bytes[1] : 0
            let payload: Data?
            switch ReportType(rawValue: reportType) {
            case .input: payload = lastReports[reportID]
            case .feature where identity.reports.contains { $0.type == .feature }: payload = profile.feature(reportID)
            default:
                _sendControlHandshake(status: .errUnsupportedRequest)
                return
            }
            guard let payload else {
                _sendControlHandshake(status: .errInvalidReportID)
                return
            }
            _sendControlData(header: 0xA0 | reportType, payload: Data([reportID]) + payload)
        }

        private func _applyOutputReport(_ bytes: Data) {
            guard bytes[0] & 0x03 == 0x02, bytes.count >= 3 else { return }
            profile.output(bytes[1], Data(bytes.dropFirst(2)))
        }

        private enum HandshakeStatus: UInt8 {
            case successful = 0x00
            case notReady = 0x01
            case errInvalidReportID = 0x02
            case errUnsupportedRequest = 0x03
            case errInvalidParameter = 0x04
            case errUnknown = 0x0E
            case errFatal = 0x0F
        }

        private func _sendControlHandshake(status: HandshakeStatus) {
            guard let controlChannel else { return }
            var byte: UInt8 = status.rawValue
            withUnsafeMutablePointer(to: &byte) { ptr in
                _ = controlChannel.writeAsync(UnsafeMutableRawPointer(ptr), length: 1, refcon: nil)
            }
        }

        private func _sendControlData(header: UInt8, payload: Data) {
            guard let controlChannel else { return }
            var buffer = Data([header])
            buffer.append(payload)
            let length = UInt16(buffer.count)
            buffer.withUnsafeMutableBytes { raw in
                guard let base = raw.baseAddress else { return }
                _ = controlChannel.writeAsync(base, length: length, refcon: nil)
            }
        }
    }

    public struct PairedDevice: Identifiable, Equatable, Codable {
        public let id: String
        public let name: String
        public var isConnected: Bool = false
        public var displayAddress: String {
            id.uppercased().groupedInPairs(separator: ":")
        }

        private enum CodingKeys: String, CodingKey { case id, name }
    }

    private extension String {
        func groupedInPairs(separator: String) -> String {
            stride(from: 0, to: count, by: 2).map {
                let start = index(startIndex, offsetBy: $0)
                let end = index(start, offsetBy: 2, limitedBy: endIndex) ?? endIndex
                return String(self[start ..< end])
            }.joined(separator: separator)
        }
    }
#endif
