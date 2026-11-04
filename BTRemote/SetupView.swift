import BTHIDKit
import CoreBluetooth
import SwiftUI
#if os(macOS)
    import AppKit
#endif

struct SetupView: View {
    @EnvironmentObject private var lowEnergy: HIDPeripheral
    @EnvironmentObject private var central: HIDCentral
    @EnvironmentObject private var names: DeviceNameStore
    @AppStorage(HIDSettings.developerModeKey) private var developerMode = false
    @AppStorage(HIDSettings.advertisedNameKey) private var advertisedName = L10n.Bluetooth.advertisedName
    @State private var selectedInfo: DeviceEntry?
    #if os(macOS)
        @State private var showBluetoothOff = false
    #endif
    @EnvironmentObject private var directInput: DirectInputController
    #if os(macOS)
        @EnvironmentObject private var classic: HIDClassicDevice
        @AppStorage(AppSettings.transportKey) private var transport = Transport.lowEnergy
    #endif

    @Environment(\.hid) private var hid

    private var isClassic: Bool {
        #if os(macOS)
            return transport == .classic
        #else
            return false
        #endif
    }

    var body: some View {
        #if os(macOS)
            NavigationStack {
                form
                    .formStyle(.grouped)
                    .navigationTitle(L10n.App.title)
            }
            .onDisappear { directInput.stop() }
            .onChange(of: hid.isActive) { isActive in
                if !isActive { directInput.stop() }
            }
        #else
            NavigationView {
                form.navigationTitle(L10n.App.title)
            }
            .navigationViewStyle(.stack)
            .onChange(of: hid.isActive) { isActive in
                if !isActive { directInput.stop() }
            }
        #endif
    }

    private var form: some View {
        Form {
            guideSection
            #if os(macOS)
                transportSection
            #endif
            if isClassic {
                #if os(macOS)
                    pairedDevicesSection
                #endif
            } else {
                connectionSection
                if !lowEnergy.connectedCentrals.isEmpty {
                    connectedDevicesSection
                }
            }
            statusSection
            if hid.isActive { directInputSection }
            if let lastError = hid.activeError {
                Section(header: Text(L10n.Section.lastError)) {
                    Text(verbatim: lastError).foregroundColor(.red).font(.caption)
                }
            }
        }
        .sheet(item: $selectedInfo) { DeviceInfoView(entry: $0) }
        #if os(macOS)
            .alert(L10n.Setup.bluetoothOffTitle, isPresented: $showBluetoothOff) {
                Button(L10n.Action.settings) { _openBluetoothSettings() }
                Button(L10n.Action.notNow, role: .cancel) {}
            } message: {
                Text(L10n.Setup.bluetoothOffMessage)
            }
        #endif
    }

    private var guideSection: some View {
        Section(header: Text(L10n.Setup.help)) {
            NavigationLink { GuideView(transport: .lowEnergy) } label: {
                Label(L10n.Setup.lowEnergyGuide, systemImage: "questionmark.circle")
            }
            #if os(macOS)
                NavigationLink { GuideView(transport: .classic) } label: {
                    Label(L10n.Setup.classicGuide, systemImage: "questionmark.circle")
                }
            #endif
            Link(destination: AppSettings.instructionsURL) {
                Label(L10n.Setup.videoInstructions, systemImage: "play.circle")
            }
        }
    }

    #if os(macOS)
        private var transportSection: some View {
            Section {
                Text(isClassic ? L10n.TransportMode.classicCompatibility : L10n.TransportMode.lowEnergyCompatibility)
                    .font(.caption).foregroundColor(.secondary)
                Picker(selection: $transport) {
                    Text(L10n.TransportMode.lowEnergy).tag(Transport.lowEnergy)
                    Text(L10n.TransportMode.classic).tag(Transport.classic)
                } label: {
                    Text(L10n.TransportMode.label)
                }
                .pickerStyle(.segmented)
            } header: {
                Text(L10n.TransportMode.section)
            }
        }
    #endif

    private var statusSection: some View {
        Section(header: Text(L10n.Section.status)) {
            if isClassic {
                #if os(macOS)
                    row(L10n.Status.bluetooth, Text(classic.state.localizedLabel))
                    row(L10n.Classic.ready, Text(classic.isReady ? L10n.Value.yes : L10n.Value.no))
                    if developerMode {
                        row(L10n.Classic.sdpPublished, Text(classic.isSDPPublished ? L10n.Value.yes : L10n.Value.no))
                        (classic.profile as? Combo).map(HostLEDsRow.init)
                    }
                #else
                    EmptyView()
                #endif
            } else {
                advertisedNameRow
                row(L10n.Status.bluetooth, Text(lowEnergy.state.localizedLabel))
                row(L10n.Status.advertising, Text(lowEnergy.isAdvertising ? L10n.Value.yes : L10n.Value.no))
                if developerMode {
                    row(L10n.Status.hidService, Text(lowEnergy.isHIDServiceAdded ? L10n.Status.hidServiceAdded : L10n.Value.none))
                    row(L10n.Status.subscribedCentrals, Text(lowEnergy.subscribedCentrals.count, format: .number))
                    row(L10n.Status.connectedPeripherals, Text(central.connected.count, format: .number))
                    (lowEnergy.profile as? Combo).map(HostLEDsRow.init)
                }
            }
        }
    }

