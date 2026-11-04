import BTHIDKit
import Combine
import Foundation

enum ReportID: UInt8 {
    case mouse = 1
    case keyboard = 2
    case keyboardLEDs = 3
    case battery = 4
    case systemControl = 5
    case consumerControl = 6
}

/// keyboard + mouse + media identity
@MainActor
final class Combo: ObservableObject, HIDProfile {
    @Published private(set) var keyboardLEDs: KeyboardLEDs = []

    let identity = HIDIdentity(
        name: L10n.Bluetooth.advertisedName,
        isNameEditable: true,
        manufacturer: "BTRemote",
        model: "BTRemote-1.0",
        // test VID
        pnp: PnPID(source: 1, vendor: 0xFFFF, product: 0x0001, version: 0x0100),
        hidInformation: Data([0x11, 0x01, 0x00, 0x03]),
        reportMap: reportMap,
        reports: [
            HIDReport(ReportID.systemControl.rawValue, .input),
            HIDReport(ReportID.consumerControl.rawValue, .input),
            HIDReport(ReportID.mouse.rawValue, .input),
            HIDReport(ReportID.keyboard.rawValue, .input),
            HIDReport(ReportID.keyboardLEDs.rawValue, .output)
        ],
        seedReports: [
            ReportID.mouse.rawValue: MouseReport.zero.data,
            ReportID.keyboard.rawValue: KeyboardReport.zero.data,
            ReportID.systemControl.rawValue: SystemControlReport.zero.data,
            ReportID.consumerControl.rawValue: ConsumerReport.zero.data
        ],
        batteryReportID: ReportID.battery.rawValue,
        boot: BootReports(
            mouse: ReportID.mouse.rawValue,
            keyboard: ReportID.keyboard.rawValue,
            keyboardLEDs: ReportID.keyboardLEDs.rawValue
        ),
        classOfDevice: 0x2540,
        sdp: Combo.sdp
    )

    func output(_ id: UInt8, _ data: Data) {
        guard id == ReportID.keyboardLEDs.rawValue, let byte = data.first else { return }
        keyboardLEDs = KeyboardLEDs(byte: byte)
    }

    private static var sdp: [String: Any] {
        [
            "0005 - BrowseGroupList": [
                SDPRecord.uuid16(0x1002)
            ],

            "0009 - BluetoothProfileDescriptorList": [
                [
                    SDPRecord.uuid16(0x1124),
                    SDPRecord.uint(0x0101, bytes: 2)
                ]
            ],

            "0100 - ServiceName": L10n.Bluetooth.advertisedName,
            "0101 - ServiceDescription": L10n.Bluetooth.serviceDescription,
            "0102 - ProviderName": L10n.Bluetooth.providerName,

            "0202 - HIDDeviceSubclass": SDPRecord.uint(0xC0, bytes: 1),
            "0203 - HIDCountryCode": SDPRecord.uint(0x21, bytes: 1),

            "0207 - HIDLANGIDBaseList": [
                SDPRecord.uint(0x0409, bytes: 2),
                SDPRecord.uint(0x0100, bytes: 2)
            ],

            "020D - HIDNormallyConnectable": true,
            "020E - HIDBootDevice": true
        ]
    }
}

