import Foundation
import SwiftUI

enum L10n {
    enum App {
        static var title: LocalizedStringKey {
            "app.title"
        }
    }

    enum Tab {
        static var remote: LocalizedStringKey {
            "tab.remote"
        }

        static var keyboard: LocalizedStringKey {
            "tab.keyboard"
        }

        static var settings: LocalizedStringKey {
            "tab.settings"
        }

        static var setup: LocalizedStringKey {
            "tab.setup"
        }
    }

    enum Remote {
        static var notConnectedTitle: LocalizedStringKey {
            "remote.not_connected_title"
        }

        static var notConnectedMessage: LocalizedStringKey {
            "remote.not_connected_message"
        }

        static var openSetup: LocalizedStringKey {
            "remote.open_setup"
        }

        static var mode: LocalizedStringKey {
            "remote.mode"
        }

        static var back: LocalizedStringKey {
            "remote.back"
        }

        static var home: LocalizedStringKey {
            "remote.home"
        }

        static var menu: LocalizedStringKey {
            "remote.menu"
        }

        static var power: LocalizedStringKey {
            "remote.power"
        }

        static var channelUp: LocalizedStringKey {
            "remote.channel_up"
        }

        static var channelDown: LocalizedStringKey {
            "remote.channel_down"
        }

        static var closedCaptions: LocalizedStringKey {
            "remote.closed_captions"
        }

        static var up: LocalizedStringKey {
            "remote.up"
        }

        static var down: LocalizedStringKey {
            "remote.down"
        }

        static var left: LocalizedStringKey {
            "remote.left"
        }

        static var right: LocalizedStringKey {
            "remote.right"
        }

        static var select: LocalizedStringKey {
            "remote.select"
        }
    }

    enum Section {
        static var lastError: LocalizedStringKey {
            "section.last_error"
        }

        static var status: LocalizedStringKey {
            "section.status"
        }

        static var connection: LocalizedStringKey {
            "section.connection"
        }

        static var devices: LocalizedStringKey {
            "section.devices"
        }

        static var battery: LocalizedStringKey {
            "section.battery"
        }
    }

    enum Status {
        static var bluetooth: LocalizedStringKey {
            "status.bluetooth"
        }

        static var advertising: LocalizedStringKey {
            "status.advertising"
        }

        static var hidService: LocalizedStringKey {
            "status.hid_service"
        }

        static var hidServiceAdded: LocalizedStringKey {
            "status.hid_service.added"
        }

        static var subscribedCentrals: LocalizedStringKey {
            "status.subscribed_centrals"
        }

        static var connectedPeripherals: LocalizedStringKey {
            "status.connected_peripherals"
        }

        static var hostLEDs: LocalizedStringKey {
            "status.host_leds"
        }
    }

    enum Value {
        static var yes: LocalizedStringKey {
            "value.yes"
        }

        static var no: LocalizedStringKey {
            "value.no"
        }

        static var none: LocalizedStringKey {
            "value.none"
        }

        static var noneString: String {
            String(localized: "value.none")
        }
    }

    enum Action {
        static var startAdvertising: LocalizedStringKey {
            "action.start_advertising"
        }

        static var stopAdvertising: LocalizedStringKey {
            "action.stop_advertising"
        }

        static var scanNearbyDevices: LocalizedStringKey {
            "action.scan_nearby_devices"
        }

        static var stopScanning: LocalizedStringKey {
            "action.stop_scanning"
        }

        static var notNow: LocalizedStringKey {
            "action.not_now"
        }

        static var done: LocalizedStringKey {
            "action.done"
        }

        static var settings: LocalizedStringKey {
            "action.settings"
        }
    }

    enum Welcome {
        static var title: LocalizedStringKey {
            "welcome.title"
        }

        static var message: LocalizedStringKey {
            "welcome.message"
        }

        static var viewGuide: LocalizedStringKey {
            "welcome.view_guide"
        }
    }

    enum Sort {
        static var title: LocalizedStringKey {
            "sort.title"
        }

        static var direction: LocalizedStringKey {
            "sort.direction"
        }

