import BTHIDKit
import SwiftUI

struct GuideView: View {
    let transport: Transport

    @AppStorage(HIDSettings.advertisedNameKey) private var advertisedName = L10n.Bluetooth.advertisedName

    var body: some View {
        Form {
            #if os(macOS)
                Section {
                    Text(about).font(.caption).foregroundColor(.secondary)
                    Text(compatibility).font(.caption).foregroundColor(.secondary)
                }
            #endif
            switch transport {
            case .lowEnergy:
                Section(header: header(L10n.Setup.fromApp, L10n.Setup.connectFromThisApp), footer: fromAppFooter) {
                    step("1.circle", L10n.Setup.fromAppStep1)
                    step("2.circle", L10n.Setup.fromAppStep2)
                }
                Section(header: header(L10n.Setup.fromDevice, L10n.Setup.connectFromTargetDevice), footer: fromDeviceFooter) {
                    step("1.circle", L10n.Setup.fromDeviceStep1)
                    step("2.circle", Text(verbatim: L10n.Setup.fromDeviceStep2(advertisedName)))
                    step("3.circle", L10n.Setup.fromDeviceStep3)
                }
            case .classic:
                Section(footer: footer) {
                    step("1.circle", L10n.Setup.classicStep1)
                    step("2.circle", L10n.Setup.classicStep2)
                    step("3.circle", L10n.Setup.classicStep3)
                }
            }
        }
        #if os(macOS)
        .formStyle(.grouped)
        #endif
        .navigationTitle(title)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(troubleshooting)
            locationHint
        }
    }

    private var fromDeviceFooter: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(troubleshooting)
            locationHint
        }
    }

    private var fromAppFooter: some View {
        Text(L10n.Setup.iCloudPaired)
    }

    private var locationHint: some View {
        Text(L10n.Setup.findGuideHint)
    }

    private var title: LocalizedStringKey {
        switch transport {
        case .lowEnergy: L10n.Setup.lowEnergyGuide
        case .classic: L10n.Setup.classicGuide
        }
    }

    #if os(macOS)
        private var about: LocalizedStringKey {
            switch transport {
            case .lowEnergy: L10n.TransportMode.lowEnergyAbout
            case .classic: L10n.TransportMode.classicAbout
            }
        }

        private var compatibility: LocalizedStringKey {
            switch transport {
            case .lowEnergy: L10n.TransportMode.lowEnergyCompatibility
            case .classic: L10n.TransportMode.classicCompatibility
            }
        }
    #endif

    private var troubleshooting: LocalizedStringKey {
        switch transport {
        case .lowEnergy: L10n.Setup.troubleshooting
        case .classic: L10n.Setup.classicTroubleshooting
        }
    }

    private func step(_ icon: String, _ text: LocalizedStringKey) -> some View {
        step(icon, Text(text))
    }

    private func step(_ icon: String, _ text: Text) -> some View {
        Label { text } icon: { Image(systemName: icon) }
    }

    private func header(_ title: LocalizedStringKey, _ subtitle: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            Text(subtitle).font(.caption).foregroundColor(.secondary).textCase(nil)
        }
    }
}
