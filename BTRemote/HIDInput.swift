import BTHIDKit
import CoreGraphics
import Foundation
import SwiftUI
#if os(iOS)
    import UIKit
#endif

struct HIDInput {
    let send: (UInt8, Data) -> Void
    let updateBattery: (UInt8) -> Void
    let isActive: Bool
    let isConnected: Bool
    let activeError: String?
    let batteryLevel: UInt8

    func sendMouse(_ report: MouseReport) {
        send(ReportID.mouse.rawValue, report.data)
    }

    func sendKeyboard(_ report: KeyboardReport) {
        send(ReportID.keyboard.rawValue, report.data)
    }

    func sendConsumer(_ report: ConsumerReport) {
        send(ReportID.consumerControl.rawValue, report.data)
    }

    func tap(_ key: Keycode, modifiers: KeyboardModifiers = []) {
        sendKeyboard(KeyboardReport(modifiers: modifiers, keys: [key]))
        sendKeyboard(.zero)
    }

    func tap(consumer: ConsumerKey) {
        sendConsumer(ConsumerReport(key: consumer))
        sendConsumer(.zero)
    }

    func click(_ button: MouseButtons) {
        sendMouse(MouseReport(buttons: button))
        sendMouse(.zero)
    }

    func move(dx: Int8, dy: Int8) {
        sendMouse(MouseReport(dX: dx, dY: dy))
    }

    func scroll(_ wheel: Int8) {
        sendMouse(MouseReport(wheel: wheel))
        sendMouse(.zero)
    }

    func type(_ character: Character) {
        guard let (key, mods) = mapASCII(character) else { return }
        sendKeyboard(KeyboardReport(modifiers: mods, keys: [key]))
        sendKeyboard(.zero)
    }

    /// empty if unmappable
    static func keyReports(for character: Character, adding modifiers: KeyboardModifiers = []) -> [KeyboardReport] {
        guard let (key, mods) = mapASCII(character) else { return [] }
        return [KeyboardReport(modifiers: mods.union(modifiers), keys: [key]), .zero]
    }

    static func keyReports(for key: Keycode, modifiers: KeyboardModifiers = []) -> [KeyboardReport] {
        [KeyboardReport(modifiers: modifiers, keys: [key]), .zero]
    }

    @MainActor
    func typeWord(_ text: String) async {
        for character in text {
            type(character)
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    static func clamp(_ value: CGFloat) -> Int8 {
        Int8(max(-127, min(127, Int(value))))
    }
}

extension HIDInput {
    #if os(macOS)
        @MainActor
        static func make(lowEnergy: HIDPeripheral, central: HIDCentral, classic: HIDClassicDevice, transport: Transport) -> HIDInput {
            guard transport == .classic else { return _lowEnergy(lowEnergy, central) }
            return HIDInput(
                send: { classic.send($0, $1) },
                updateBattery: { classic.updateBatteryLevel($0) },
                isActive: classic.isSDPPublished,
                isConnected: classic.connectedAddress != nil,
                activeError: classic.lastError,
                batteryLevel: classic.batteryLevel
            )
        }
    #else
        @MainActor
        static func make(lowEnergy: HIDPeripheral, central: HIDCentral) -> HIDInput {
            _lowEnergy(lowEnergy, central)
        }
    #endif

    static var unavailable: HIDInput {
        HIDInput(
            send: { _, _ in }, updateBattery: { _ in },
            isActive: false, isConnected: false, activeError: nil, batteryLevel: 0
        )
    }

    @MainActor
    private static func _lowEnergy(_ lowEnergy: HIDPeripheral, _ central: HIDCentral) -> HIDInput {
        HIDInput(
            send: { lowEnergy.send($0, $1) },
            updateBattery: { lowEnergy.updateBatteryLevel($0) },
            isActive: lowEnergy.isHIDServiceAdded,
            isConnected: lowEnergy.connectedCentrals.contains { !lowEnergy.inactiveCentrals.contains($0) } || !central.connected.isEmpty,
            activeError: lowEnergy.lastError ?? central.lastError,
            batteryLevel: lowEnergy.batteryLevel
        )
    }
}

extension EnvironmentValues {
    @Entry var hid: HIDInput = .unavailable
}

enum Haptics {
    @MainActor
    static func tap() {
        #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

/// US layout
private func mapASCII(_ character: Character) -> (Keycode, KeyboardModifiers)? {
    if let a = character.asciiValue {
        if a >= 0x61, a <= 0x7A, let key = Keycode(rawValue: 0x04 + (a - 0x61)) { return (key, []) } // a..z
        if a >= 0x41, a <= 0x5A, let key = Keycode(rawValue: 0x04 + (a - 0x41)) { return (key, .leftShift) } // A..Z
    }
    return _symbolKeys[character]
}

private let _shift: KeyboardModifiers = .leftShift
private let _symbolKeys: [Character: (Keycode, KeyboardModifiers)] = [
    "1": (.digit1, []), "2": (.digit2, []), "3": (.digit3, []), "4": (.digit4, []), "5": (.digit5, []),
    "6": (.digit6, []), "7": (.digit7, []), "8": (.digit8, []), "9": (.digit9, []), "0": (.digit0, []),
    "!": (.digit1, _shift), "@": (.digit2, _shift), "#": (.digit3, _shift), "$": (.digit4, _shift), "%": (.digit5, _shift),
    "^": (.digit6, _shift), "&": (.digit7, _shift), "*": (.digit8, _shift), "(": (.digit9, _shift), ")": (.digit0, _shift),
    " ": (.space, []), "\n": (.return, []), "\r": (.return, []), "\t": (.tab, []),
    "-": (.minus, []), "_": (.minus, _shift), "=": (.equal, []), "+": (.equal, _shift),
    "[": (.leftBracket, []), "{": (.leftBracket, _shift), "]": (.rightBracket, []), "}": (.rightBracket, _shift),
    "\\": (.backslash, []), "|": (.backslash, _shift), ";": (.semicolon, []), ":": (.semicolon, _shift),
    "'": (.quote, []), "\"": (.quote, _shift), "`": (.grave, []), "~": (.grave, _shift),
    ",": (.comma, []), "<": (.comma, _shift), ".": (.period, []), ">": (.period, _shift),
    "/": (.slash, []), "?": (.slash, _shift)
]