        static var ascending: LocalizedStringKey {
            "sort.ascending"
        }

        static var descending: LocalizedStringKey {
            "sort.descending"
        }
    }

    enum Device {
        static var emptyState: LocalizedStringKey {
            "device.empty_state"
        }

        static var unknownManufacturer: String {
            String(localized: "device.unknown_manufacturer")
        }

        static var inactive: LocalizedStringKey {
            "device.inactive"
        }

        static var notSubscribed: LocalizedStringKey {
            "device.not_subscribed"
        }

        static var connectedLegend: LocalizedStringKey {
            "device.connected_legend"
        }

        static func rssi(_ value: Int) -> String {
            String.localizedStringWithFormat(
                String(localized: "device.rssi_format"),
                value
            )
        }

        static func connectAccessibilityLabel(_ name: String) -> String {
            String.localizedStringWithFormat(
                String(localized: "device.connect_accessibility_label"),
                name
            )
        }

        static func disconnectAccessibilityLabel(_ name: String) -> String {
            String.localizedStringWithFormat(
                String(localized: "device.disconnect_accessibility_label"),
                name
            )
        }
    }
}

extension L10n {
    enum Keyboard {
        static var prompt: LocalizedStringKey {
            "keyboard.prompt"
        }

        static var clear: LocalizedStringKey {
            "keyboard.clear"
        }

        static var send: LocalizedStringKey {
            "keyboard.send"
        }

        static var liveTyping: LocalizedStringKey {
            "keyboard.live_typing"
        }

        static var done: LocalizedStringKey {
            "keyboard.done"
        }

        static var esc: LocalizedStringKey {
            "keyboard.esc"
        }

        static var arrows: LocalizedStringKey {
            "keyboard.arrows"
        }

        static var tab: LocalizedStringKey {
            "keyboard.tab"
        }

        static var up: LocalizedStringKey {
            "keyboard.up"
        }

        static var down: LocalizedStringKey {
            "keyboard.down"
        }

        static var left: LocalizedStringKey {
            "keyboard.left"
        }

        static var right: LocalizedStringKey {
            "keyboard.right"
        }

        static var shift: LocalizedStringKey {
            "keyboard.shift"
        }

        static var ctrl: LocalizedStringKey {
            "keyboard.ctrl"
        }

        static var alt: LocalizedStringKey {
            "keyboard.alt"
        }

        static var meta: LocalizedStringKey {
            "keyboard.meta"
        }

        static var altGr: LocalizedStringKey {
            "keyboard.alt_gr"
        }

        static var printScreen: LocalizedStringKey {
            "keyboard.print_screen"
        }

        static var backspace: LocalizedStringKey {
            "keyboard.backspace"
        }

        static var enter: LocalizedStringKey {
            "keyboard.enter"
        }

        static var space: LocalizedStringKey {
            "keyboard.space"
        }
    }

    enum DirectInput {
        static var section: LocalizedStringKey {
            "section.direct_input"
        }

        static var toggle: LocalizedStringKey {
            "direct_input.toggle"
        }

        static var releaseHint: LocalizedStringKey {
            "direct_input.release_hint"
        }

        static var iosNoDevice: LocalizedStringKey {
            "direct_input.ios_no_device"
        }

        static var releaseHintString: String {
            String(localized: "direct_input.release_hint")
        }

        static var captureFailedString: String {
            String(localized: "direct_input.capture_failed")
        }

        static var permissionTitle: LocalizedStringKey {
            "direct_input.permission_title"
        }

        static var permissionMessage: LocalizedStringKey {
            "direct_input.permission_message"
        }

        static var openSettings: LocalizedStringKey {
            "direct_input.open_settings"
        }

        static var enable: LocalizedStringKey {
            "direct_input.enable"
        }

        static var connectedPromptTitle: LocalizedStringKey {
            "direct_input.connected_prompt_title"
        }

        static var connectedPromptMessage: LocalizedStringKey {
            "direct_input.connected_prompt_message"
        }
    }

    enum Mouse {
        static var leftButton: LocalizedStringKey {
            "mouse.button.left"
        }

