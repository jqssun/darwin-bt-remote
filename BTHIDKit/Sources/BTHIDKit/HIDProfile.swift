import Foundation

@MainActor
public protocol HIDProfile: AnyObject {
    var identity: HIDIdentity { get }
    func connect(host: String?, send: @escaping @MainActor (UInt8, Data) -> Void)
    func disconnect()
    func feature(_ id: UInt8) -> Data?
    func output(_ id: UInt8, _ data: Data)
    func battery(_ level: UInt8)
}

public extension HIDProfile {
    func connect(host: String?, send: @escaping @MainActor (UInt8, Data) -> Void) {}
    func disconnect() {}
    func feature(_ id: UInt8) -> Data? {
        nil
    }

    func output(_ id: UInt8, _ data: Data) {}
    func battery(_ level: UInt8) {}
}

public struct HIDIdentity {
    public let name: String
    public let isNameEditable: Bool
    public let manufacturer: String
    public let model: String
    public let pnp: PnPID
    public let hidInformation: Data
    public let reportMap: Data
    /// in GATT order
    public let reports: [HIDReport]
    /// answers input reads before first send
    public let seedReports: [UInt8: Data]
    public let batteryReportID: UInt8?
    public let boot: BootReports?
    public let classOfDevice: UInt32
    /// add HID SDP
    public let sdp: [String: Any]
    /// add PnP SDP
    public let classicDeviceID: Bool

    public init(
        name: String,
        isNameEditable: Bool,
        manufacturer: String,
        model: String,
        pnp: PnPID,
        hidInformation: Data,
        reportMap: Data,
        reports: [HIDReport],
        seedReports: [UInt8: Data],
        batteryReportID: UInt8? = nil,
        boot: BootReports? = nil,
        classOfDevice: UInt32,
        sdp: [String: Any],
        classicDeviceID: Bool = false
    ) {
        self.name = name
        self.isNameEditable = isNameEditable
        self.manufacturer = manufacturer
        self.model = model
        self.pnp = pnp
        self.hidInformation = hidInformation
        self.reportMap = reportMap
        self.reports = reports
        self.seedReports = seedReports
        self.batteryReportID = batteryReportID
        self.boot = boot
        self.classOfDevice = classOfDevice
        self.sdp = sdp
        self.classicDeviceID = classicDeviceID
    }
}

public enum ReportType: UInt8, Sendable {
    case input = 1
    case output = 2
    case feature = 3
}

public struct HIDReport: Hashable, Sendable {
    public let id: UInt8
    public let type: ReportType

    public init(_ id: UInt8, _ type: ReportType) {
        self.id = id
        self.type = type
    }

    var reference: Data {
        Data([id, type.rawValue])
    }
}

public struct PnPID: Sendable {
    public let source: UInt8
    public let vendor: UInt16
    public let product: UInt16
    public let version: UInt16

    public init(source: UInt8, vendor: UInt16, product: UInt16, version: UInt16) {
        self.source = source
        self.vendor = vendor
        self.product = product
        self.version = version
    }

    var data: Data {
        Data([source] + [vendor, product, version].flatMap { [UInt8($0 & 0xFF), UInt8($0 >> 8)] })
    }
}

public struct BootReports: Sendable {
    public let mouse: UInt8
    public let keyboard: UInt8
    public let keyboardLEDs: UInt8

    public init(mouse: UInt8, keyboard: UInt8, keyboardLEDs: UInt8) {
        self.mouse = mouse
        self.keyboard = keyboard
        self.keyboardLEDs = keyboardLEDs
    }
}