    private var advertisedNameRow: some View {
        NavigationLink {
            NameEditView(
                title: L10n.Setup.advertisedName,
                footer: L10n.Setup.advertisedNameHint,
                maxLength: AppSettings.maxAdvertisedNameLength,
                name: $advertisedName,
                onCommit: _applyAdvertisedName
            )
        } label: {
            HStack {
                Text(L10n.Setup.advertisedName)
                Spacer()
                Text(verbatim: advertisedName).foregroundColor(.secondary)
            }
        }
    }

    private func _applyAdvertisedName() {
        if advertisedName.isEmpty { advertisedName = L10n.Bluetooth.advertisedName }
        lowEnergy.advertisedName = advertisedName
        guard lowEnergy.isAdvertising else { return }
        lowEnergy.stop()
        lowEnergy.start()
    }

    private var connectionSection: some View {
        Section(header: Text(L10n.Section.connection), footer: Text(L10n.Setup.deviceNameLimitation)) {
            if lowEnergy.isAdvertising {
                Button(role: .destructive) { lowEnergy.stop() } label: {
                    Label(L10n.Action.stopAdvertising, systemImage: "stop.circle")
                }
            } else {
                Button { _startAdvertising() } label: {
                    Label(L10n.Action.startAdvertising, systemImage: "antenna.radiowaves.left.and.right")
                }
            }
            NavigationLink {
                DeviceListView()
            } label: {
                Label(L10n.Section.devices, systemImage: "dot.radiowaves.left.and.right")
            }
        }
        .onAppear(perform: _seedAliasesFromScan)
        .onChange(of: lowEnergy.connectedCentrals) { _ in _seedAliasesFromScan() }
        .onChange(of: central.discovered) { _ in _seedAliasesFromScan() }
    }

    private var connectedDevicesSection: some View {
        Section {
            ForEach(_connectedDevices) { connectedDeviceRow($0) }
        } footer: {
            Text(L10n.Setup.activeLegend)
        }
    }

    private var _connectedDevices: [DeviceEntry] {
        lowEnergy.connectedCentrals
            .map { uuid in
                let alias = names.name(for: uuid)
                let subscribed = lowEnergy.subscribedCentrals.keys.contains(uuid)
                return DeviceEntry(
                    id: uuid,
                    name: alias ?? "",
                    isNamed: alias != nil,
                    rssi: 0,
                    advertisedServices: [],
                    companyID: nil,
                    txPower: nil,
                    isConnectable: nil,
                    isHostConnected: true,
                    isCentralConnected: false,
                    isConnecting: false,
                    isSubscribed: subscribed,
                    isActive: subscribed && !lowEnergy.inactiveCentrals.contains(uuid)
                )
            }
            .sorted { $0.id.uuidString < $1.id.uuidString }
    }

    private func _seedAliasesFromScan() {
        for uuid in lowEnergy.connectedCentrals where names.name(for: uuid) == nil {
            guard let scanned = central.discovered.first(where: { $0.id == uuid && $0.isNamed })?.name else { continue }
            names.setName(scanned, for: uuid)
        }
    }

    private func _startAdvertising() {
        if lowEnergy.state == .poweredOn {
            lowEnergy.start()
            return
        }
        #if os(iOS)
            lowEnergy.promptPowerAlert()
        #else
            showBluetoothOff = true
        #endif
    }

    #if os(macOS)
        private func _openBluetoothSettings() {
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.systempreferences") else { return }
            NSWorkspace.shared.open(url)
        }
    #endif

    private func connectedDeviceRow(_ entry: DeviceEntry) -> some View {
        ConnectedDeviceRow(
            entry: entry,
            onToggle: { lowEnergy.toggleActive(entry.id) },
            onInfo: { selectedInfo = entry }
        )
    }