        static var middleButton: LocalizedStringKey {
            "mouse.button.middle"
        }

        static var rightButton: LocalizedStringKey {
            "mouse.button.right"
        }

        static var wheelUp: LocalizedStringKey {
            "mouse.wheel.up"
        }

        static var wheelDown: LocalizedStringKey {
            "mouse.wheel.down"
        }
    }

    enum Media {
        static var playPause: LocalizedStringKey {
            "media.play_pause"
        }

        static var rewind: LocalizedStringKey {
            "media.rewind"
        }

        static var fastForward: LocalizedStringKey {
            "media.fast_forward"
        }

        static var mute: LocalizedStringKey {
            "media.mute"
        }

        static var volumeDown: LocalizedStringKey {
            "media.volume_down"
        }

        static var volumeUp: LocalizedStringKey {
            "media.volume_up"
        }
    }

    enum Battery {
        static var level: LocalizedStringKey {
            "battery.level"
        }
    }

    enum BluetoothState {
        static var unknown: LocalizedStringKey {
            "bluetooth_state.unknown"
        }

        static var resetting: LocalizedStringKey {
            "bluetooth_state.resetting"
        }

        static var unsupported: LocalizedStringKey {
            "bluetooth_state.unsupported"
        }

        static var unauthorized: LocalizedStringKey {
            "bluetooth_state.unauthorized"
        }

        static var poweredOff: LocalizedStringKey {
            "bluetooth_state.powered_off"
        }

        static var poweredOn: LocalizedStringKey {
            "bluetooth_state.powered_on"
        }

        static var unavailable: LocalizedStringKey {
            "bluetooth_state.unavailable"
        }
    }

    enum KeyboardLED {
        static var numLock: String {
            String(localized: "keyboard_led.num_lock")
        }

        static var capsLock: String {
            String(localized: "keyboard_led.caps_lock")
        }

        static var scrollLock: String {
            String(localized: "keyboard_led.scroll_lock")
        }
    }

    enum Bluetooth {
        static var advertisedName: String {
            String(localized: "bluetooth.advertised_name")
        }

        static var serviceDescription: String {
            String(localized: "bluetooth.service_description")
        }

        static var providerName: String {
            String(localized: "bluetooth.provider_name")
        }
    }

    enum TransportMode {
        static var section: LocalizedStringKey {
            "section.transport_mode"
        }

        static var label: LocalizedStringKey {
            "transport_mode.label"
        }

        static var classic: LocalizedStringKey {
            "transport_mode.classic"
        }

        static var lowEnergy: LocalizedStringKey {
            "transport_mode.low_energy"
        }

        static var classicAbout: LocalizedStringKey {
            "transport_mode.classic.about"
        }

        static var lowEnergyAbout: LocalizedStringKey {
            "transport_mode.low_energy.about"
        }

        static var classicCompatibility: LocalizedStringKey {
            "transport_mode.classic.compatibility"
        }

        static var lowEnergyCompatibility: LocalizedStringKey {
            "transport_mode.low_energy.compatibility"
        }
    }

    enum Classic {
        static var pairedDevicesSection: LocalizedStringKey {
            "section.paired_devices"
        }

        static var noPairedDevices: LocalizedStringKey {
            "classic.no_paired_devices"
        }

        static var refresh: LocalizedStringKey {
            "classic.refresh"
        }

        static var connect: LocalizedStringKey {
            "classic.connect"
        }

        static var disconnect: LocalizedStringKey {
            "classic.disconnect"
        }

        static var ready: LocalizedStringKey {
            "classic.ready"
        }

        static var sdpPublished: LocalizedStringKey {
            "classic.sdp_published"
        }

        static var pairFromSystemSettings: LocalizedStringKey {
            "classic.pair_from_system_settings"
        }

        static var pairNewDevice: LocalizedStringKey {
            "classic.pair_new_device"
        }

        static var pairWindowTitle: String {
            String(localized: "classic.pair_window.title")
        }

        static var pairWindowDescription: String {
            String(localized: "classic.pair_window.description")
        }
    }
}