private let reportMap = Data([
    // mouse: report ID 1 (52 bytes)
    0x05, 0x01, // Usage Page (Generic Desktop)
    0x09, 0x02, // Usage (Mouse)
    0xA1, 0x01, // Collection (Application)
    0x85, 0x01, //   Report ID (1)
    0x09, 0x01, //   Usage (Pointer)
    0xA1, 0x00, //   Collection (Physical)
    0x05, 0x09, //     Usage Page (Button)
    0x19, 0x01, //     Usage Min (1)
    0x29, 0x03, //     Usage Max (3)
    0x75, 0x01, //     Report Size (1)
    0x95, 0x03, //     Report Count (3)
    0x15, 0x00, //     Logical Min (0)
    0x25, 0x01, //     Logical Max (1)
    0x81, 0x02, //     Input (Data,Var,Abs)
    0x95, 0x05, //     Report Count (5)
    0x81, 0x03, //     Input (Const,Var,Abs) padding
    0x05, 0x01, //     Usage Page (Generic Desktop)
    0x09, 0x30, //     Usage (X)
    0x09, 0x31, //     Usage (Y)
    0x09, 0x38, //     Usage (Wheel)
    0x75, 0x08, //     Report Size (8)
    0x95, 0x03, //     Report Count (3)
    0x15, 0x81, //     Logical Min (-127)
    0x25, 0x7F, //     Logical Max (127)
    0x81, 0x06, //     Input (Data,Var,Rel)
    0xC0, //   End Collection
    0xC0, // End Collection

    // keyboard input + LED output: report IDs 2 and 3 (61 bytes)
    0x05, 0x01, // Usage Page (Generic Desktop)
    0x09, 0x06, // Usage (Keyboard)
    0xA1, 0x01, // Collection (Application)
    0x85, 0x02, //   Report ID (2)
    0x05, 0x07, //   Usage Page (Keyboard/Keypad)
    0x19, 0xE0, //   Usage Min (LeftControl)
    0x29, 0xE7, //   Usage Max (RightGUI)
    0x75, 0x01, //   Report Size (1)
    0x95, 0x08, //   Report Count (8)
    0x15, 0x00, //   Logical Min (0)
    0x25, 0x01, //   Logical Max (1)
    0x81, 0x02, //   Input (Data,Var,Abs): 8 modifier bits
    0x95, 0x01, //   Report Count (1)
    0x75, 0x08, //   Report Size (8)
    0x81, 0x01, //   Input (Const,Array,Abs): reserved byte
    0x19, 0x00, //   Usage Min (0)
    0x29, 0xDD, //   Usage Max (221)
    0x95, 0x06, //   Report Count (6)
    0x25, 0xDD, //   Logical Max (221)
    0x81, 0x00, //   Input (Data,Array,Abs): 6 keys
    0x85, 0x03, //   Report ID (3)
    0x05, 0x08, //   Usage Page (LEDs)
    0x19, 0x01, //   Usage Min (NumLock)
    0x29, 0x05, //   Usage Max (Kana)
    0x95, 0x05, //   Report Count (5)
    0x75, 0x01, //   Report Size (1)
    0x25, 0x01, //   Logical Max (1)
    0x91, 0x02, //   Output (Data,Var,Abs): 5 LED bits
    0x95, 0x03, //   Report Count (3)
    0x91, 0x03, //   Output (Const,Var,Abs): LED padding
    0xC0, // End Collection

    // battery: report ID 4 (23 bytes)
    0x05, 0x0C, // Usage Page (Consumer)
    0x09, 0x01, // Usage (Consumer Control)
    0xA1, 0x01, // Collection (Application)
    0x85, 0x04, //   Report ID (4)
    0x05, 0x06, //   Usage Page (Generic Device Controls)
    0x09, 0x20, //   Usage (Battery Strength)
    0x75, 0x08, //   Report Size (8)
    0x95, 0x01, //   Report Count (1)
    0x15, 0x00, //   Logical Min (0)
    0x25, 0x64, //   Logical Max (100)
    0x81, 0x02, //   Input (Data,Var,Abs)
    0xC0, // End Collection

    // system control: report ID 5 (35 bytes)
    0x05, 0x01, // Usage Page (Generic Desktop)
    0x09, 0x80, // Usage (System Control)
    0xA1, 0x01, // Collection (Application)
    0x85, 0x05, //   Report ID (5)
    0x09, 0x81, //   Usage (System Power Down)
    0x09, 0x82, //   Usage (System Sleep)
    0x09, 0x8E, //   Usage (System Cold Restart)
    0x09, 0xA8, //   Usage (System Hibernate)
    0x09, 0x8F, //   Usage (System Warm Restart)
    0x09, 0x85, //   Usage (System Main Menu)
    0x09, 0x86, //   Usage (System App Menu)
    0x09, 0xA7, //   Usage (System Speaker Mute)
    0x75, 0x01, //   Report Size (1)
    0x95, 0x08, //   Report Count (8)
    0x15, 0x00, //   Logical Min (0)
    0x25, 0x01, //   Logical Max (1)
    0x81, 0x06, //   Input (Data,Var,Rel)
    0xC0, // End Collection

    // consumer control: report ID 6 (68 bytes)
    0x05, 0x0C, // Usage Page (Consumer)
    0x09, 0x01, // Usage (Consumer Control)
    0xA1, 0x01, // Collection (Application)
    0x85, 0x06, //   Report ID (6)
    0x19, 0x00, //   Usage Min (0)
    0x2A, 0x74, 0x01, //   Usage Max (0x0174)
    0x75, 0x10, //   Report Size (16)
    0x95, 0x01, //   Report Count (1)
    0x15, 0x00, //   Logical Min (0)
    0x26, 0x74, 0x01, //   Logical Max (0x0174)
    0x81, 0x00, //   Input (Data,Array,Abs): 16-bit consumer
    0x1A, 0x81, 0x01, //   Usage Min (0x0181)
    0x2A, 0xCB, 0x01, //   Usage Max (0x01CB)
    0x95, 0x01, //   Report Count (1)
    0x75, 0x08, //   Report Size (8)
    0x15, 0x01, //   Logical Min (1)
    0x25, 0x4B, //   Logical Max (75)
    0x81, 0x00, //   Input (Data,Array,Abs)
    0x1A, 0x01, 0x02, //   Usage Min (0x0201)
    0x2A, 0xB0, 0x02, //   Usage Max (0x02B0)
    0x25, 0xB0, //   Logical Max (0xB0)
    0x81, 0x00, //   Input (Data,Array,Abs)
    0xA1, 0x03, //   Collection (Report)
    0x19, 0x00, //     Usage Min (0)
    0x29, 0xFF, //     Usage Max (0xFF)
    0x95, 0x01, //     Report Count (1)
    0x75, 0x08, //     Report Size (8)
    0x15, 0x00, //     Logical Min (0)
    0x25, 0xFF, //     Logical Max (0xFF)
    0x81, 0x00, //     Input (Data,Array,Abs)
    0xC0, //   End Collection
    0xC0 // End Collection
])
