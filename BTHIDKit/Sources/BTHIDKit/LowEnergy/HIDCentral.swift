import Combine
import CoreBluetooth
import Foundation
import os

@MainActor
public final class HIDCentral: NSObject, ObservableObject {
    @Published public private(set) var state: CBManagerState = .unknown
    @Published public private(set) var isScanning = false
    @Published public private(set) var discovered: [DiscoveredPeripheral] = []
    @Published public private(set) var connected: Set<UUID> = []
    @Published public private(set) var connecting: Set<UUID> = []
    @Published public private(set) var lastError: String?

    static let restoreIdentifier = "central"

    private let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "HIDCentral")
    private var centralManager: CBCentralManager?
    private var peripheralCache: [UUID: CBPeripheral] = [:]

    private func _trace(_ message: @autoclosure () -> String) {
        guard UserDefaults.standard.bool(forKey: HIDSettings.developerModeKey) else { return }
        let text = message()
        log.info("\(text, privacy: .public)")
    }

    public func start() {
        guard centralManager == nil else { return }
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [
                CBCentralManagerOptionRestoreIdentifierKey: HIDCentral.restoreIdentifier,
                CBCentralManagerOptionShowPowerAlertKey: true
            ]
        )
    }

    public func startScan() {
        guard let centralManager, centralManager.state == .poweredOn else {
            start()
            return
        }
        discovered.removeAll()
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        isScanning = true
        _trace("scan started")
    }

    public func stopScan() {
        centralManager?.stopScan()
        isScanning = false
        _trace("scan stopped")
    }

    public func connect(_ identifier: UUID) {
        guard let centralManager else { return }
        let peripheral = peripheralCache[identifier]
            ?? centralManager.retrievePeripherals(withIdentifiers: [identifier]).first
        guard let peripheral else {
            lastError = L10n.ErrorMessage.peripheralNotRetained(identifier)
            return
        }
        peripheralCache[identifier] = peripheral
        connecting.insert(identifier)
        centralManager.connect(peripheral, options: [
            CBConnectPeripheralOptionNotifyOnConnectionKey: true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
        ])
        _trace("connect requested: \(peripheral.identifier)")
    }

    public func disconnect(_ identifier: UUID) {
        guard let centralManager, let peripheral = peripheralCache[identifier] else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }

    func refreshKnownPeripherals(servicesFilter: [CBUUID] = [GATT.hidService]) {
        guard let centralManager else { return }
        let known = centralManager.retrieveConnectedPeripherals(withServices: servicesFilter)
        for peripheral in known {
            peripheralCache[peripheral.identifier] = peripheral
            upsertDiscovered(peripheral: peripheral, advertisementData: [:], rssi: 0)
        }
    }

    private func upsertDiscovered(
        peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi: Int
    ) {
        let resolvedName = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? peripheral.name
        let services = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]) ?? []
        let companyID = Self.companyID(from: advertisementData)
        let txPower = (advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber)?.intValue
        let isConnectable = (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue
        _trace(
            "discovered: \(peripheral.identifier) name=\(resolvedName ?? "nil") company=\(companyID ?? 0) services=\(services) rssi=\(rssi)"
        )
        let entry = DiscoveredPeripheral(
            id: peripheral.identifier,
            name: resolvedName ?? L10n.Device.unknownName,
            isNamed: resolvedName != nil,
            rssi: rssi,
            advertisedServices: services,
            companyID: companyID,
            txPower: txPower,
            isConnectable: isConnectable
        )
        if let index = discovered.firstIndex(where: { $0.id == entry.id }) {
            let existing = discovered[index]
            discovered[index] = DiscoveredPeripheral(
                id: entry.id,
                name: entry.isNamed ? entry.name : existing.name,
                isNamed: existing.isNamed || entry.isNamed,
                rssi: rssi == 0 ? existing.rssi : rssi,
                advertisedServices: services.isEmpty ? existing.advertisedServices : services,
                companyID: companyID ?? existing.companyID,
                txPower: txPower ?? existing.txPower,
                isConnectable: isConnectable ?? existing.isConnectable
            )
        } else {
            discovered.append(entry)
        }
    }

    private static func companyID(from advertisementData: [String: Any]) -> UInt16? {
        guard let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data, data.count >= 2 else { return nil }
        let bytes = [UInt8](data.prefix(2))
        return UInt16(bytes[0]) | (UInt16(bytes[1]) << 8)
    }
}

public struct DiscoveredPeripheral: Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var isNamed: Bool
    public var rssi: Int
    public var advertisedServices: [CBUUID]
    public var companyID: UInt16?
    public var txPower: Int?
    public var isConnectable: Bool?
}

extension HIDCentral: @preconcurrency CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        state = central.state
        _trace("central state -> \(central.state.rawValue)")
        if central.state == .poweredOn {
            // must happen before HID services added
            #if os(iOS)
                central.registerForConnectionEvents(options: nil)
            #endif
            refreshKnownPeripherals()
        }
        if central.state != .poweredOn {
            isScanning = false
            connected.removeAll()
            connecting.removeAll()
        }
    }

    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        _trace("central willRestoreState: \(dict.keys.sorted())")
        if let restored = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for peripheral in restored {
                peripheralCache[peripheral.identifier] = peripheral
            }
        }
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        peripheralCache[peripheral.identifier] = peripheral
        upsertDiscovered(
            peripheral: peripheral,
            advertisementData: advertisementData,
            rssi: RSSI.intValue
        )
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connecting.remove(peripheral.identifier)
        connected.insert(peripheral.identifier)
        _trace("connected: \(peripheral.identifier)")
        peripheralCache[peripheral.identifier] = peripheral
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        connecting.remove(peripheral.identifier)
        connected.remove(peripheral.identifier)
        if let error {
            log.error("disconnected with error: \(error.localizedDescription, privacy: .public)")
            lastError = error.localizedDescription
        } else {
            _trace("disconnected: \(peripheral.identifier)")
        }
    }

    public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        connecting.remove(peripheral.identifier)
        if let error {
            lastError = L10n.ErrorMessage.failedToConnect(error.localizedDescription)
            log.error("failed to connect: \(error.localizedDescription, privacy: .public)")
        }
    }
}
