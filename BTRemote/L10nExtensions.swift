import Foundation
import SwiftUI

extension L10n {
    enum DeviceInfo {
        static var title: LocalizedStringKey {
            "device_info.title"
        }

        static var info: LocalizedStringKey {
            "device_info.info"
        }

        static var device: LocalizedStringKey {
            "device_info.device"
        }

        static var manufacturer: LocalizedStringKey {
            "device_info.manufacturer"
        }

        static var advertisement: LocalizedStringKey {
            "device_info.advertisement"
        }

        static var services: LocalizedStringKey {
            "device_info.services"
        }

        static var name: LocalizedStringKey {
            "device_info.name"
        }

        static var identifier: LocalizedStringKey {
            "device_info.identifier"
        }

        static var signal: LocalizedStringKey {
            "device_info.signal"
        }

        static var connectable: LocalizedStringKey {
            "device_info.connectable"
        }

        static var txPower: LocalizedStringKey {
            "device_info.tx_power"
        }

        static var done: LocalizedStringKey {
            "device_info.done"
        }
    }

    enum Setup {
        static var help: LocalizedStringKey {
            "setup.help"
        }

        static var videoInstructions: LocalizedStringKey {
            "setup.video_instructions"
        }

        static var activeLegend: LocalizedStringKey {
            "setup.active_legend"
        }

        static var lowEnergyGuide: LocalizedStringKey {
            "setup.le_guide"
        }

        static var classicGuide: LocalizedStringKey {
            "setup.classic_guide"
        }

        static var classicStep1: LocalizedStringKey {
            "setup.classic_step1"
        }

        static var classicStep2: LocalizedStringKey {
            "setup.classic_step2"
        }

        static var classicStep3: LocalizedStringKey {
            "setup.classic_step3"
        }

        static var classicTroubleshooting: LocalizedStringKey {
            "setup.classic_troubleshooting"
        }

        static var connectFromThisApp: LocalizedStringKey {
            "setup.connect_from_this_app"
        }

        static var connectFromTargetDevice: LocalizedStringKey {
            "setup.connect_from_target_device"
        }

        static var fromApp: LocalizedStringKey {
            "setup.from_app"
        }

        static var fromAppStep1: LocalizedStringKey {
            "setup.from_app_step1"
        }

        static var fromAppStep2: LocalizedStringKey {
            "setup.from_app_step2"
        }

        static var fromDevice: LocalizedStringKey {
            "setup.from_device"
        }

        static var fromDeviceStep1: LocalizedStringKey {
            "setup.from_device_step1"
        }

        static func fromDeviceStep2(_ name: String) -> String {
            String.localizedStringWithFormat(
                String(localized: "setup.from_device_step2"),
                name
            )
        }

        static var fromDeviceStep3: LocalizedStringKey {
            "setup.from_device_step3"
        }

        static var troubleshooting: LocalizedStringKey {
            "setup.troubleshooting"
        }

        static var iCloudPaired: LocalizedStringKey {
            "setup.icloud_paired"
        }

        static var findGuideHint: LocalizedStringKey {
            "setup.find_guide_hint"
        }

        static var deviceNameLimitation: LocalizedStringKey {
            "setup.device_name_limitation"
        }

        static var advertisedName: LocalizedStringKey {
            "setup.advertised_name"
        }

        static var advertisedNameHint: LocalizedStringKey {
            "setup.advertised_name_hint"
        }

        static var bluetoothOffTitle: LocalizedStringKey {
            "setup.bluetooth_off_title"
        }

        static var bluetoothOffMessage: LocalizedStringKey {
            "setup.bluetooth_off_message"
        }
    }

    enum Settings {
        static var trackpad: LocalizedStringKey {
            "settings.trackpad"
        }

        static var trackingSpeed: LocalizedStringKey {
            "settings.tracking_speed"
        }

        static var scrollSpeed: LocalizedStringKey {
            "settings.scroll_speed"
        }

        static var connection: LocalizedStringKey {
            "settings.connection"
        }

        static var autoAdvertise: LocalizedStringKey {
            "settings.auto_advertise"
        }

        static var autoAdvertiseHint: LocalizedStringKey {
            "settings.auto_advertise_hint"
        }

        static var advanced: LocalizedStringKey {
            "settings.advanced"
        }

        static var developerMode: LocalizedStringKey {
            "settings.developer_mode"
        }

        static var forceServiceChanged: LocalizedStringKey {
            "settings.force_service_changed"
        }

        static var forceServiceChangedHint: LocalizedStringKey {
            "settings.force_service_changed_hint"
        }

        static var sourceCode: LocalizedStringKey {
            "settings.source_code"
        }

        static var reset: LocalizedStringKey {
            "settings.reset"
        }

        static var resetConfirm: LocalizedStringKey {
            "settings.reset_confirm"
        }
    }
}
