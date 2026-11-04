import Foundation

enum L10n {
    enum ErrorMessage {
        static func peripheralNotRetained(_ identifier: UUID) -> String {
            String.localizedStringWithFormat(
                String(localized: "error.peripheral_not_retained", bundle: .module),
                identifier.uuidString
            )
        }

        static func failedToConnect(_ reason: String) -> String {
            String.localizedStringWithFormat(
                String(localized: "error.failed_to_connect", bundle: .module),
                reason
            )
        }

        static var sdpPublishFailed: String {
            String(localized: "error.sdp_publish_failed", bundle: .module)
        }

        static func deviceNotPaired(_ name: String) -> String {
            String.localizedStringWithFormat(
                String(localized: "error.device_not_paired", bundle: .module),
                name
            )
        }

        static func openConnectionFailed(_ code: String) -> String {
            String.localizedStringWithFormat(
                String(localized: "error.open_connection_failed", bundle: .module),
                code
            )
        }

        static func openL2CAPFailed(_ psm: UInt16, _ code: String) -> String {
            String.localizedStringWithFormat(
                String(localized: "error.open_l2cap_failed", bundle: .module),
                String(format: "0x%04X", psm),
                code
            )
        }

        static func writeFailed(_ code: String) -> String {
            String.localizedStringWithFormat(
                String(localized: "error.write_failed", bundle: .module),
                code
            )
        }
    }

    enum Device {
        static var unknownName: String {
            String(localized: "device.unknown_name", bundle: .module)
        }
    }

    enum Classic {
        static var pairWindowHeader: String {
            String(localized: "classic.pair_window.header", bundle: .module)
        }
    }
}
