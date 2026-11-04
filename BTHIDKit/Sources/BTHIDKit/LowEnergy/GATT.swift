import CoreBluetooth
import Foundation

enum GATT {
    // CBPeripheralManager rejects short-form service UUIDs

    nonisolated(unsafe) static let batteryService = CBUUID(string: "0000180F-0000-1000-8000-00805F9B34FB")
    nonisolated(unsafe) static let deviceInformationService = CBUUID(string: "0000180A-0000-1000-8000-00805F9B34FB")
    nonisolated(unsafe) static let hidService = CBUUID(string: "00001812-0000-1000-8000-00805F9B34FB")
    /// advertising only: full form goes on air as 128-bit list
    nonisolated(unsafe) static let hidServiceAdvertised = CBUUID(string: "1812")

    nonisolated(unsafe) static let cccd = CBUUID(string: "00002902-0000-1000-8000-00805F9B34FB")
    nonisolated(unsafe) static let externalReportReference = CBUUID(string: "00002907-0000-1000-8000-00805F9B34FB")
    nonisolated(unsafe) static let reportReference = CBUUID(string: "00002908-0000-1000-8000-00805F9B34FB")

    nonisolated(unsafe) static let batteryLevel = CBUUID(string: "00002A19-0000-1000-8000-00805F9B34FB")
    nonisolated(unsafe) static let bootKeyboardInputReport = CBUUID(string: "00002A22-0000-1000-8000-00805F9B34FB")
    nonisolated(unsafe) static let bootKeyboardOutputReport = CBUUID(string: "00002A32-0000-1000-8000-00805F9B34FB")
    nonisolated(unsafe) static let bootMouseInputReport = CBUUID(string: "00002A33-0000-1000-8000-00805F9B34FB")
    nonisolated(unsafe) static let hidInformation = CBUUID(string: "00002A4A-0000-1000-8000-00805F9B34FB")
    nonisolated(unsafe) static let reportMap = CBUUID(string: "00002A4B-0000-1000-8000-00805F9B34FB")
    nonisolated(unsafe) static let hidControlPoint = CBUUID(string: "00002A4C-0000-1000-8000-00805F9B34FB")
    nonisolated(unsafe) static let report = CBUUID(string: "00002A4D-0000-1000-8000-00805F9B34FB")
    nonisolated(unsafe) static let protocolMode = CBUUID(string: "00002A4E-0000-1000-8000-00805F9B34FB")

    nonisolated(unsafe) static let manufacturerName = CBUUID(string: "00002A29-0000-1000-8000-00805F9B34FB")
    nonisolated(unsafe) static let modelNumber = CBUUID(string: "00002A24-0000-1000-8000-00805F9B34FB")
    nonisolated(unsafe) static let pnpID = CBUUID(string: "00002A50-0000-1000-8000-00805F9B34FB")

    static let externalReportReferenceValue = Data([0x19, 0x2A])
}
