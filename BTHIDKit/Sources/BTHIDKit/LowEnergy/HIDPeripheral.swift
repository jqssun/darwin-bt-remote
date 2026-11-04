import Combine
import CoreBluetooth
import os
import SwiftUI

@MainActor
public final class HIDPeripheral: NSObject, ObservableObject {
    @Published public private(set) var state: CBManagerState = .unknown
    @Published public private(set) var isAdvertising = false
    @Published public private(set) var isHIDServiceAdded = false
    @Published public private(set) var subscribedCentrals: [UUID: Set<CBUUID>] = [:]
    /// broadcasts skip inactive hosts
    @Published public private(set) var inactiveCentrals: Set<UUID> = []
    @Published public private(set) var connectedCentrals: Set<UUID> = []
    @Published public private(set) var lastError: String?
    @Published public private(set) var batteryLevel: UInt8 = 100

    public let profile: any HIDProfile
    private var identity: HIDIdentity {
        profile.identity
    }

    private var centralObjects: [UUID: CBCentral] = [:]

    public var advertisedName: String

    public var localName: String {
        identity.isNameEditable ? advertisedName : identity.name
    }

    private let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "HIDPeripheral")
    private var pManager: CBPeripheralManager?
    private var batteryServiceObj: CBMutableService?
    private var deviceInfoServiceObj: CBMutableService?
    private var hidServiceObj: CBMutableService?
    private var isHIDServiceAllowed = false
    private var isReadyToSendNotification = true

    private var charsByReport: [HIDReport: CBMutableCharacteristic] = [:]
    private var bootMouseInputChar: CBMutableCharacteristic?
    private var bootKeyboardInputChar: CBMutableCharacteristic?
    private var bootKeyboardOutputChar: CBMutableCharacteristic?
    private var batteryLevelChar: CBMutableCharacteristic?
    private var serviceChangedObj: CBMutableService?
    private var serviceChangedArmed = false
    private static let serviceChangedGrace: UInt64 = 2_000_000_000

    /// replayed on reads + new subscriptions
    private var cachedReports: [UInt8: Data]

    private var pendingBroadcast: (Data, CBMutableCharacteristic)?

    public init(profile: any HIDProfile) {
        self.profile = profile
        advertisedName = UserDefaults.standard.string(forKey: HIDSettings.advertisedNameKey) ?? profile.identity.name
        cachedReports = profile.identity.seedReports
        super.init()
    }

    public func start() {
        isHIDServiceAllowed = true
        if pManager == nil {
            pManager = CBPeripheralManager(
                delegate: self,
                queue: nil,
                options: [CBPeripheralManagerOptionShowPowerAlertKey: true]
            )
        } else if state == .poweredOn {
            if isHIDServiceAdded {
                startAdvertisingNow()
            } else {
                installServices()
            }
        }
    }

    public func stop() {
        isHIDServiceAllowed = false
        pManager?.stopAdvertising()
        isAdvertising = false
    }

    public func promptPowerAlert() {
        guard state != .poweredOn else { return }
        _resetForRestart()
        start()
    }

    private func _resetForRestart() {
        profile.disconnect()
        pManager?.stopAdvertising()
        pManager = nil
        isAdvertising = false
        isHIDServiceAdded = false
        isReadyToSendNotification = true
        pendingBroadcast = nil
        batteryServiceObj = nil
        deviceInfoServiceObj = nil
        hidServiceObj = nil
        serviceChangedObj = nil
        serviceChangedArmed = false
        batteryLevelChar = nil
        bootMouseInputChar = nil
        bootKeyboardInputChar = nil
        bootKeyboardOutputChar = nil
        charsByReport.removeAll()
        subscribedCentrals.removeAll()
        inactiveCentrals.removeAll()
        connectedCentrals.removeAll()
        centralObjects.removeAll()
    }

    public func send(_ id: UInt8, _ data: Data) {
        broadcast(data, reportID: id)
        if id == identity.boot?.keyboard {
            bootKeyboardInputChar.map { _ = updateValue(data, for: $0) }
        }
    }

    public func toggleActive(_ uuid: UUID) {
        if inactiveCentrals.contains(uuid) {
            inactiveCentrals.remove(uuid)
        } else {
            inactiveCentrals.insert(uuid)
        }
    }

    public func updateBatteryLevel(_ level: UInt8) {
        let clamped = min(level, 100)
        batteryLevel = clamped
        profile.battery(clamped)
        let asHIDReport = Data([clamped])
        if let id = identity.batteryReportID { cachedReports[id] = asHIDReport }
        if let batteryLevelChar { _ = updateValue(asHIDReport, for: batteryLevelChar) }
    }

    /// cycle temp service to fix stale GATT cache
    public func scheduleServiceChanged() {
        guard UserDefaults.standard.bool(forKey: HIDSettings.forceServiceChangedKey), !serviceChangedArmed else { return }
        serviceChangedArmed = true
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: Self.serviceChangedGrace)
            self?._cycleServiceChangedIfUnsubscribed()
        }
    }

    private func _cycleServiceChangedIfUnsubscribed() {
        guard subscribedCentrals.isEmpty else { return }
        _cycleServiceChanged()
    }

    private func _cycleServiceChanged() {
        guard let pManager else { return }
        if let svc = serviceChangedObj {
            pManager.remove(svc)
            pManager.add(svc)
        } else {
            let svc = buildServiceChangedTrigger()
            serviceChangedObj = svc
            pManager.add(svc)
        }
        _trace("Service Changed cycled")
    }

    private func buildServiceChangedTrigger() -> CBMutableService {
        let service = CBMutableService(type: CBUUID(nsuuid: UUID()), primary: true)
        service.characteristics = [
            CBMutableCharacteristic(
                type: CBUUID(nsuuid: UUID()),
                properties: [.read, .notifyEncryptionRequired],
                value: nil,
                permissions: .readEncryptionRequired
            )
        ]
        return service
    }

    private func installServices() {
        guard let pManager, !isHIDServiceAdded, batteryServiceObj == nil else { return }
        let battery = buildBatteryService()
        batteryServiceObj = battery
        pManager.add(battery)
    }

    private func buildDeviceInfoService() -> CBMutableService {
        let service = CBMutableService(type: GATT.deviceInformationService, primary: true)
        service.characteristics = [
            CBMutableCharacteristic(
                type: GATT.manufacturerName,
                properties: .read,
                value: Data(identity.manufacturer.utf8),
                permissions: .readable
            ),
            CBMutableCharacteristic(
                type: GATT.modelNumber,
                properties: .read,
                value: Data(identity.model.utf8),
                permissions: .readable
            ),
            CBMutableCharacteristic(
                type: GATT.pnpID,
                properties: .read,
                value: identity.pnp.data,
                permissions: .readable
            )
        ]
        return service
    }

    private func buildBatteryService() -> CBMutableService {
        let service = CBMutableService(type: GATT.batteryService, primary: true)
        let level = CBMutableCharacteristic(
            type: GATT.batteryLevel,
            properties: [.read, .notifyEncryptionRequired],
            value: nil,
            permissions: .readEncryptionRequired
        )
        if let id = identity.batteryReportID {
            let reportRef = CBMutableDescriptor(
                type: GATT.reportReference,
                value: NSData(data: HIDReport(id, .input).reference)
            )
            level.descriptors = [reportRef]
        }
        service.characteristics = [level]
        batteryLevelChar = level
        return service
    }

    private func buildHIDService(includingBattery battery: CBMutableService?) -> CBMutableService {
        let service = CBMutableService(type: GATT.hidService, primary: true)
        if let battery { service.includedServices = [battery] }

        let controlPoint = CBMutableCharacteristic(
            type: GATT.hidControlPoint,
            properties: .read,
            value: nil,
            permissions: .readEncryptionRequired
        )

        let protocolMode = CBMutableCharacteristic(
            type: GATT.protocolMode,
            properties: [.read, .writeWithoutResponse],
            value: nil,
            permissions: [.readEncryptionRequired, .writeEncryptionRequired]
        )

        let hidInfo = CBMutableCharacteristic(
            type: GATT.hidInformation,
            properties: .read,
            value: identity.hidInformation,
            permissions: .readEncryptionRequired
        )

        let reportMap = CBMutableCharacteristic(
            type: GATT.reportMap,
            properties: .read,
            value: identity.reportMap,
            permissions: .readEncryptionRequired
        )
        if identity.batteryReportID != nil {
            reportMap.descriptors = [
                CBMutableDescriptor(
                    type: GATT.externalReportReference,
                    value: NSData(data: GATT.externalReportReferenceValue)
                )
            ]
        }

        // report characteristic order matters
        let reportChars = identity.reports.map { report in
            let char = makeReportChar(report)
            charsByReport[report] = char
            return char
        }

        service.characteristics = [controlPoint, protocolMode, hidInfo] + buildBootChars() + [reportMap] + reportChars
        return service
    }

    private func buildBootChars() -> [CBMutableCharacteristic] {
        guard identity.boot != nil else { return [] }
        let bootMouseInput = CBMutableCharacteristic(
            type: GATT.bootMouseInputReport,
            properties: [.read, .notifyEncryptionRequired],
            value: nil,
            permissions: [.readEncryptionRequired, .writeEncryptionRequired]
        )
        let bootKbdInput = CBMutableCharacteristic(
            type: GATT.bootKeyboardInputReport,
            properties: [.read, .notifyEncryptionRequired],
            value: nil,
            permissions: [.readEncryptionRequired, .writeEncryptionRequired]
        )
        let bootKbdOutput = CBMutableCharacteristic(
            type: GATT.bootKeyboardOutputReport,
            properties: [.read, .writeWithoutResponse, .write],
            value: nil,
            permissions: [.readEncryptionRequired, .writeEncryptionRequired]
        )
        bootMouseInputChar = bootMouseInput
        bootKeyboardInputChar = bootKbdInput
        bootKeyboardOutputChar = bootKbdOutput
        return [bootMouseInput, bootKbdInput, bootKbdOutput]
    }

    private func makeReportChar(_ report: HIDReport) -> CBMutableCharacteristic {
        let char = switch report.type {
        case .input:
            CBMutableCharacteristic(
                type: GATT.report,
                properties: [.read, .notifyEncryptionRequired],
                value: nil,
                permissions: .readEncryptionRequired
            )
        case .output, .feature:
            CBMutableCharacteristic(
                type: GATT.report,
                properties: report.type == .output ? [.read, .writeWithoutResponse, .write] : [.read, .write],
                value: nil,
                permissions: [.readEncryptionRequired, .writeEncryptionRequired]
            )
        }
        char.descriptors = [
            CBMutableDescriptor(type: GATT.reportReference, value: NSData(data: report.reference))
        ]
        return char
    }

    private func startAdvertisingNow() {
        guard let pManager, !isAdvertising else { return }
        pManager.startAdvertising([
            CBAdvertisementDataLocalNameKey: localName,
            // hidService stays first
            CBAdvertisementDataServiceUUIDsKey: [GATT.hidServiceAdvertised]
        ])
    }

    private func broadcast(_ data: Data, reportID: UInt8) {
        cachedReports[reportID] = data
        guard let char = charsByReport[HIDReport(reportID, .input)] else { return }
        _ = updateValue(data, for: char)
    }

    @discardableResult
    private func updateValue(_ data: Data, for char: CBMutableCharacteristic) -> Bool {
        guard let pManager else { return false }
        let recipients = activeRecipients()
        guard !recipients.isEmpty else { return false }
        if !isReadyToSendNotification {
            pendingBroadcast = (data, char)
            return false
        }
        let accepted = pManager.updateValue(data, for: char, onSubscribedCentrals: recipients)
        if !accepted {
            isReadyToSendNotification = false
            pendingBroadcast = (data, char)
        }
        return accepted
    }

    private func drainPendingBroadcast() {
        guard let (data, char) = pendingBroadcast, let pManager else { return }
        pendingBroadcast = nil
        let recipients = activeRecipients()
        guard !recipients.isEmpty else { return }
        let accepted = pManager.updateValue(data, for: char, onSubscribedCentrals: recipients)
        if !accepted {
            isReadyToSendNotification = false
            pendingBroadcast = (data, char)
        }
    }

    private func _trace(_ message: @autoclosure () -> String) {
        guard UserDefaults.standard.bool(forKey: HIDSettings.developerModeKey) else { return }
        let text = message()
        log.info("\(text, privacy: .public)")
    }

    private func _trackInteraction(from central: CBCentral) {
        centralObjects[central.identifier] = central
        guard !connectedCentrals.contains(central.identifier) else { return }
        connectedCentrals.insert(central.identifier)
        _trace("central tracked: \(central.identifier)")
    }

    private func activeRecipients() -> [CBCentral] {
        subscribedCentrals.keys
            .filter { !inactiveCentrals.contains($0) }
            .compactMap { centralObjects[$0] }
    }

    private func report(forCharacteristic char: CBCharacteristic) -> HIDReport? {
        for (report, c) in charsByReport where c.uuid == char.uuid && c === char as AnyObject {
            return report
        }
        // fallback for restored characteristics
        if char.uuid == GATT.report,
           let descriptor = (char as? CBMutableCharacteristic)?
           .descriptors?
           .first(where: { $0.uuid == GATT.reportReference }),
           let value = descriptor.value as? Data,
           value.count >= 2,
           let type = ReportType(rawValue: value[value.startIndex + 1])
        {
            return HIDReport(value[value.startIndex], type)
        }
        return nil
    }
}

