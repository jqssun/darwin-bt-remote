import CoreBluetooth
import SwiftUI

struct DeviceRow<Trailing: View>: View {
    let entry: DeviceEntry
    var accessibilityLabel: String?
    let action: () -> Void
    let onInfo: () -> Void
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack {
            Button(action: action) {
                HStack {
                    RowLeadingStatus(phase: entry.isConnecting ? .connecting : (entry.isCentralConnected ? .active : .idle))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: entry.displayName).foregroundColor(.primary)
                        Text(verbatim: entry.id.uuidString)
                            .font(.caption2).foregroundColor(.secondary).lineLimit(1)
                    }
                    Spacer()
                    trailing()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text(verbatim: accessibilityLabel ?? entry.displayName))

            Button(action: onInfo) {
                Image(systemName: "info.circle").foregroundColor(.accentColor)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(L10n.DeviceInfo.info)
        }
    }
}

struct DeviceEntry: Identifiable, Equatable {
    let id: UUID
    let name: String
    let isNamed: Bool
    let rssi: Int
    let advertisedServices: [CBUUID]
    let companyID: UInt16?
    let txPower: Int?
    let isConnectable: Bool?
    let isHostConnected: Bool
    let isCentralConnected: Bool
    let isConnecting: Bool
    let isSubscribed: Bool
    let isActive: Bool

    var isLive: Bool {
        isCentralConnected || (isHostConnected && isActive)
    }

    var manufacturer: String? {
        companyID.flatMap { BluetoothNumbers.company($0) }
    }

    var displayName: String {
        if isNamed { return name }
        return "[\(manufacturer ?? L10n.Device.unknownManufacturer)]"
    }
}

struct RowLeadingStatus: View {
    enum Phase { case idle, connecting, active }
    let phase: Phase

    var body: some View {
        ZStack {
            switch phase {
            case .idle:
                Color.clear
            case .connecting:
                ProgressView()
            case .active:
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.accentColor)
            }
        }
        .frame(width: 22)
    }
}

struct ConnectedDeviceRow: View {
    let entry: DeviceEntry
    let onToggle: () -> Void
    let onInfo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if entry.isSubscribed {
                Button(action: onToggle) { label }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(Text(verbatim: entry.displayName))
            } else {
                label
            }
            Button(action: onInfo) {
                Image(systemName: "info.circle").foregroundColor(.accentColor)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(L10n.DeviceInfo.info)
        }
    }

    private var label: some View {
        HStack(spacing: 12) {
            RowLeadingStatus(phase: entry.isActive ? .active : .idle)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: entry.displayName).foregroundColor(.primary)
                Text(verbatim: entry.id.uuidString)
                    .font(.caption2).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            if !entry.isSubscribed {
                Text(L10n.Device.notSubscribed).font(.caption).foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}
