import BTHIDKit
import SwiftUI

enum Transport: String {
    case lowEnergy, classic
}

@main
struct BTRemoteApp: App {
    #if os(iOS)
        @StateObject private var lowEnergy = HIDPeripheral(profile: Combo())
        @StateObject private var central = HIDCentral()
        @AppStorage(AppSettings.autoAdvertiseKey) private var autoAdvertise = true
    #else
        @StateObject private var lowEnergy = HIDPeripheral(profile: Combo())
        @StateObject private var central = HIDCentral()
        @StateObject private var classic = HIDClassicDevice(profile: Combo())
        @AppStorage(AppSettings.transportKey) private var transport = Transport.lowEnergy
    #endif

    @StateObject private var deviceNames = DeviceNameStore()

    init() {
        UserDefaults.standard.register(defaults: [HIDSettings.forceServiceChangedKey: true])
    }

    private var hid: HIDInput {
        #if os(macOS)
            return HIDInput.make(lowEnergy: lowEnergy, central: central, classic: classic, transport: transport)
        #else
            return HIDInput.make(lowEnergy: lowEnergy, central: central)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            #if os(iOS)
                ContentView()
                    .environmentObject(lowEnergy)
                    .environmentObject(central)
                    .environmentObject(deviceNames)
                    .environment(\.hid, hid)
                    .onAppear {
                        central.start()
                        if autoAdvertise { lowEnergy.start() }
                    }
            #else
                ContentView()
                    .environmentObject(lowEnergy)
                    .environmentObject(central)
                    .environmentObject(classic)
                    .environmentObject(deviceNames)
                    .environment(\.hid, hid)
                    .onAppear { _start() }
                    .onChange(of: transport) { _ in _switch() }
            #endif
        }
    }

    #if os(macOS)
        private func _start() {
            switch transport {
            case .classic:
                classic.start()
            case .lowEnergy:
                lowEnergy.start()
                central.start()
            }
        }

        private func _switch() {
            lowEnergy.stop()
            classic.stop()
            _start()
        }
    #endif
}