extension HIDPeripheral: @preconcurrency CBPeripheralManagerDelegate {
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        state = peripheral.state
        _trace("CB state -> \(peripheral.state.rawValue)")
        if peripheral.state == .poweredOn, isHIDServiceAllowed, !isHIDServiceAdded {
            installServices()
        }
        if peripheral.state != .poweredOn {
            isAdvertising = false
        }
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error {
            log.error("didAddService(\(service.uuid)) error: \(error.localizedDescription, privacy: .public)")
            lastError = error.localizedDescription
        }
        switch service.uuid {
        case GATT.batteryService:
            let dis = buildDeviceInfoService()
            deviceInfoServiceObj = dis
            peripheral.add(dis)
        case GATT.deviceInformationService:
            let hid = buildHIDService(includingBattery: batteryServiceObj)
            hidServiceObj = hid
            peripheral.add(hid)
        case GATT.hidService:
            isHIDServiceAdded = true
            startAdvertisingNow()
        default:
            break
        }
    }

    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error {
            isAdvertising = false
            lastError = error.localizedDescription
            log.error("startAdvertising error: \(error.localizedDescription, privacy: .public)")
        } else {
            isAdvertising = true
            _trace("advertising as \(localName)")
        }
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        _trackInteraction(from: central)
        subscribedCentrals[central.identifier, default: []].insert(characteristic.uuid)
        _trace("subscribe: \(central.identifier) -> \(characteristic.uuid)")
        let boot = identity.boot
        if let report = report(forCharacteristic: characteristic),
           let cached = cachedReports[report.id],
           let char = charsByReport[report]
        {
            _ = updateValue(cached, for: char)
        } else if characteristic.uuid == GATT.bootMouseInputReport, let bootMouseInputChar,
                  let zero = boot.flatMap({ identity.seedReports[$0.mouse] })
        {
            _ = updateValue(zero, for: bootMouseInputChar)
        } else if characteristic.uuid == GATT.bootKeyboardInputReport, let bootKeyboardInputChar,
                  let zero = boot.flatMap({ identity.seedReports[$0.keyboard] })
        {
            _ = updateValue(zero, for: bootKeyboardInputChar)
        } else if characteristic.uuid == GATT.batteryLevel, let batteryLevelChar {
            _ = updateValue(Data([batteryLevel]), for: batteryLevelChar)
        }
        // CoreBluetooth exposes no central address
        if characteristic.uuid == GATT.report {
            profile.connect(host: nil) { [weak self] id, data in self?.send(id, data) }
        }
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        _trace("unsubscribe: \(central.identifier) <- \(characteristic.uuid)")
        guard var chars = subscribedCentrals[central.identifier] else { return }
        chars.remove(characteristic.uuid)
        if chars.isEmpty {
            subscribedCentrals.removeValue(forKey: central.identifier)
            centralObjects.removeValue(forKey: central.identifier)
            inactiveCentrals.remove(central.identifier)
            connectedCentrals.remove(central.identifier)
            serviceChangedArmed = false
        } else {
            subscribedCentrals[central.identifier] = chars
        }
        if subscribedCentrals.isEmpty { profile.disconnect() }
    }

    public func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        isReadyToSendNotification = true
        drainPendingBroadcast()
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        _trace("read: \(request.central.identifier) -> \(request.characteristic.uuid)")
        _trackInteraction(from: request.central)
        scheduleServiceChanged()
        let value = readValue(forRequest: request)
        guard let value else {
            peripheral.respond(to: request, withResult: .invalidAttributeValueLength)
            return
        }
        guard request.offset <= value.count else {
            peripheral.respond(to: request, withResult: .invalidOffset)
            return
        }
        request.value = value.subdata(in: request.offset ..< value.count)
        peripheral.respond(to: request, withResult: .success)
    }

    private func readValue(forRequest request: CBATTRequest) -> Data? {
        switch request.characteristic.uuid {
        case GATT.batteryLevel: return Data([batteryLevel])
        case GATT.hidInformation: return identity.hidInformation
        case GATT.reportMap: return identity.reportMap
        case GATT.protocolMode: return Data([0x01])
        case GATT.manufacturerName: return Data(identity.manufacturer.utf8)
        case GATT.modelNumber: return Data(identity.model.utf8)
        case GATT.pnpID: return identity.pnp.data
        case GATT.report:
            guard let report = report(forCharacteristic: request.characteristic) else { return Data() }
            switch report.type {
            case .input: return cachedReports[report.id] ?? Data()
            case .output: return Data()
            case .feature: return profile.feature(report.id)
            }
        case GATT.bootMouseInputReport: return identity.boot.flatMap { cachedReports[$0.mouse] }
        case GATT.bootKeyboardInputReport: return identity.boot.flatMap { cachedReports[$0.keyboard] }
        default: return Data()
        }
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            _trace("write: \(request.central.identifier) -> \(request.characteristic.uuid)")
            _trackInteraction(from: request.central)
            handleWriteRequest(request)
        }
        if let first = requests.first {
            peripheral.respond(to: first, withResult: .success)
        }
    }

    private func handleWriteRequest(_ request: CBATTRequest) {
        guard let value = request.value else { return }
        switch request.characteristic.uuid {
        case GATT.bootKeyboardOutputReport:
            if let id = identity.boot?.keyboardLEDs { profile.output(id, value) }
        case GATT.report:
            if let report = report(forCharacteristic: request.characteristic), report.type == .output {
                profile.output(report.id, value)
            }
        case GATT.protocolMode, GATT.hidControlPoint:
            break
        default:
            break
        }
    }
}