    #if os(macOS)
        private var pairedDevicesSection: some View {
            Section(header: Text(L10n.Classic.pairedDevicesSection)) {
                Text(L10n.Classic.pairFromSystemSettings)
                    .font(.caption).foregroundColor(.secondary)
                Button {
                    _ = classic.presentPairingPicker(title: L10n.Classic.pairWindowTitle, message: L10n.Classic.pairWindowDescription)
                } label: {
                    Label(L10n.Classic.pairNewDevice, systemImage: "plus.circle")
                }
                Button { classic.refreshPairedDevices() } label: {
                    Label(L10n.Classic.refresh, systemImage: "arrow.clockwise")
                }
                ForEach(classic.pairedDevices) { peer in
                    pairedDeviceRow(peer)
                }
                if classic.pairedDevices.isEmpty {
                    Text(L10n.Classic.noPairedDevices)
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .onAppear { classic.refreshPairedDevices() }
        }

        @ViewBuilder
        private func pairedDeviceRow(_ peer: PairedDevice) -> some View {
            let isLive = classic.connectedAddress == peer.id
            HStack {
                Button {
                    if isLive {
                        classic.disconnect()
                    } else {
                        classic.connect(to: peer)
                    }
                } label: {
                    HStack {
                        Image(systemName: isLive ? "link.circle.fill" : "link.circle")
                            .foregroundColor(isLive ? .green : .accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: peer.name).foregroundColor(.primary)
                            Text(verbatim: peer.displayAddress)
                                .font(.caption2).foregroundColor(.secondary).lineLimit(1)
                        }
                        Spacer()
                        Text(isLive ? L10n.Classic.disconnect : L10n.Classic.connect)
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)
                Button(role: .destructive) { classic.forgetDevice(id: peer.id) } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
        }
    #endif

    #if os(macOS)
        private var directInputSection: some View {
            Section(header: Text(L10n.DirectInput.section), footer: Text(L10n.DirectInput.releaseHint)) {
                Toggle(isOn: directInputBinding) {
                    Label(L10n.DirectInput.toggle, systemImage: "rectangle.and.hand.point.up.left")
                }
                if let lastError = directInput.lastError {
                    Text(verbatim: lastError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }

        private var directInputBinding: Binding<Bool> {
            Binding(
                get: { directInput.isCapturing },
                set: { shouldCapture in
                    if shouldCapture {
                        directInput.start(hid)
                    } else {
                        directInput.stop()
                    }
                }
            )
        }
    #endif

    #if os(iOS)
        private var directInputSection: some View {
            Section(
                header: Text(L10n.DirectInput.section),
                footer: Text(directInput.hasInputDevice ? L10n.DirectInput.releaseHint : L10n.DirectInput.iosNoDevice)
            ) {
                Toggle(isOn: directInputBinding) {
                    Label(L10n.DirectInput.toggle, systemImage: "rectangle.and.hand.point.up.left")
                }
                .disabled(!directInput.hasInputDevice)
                if let lastError = directInput.lastError {
                    Text(verbatim: lastError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }

        private var directInputBinding: Binding<Bool> {
            Binding(
                get: { directInput.isCapturing },
                set: { shouldCapture in
                    if shouldCapture {
                        directInput.start(hid)
                    } else {
                        directInput.stop()
                    }
                }
            )
        }
    #endif
}

private func row(_ title: LocalizedStringKey, _ value: Text) -> some View {
    HStack {
        Text(title)
        Spacer()
        value.foregroundColor(.secondary)
    }
}

private struct HostLEDsRow: View {
    @ObservedObject var combo: Combo

    var body: some View {
        row(L10n.Status.hostLEDs, Text(verbatim: combo.keyboardLEDs.localizedLabel))
    }
}

private extension CBManagerState {
    var localizedLabel: LocalizedStringKey {
        switch self {
        case .unknown: return L10n.BluetoothState.unknown
        case .resetting: return L10n.BluetoothState.resetting
        case .unsupported: return L10n.BluetoothState.unsupported
        case .unauthorized: return L10n.BluetoothState.unauthorized
        case .poweredOff: return L10n.BluetoothState.poweredOff
        case .poweredOn: return L10n.BluetoothState.poweredOn
        @unknown default: return L10n.BluetoothState.unavailable
        }
    }
}

#if os(macOS)
    private extension HIDClassicDevice.ControllerState {
        var localizedLabel: LocalizedStringKey {
            switch self {
            case .unknown: L10n.BluetoothState.unknown
            case .poweredOff: L10n.BluetoothState.poweredOff
            case .poweredOn: L10n.BluetoothState.poweredOn
            }
        }
    }
#endif

private extension KeyboardLEDs {
    var localizedLabel: String {
        var parts: [String] = []
        if contains(.numLock) { parts.append(L10n.KeyboardLED.numLock) }
        if contains(.capsLock) { parts.append(L10n.KeyboardLED.capsLock) }
        if contains(.scrollLock) { parts.append(L10n.KeyboardLED.scrollLock) }
        return parts.isEmpty ? L10n.Value.noneString : ListFormatter.localizedString(byJoining: parts)
    }
}

#if DEBUG
    #Preview {
        #if os(iOS)
            SetupView()
                .environmentObject(HIDPeripheral(profile: Combo()))
                .environmentObject(HIDCentral())
                .environmentObject(DeviceNameStore())
                .environmentObject(DirectInputController())
        #else
            SetupView()
                .environmentObject(HIDPeripheral(profile: Combo()))
                .environmentObject(HIDCentral())
                .environmentObject(DeviceNameStore())
                .environmentObject(HIDClassicDevice(profile: Combo()))
                .environmentObject(DirectInputController())
        #endif
    }
#endif
