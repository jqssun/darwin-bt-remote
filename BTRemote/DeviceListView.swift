import BTHIDKit
import CoreBluetooth
import SwiftUI

private enum SortField: Hashable {
    case name, signal

    var label: LocalizedStringKey {
        switch self {
        case .name: L10n.DeviceInfo.name
        case .signal: L10n.DeviceInfo.signal
        }
    }
}

struct DeviceListView: View {
    @EnvironmentObject private var central: HIDCentral
    @State private var selectedInfo: DeviceEntry?
    @State private var sortField: SortField = .name
    @State private var sortAscending = false

    var body: some View {
        Form {
            Section {
                if central.isScanning {
                    Button(role: .destructive) { central.stopScan() } label: {
                        Label(L10n.Action.stopScanning, systemImage: "stop.circle")
                    }
                } else {
                    Button { central.startScan() } label: {
                        Label(L10n.Action.scanNearbyDevices, systemImage: "magnifyingglass")
                    }
                }
            }
            Section {
                ForEach(_devices) { deviceRow($0) }
                if _devices.isEmpty, !central.isScanning {
                    Text(L10n.Device.emptyState)
                        .font(.caption).foregroundColor(.secondary)
                }
            } footer: {
                if !_devices.isEmpty {
                    Text(L10n.Device.connectedLegend)
                }
            }
        }
        #if os(macOS)
        .formStyle(.grouped)
        #endif
        .navigationTitle(L10n.Section.devices)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .toolbar { sortMenu }
            .sheet(item: $selectedInfo) { DeviceInfoView(entry: $0) }
            .onAppear { central.startScan() }
            .onDisappear { central.stopScan() }
    }

    @ToolbarContentBuilder
    private var sortMenu: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Picker(L10n.Sort.title, selection: $sortField) {
                    Text(SortField.name.label).tag(SortField.name)
                    Text(SortField.signal.label).tag(SortField.signal)
                }
                .pickerStyle(.inline)
                Picker(L10n.Sort.direction, selection: $sortAscending) {
                    Text(L10n.Sort.ascending).tag(true)
                    Text(L10n.Sort.descending).tag(false)
                }
                .pickerStyle(.inline)
            } label: {
                Label(L10n.Sort.title, systemImage: "ellipsis")
            }
        }
    }

    private var _devices: [DeviceEntry] {
        central.discovered
            .map { peripheral in
                DeviceEntry(
                    id: peripheral.id,
                    name: peripheral.name,
                    isNamed: peripheral.isNamed,
                    rssi: peripheral.rssi,
                    advertisedServices: peripheral.advertisedServices,
                    companyID: peripheral.companyID,
                    txPower: peripheral.txPower,
                    isConnectable: peripheral.isConnectable,
                    isHostConnected: false,
                    isCentralConnected: central.connected.contains(peripheral.id),
                    isConnecting: central.connecting.contains(peripheral.id),
                    isSubscribed: false,
                    isActive: true
                )
            }
            .sorted(by: _isOrderedBefore)
    }

    private func _isOrderedBefore(_ lhs: DeviceEntry, _ rhs: DeviceEntry) -> Bool {
        let ascending: Bool
        switch sortField {
        case .name:
            let cmp = lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName)
            guard cmp != .orderedSame else { return lhs.id.uuidString < rhs.id.uuidString }
            ascending = cmp == .orderedAscending
        case .signal:
            guard lhs.rssi != rhs.rssi else { return lhs.id.uuidString < rhs.id.uuidString }
            ascending = lhs.rssi < rhs.rssi
        }
        return ascending == sortAscending
    }

    private func deviceRow(_ entry: DeviceEntry) -> some View {
        DeviceRow(
            entry: entry,
            accessibilityLabel: entry.isLive
                ? L10n.Device.disconnectAccessibilityLabel(entry.displayName)
                : L10n.Device.connectAccessibilityLabel(entry.displayName),
            action: {
                if entry.isCentralConnected {
                    central.disconnect(entry.id)
                } else {
                    central.connect(entry.id)
                }
            },
            onInfo: { selectedInfo = entry }
        ) {
            if entry.rssi != 0 {
                Text(verbatim: L10n.Device.rssi(entry.rssi)).font(.caption).foregroundColor(.secondary)
            }
        }
    }
}

#if DEBUG
    #Preview {
        DeviceListView()
            .environmentObject(HIDPeripheral(profile: Combo()))
            .environmentObject(HIDCentral())
            .environmentObject(DeviceNameStore())
    }
#endif
