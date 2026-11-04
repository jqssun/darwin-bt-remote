import Foundation

struct MouseReport: Sendable, Equatable {
    var buttons: MouseButtons = []
    var dX: Int8 = 0
    var dY: Int8 = 0
    var wheel: Int8 = 0

    static let zero = MouseReport()

    var data: Data {
        Data([
            buttons.rawValue,
            UInt8(bitPattern: dX),
            UInt8(bitPattern: dY),
            UInt8(bitPattern: wheel)
        ])
    }
}

struct MouseButtons: OptionSet, Sendable, Equatable {
    let rawValue: UInt8
    static let left = MouseButtons(rawValue: 1 << 0)
    static let right = MouseButtons(rawValue: 1 << 1)
    static let middle = MouseButtons(rawValue: 1 << 2)
}

struct KeyboardReport: Sendable, Equatable {
    var modifiers: KeyboardModifiers = []
    var keys: [Keycode] = []

    static let zero = KeyboardReport()

    var data: Data {
        var bytes = [UInt8](repeating: 0, count: 8)
        bytes[0] = modifiers.rawValue
        for (i, key) in keys.prefix(6).enumerated() {
            bytes[2 + i] = key.rawValue
        }
        return Data(bytes)
    }
}

struct KeyboardModifiers: OptionSet, Sendable, Equatable {
    let rawValue: UInt8
    static let leftCtrl = KeyboardModifiers(rawValue: 1 << 0)
    static let leftShift = KeyboardModifiers(rawValue: 1 << 1)
    static let leftAlt = KeyboardModifiers(rawValue: 1 << 2)
    static let leftGUI = KeyboardModifiers(rawValue: 1 << 3)
    static let rightCtrl = KeyboardModifiers(rawValue: 1 << 4)
    static let rightShift = KeyboardModifiers(rawValue: 1 << 5)
    static let rightAlt = KeyboardModifiers(rawValue: 1 << 6)
    static let rightGUI = KeyboardModifiers(rawValue: 1 << 7)
}

struct KeyboardLEDs: OptionSet, Sendable, Equatable {
    let rawValue: UInt8
    static let numLock = KeyboardLEDs(rawValue: 1 << 0)
    static let capsLock = KeyboardLEDs(rawValue: 1 << 1)
    static let scrollLock = KeyboardLEDs(rawValue: 1 << 2)
    static let compose = KeyboardLEDs(rawValue: 1 << 3)
    static let kana = KeyboardLEDs(rawValue: 1 << 4)

    init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    init(byte: UInt8) {
        rawValue = byte & 0x1F
    }
}

enum Keycode: UInt8, Sendable, Equatable, Hashable {
    case a = 0x04, b, c, d, e, f, g, h, i, j, k, l, m
    case n, o, p, q, r, s, t, u, v, w, x, y, z
    case digit1 = 0x1E, digit2, digit3, digit4, digit5, digit6, digit7, digit8, digit9, digit0
    case `return` = 0x28
    case escape = 0x29
    case backspace = 0x2A
    case tab = 0x2B
    case space = 0x2C
    case minus = 0x2D
    case equal = 0x2E
    case leftBracket = 0x2F
    case rightBracket = 0x30
    case backslash = 0x31
    case semicolon = 0x33
    case quote = 0x34
    case grave = 0x35
    case comma = 0x36
    case period = 0x37
    case slash = 0x38
    case capsLock = 0x39
    case f1 = 0x3A, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12
    case printScreen = 0x46
    case rightArrow = 0x4F
    case leftArrow = 0x50
    case downArrow = 0x51
    case upArrow = 0x52
}

struct SystemControlReport: Sendable, Equatable {
    var actions: SystemActions = []

    static let zero = SystemControlReport()

    var data: Data {
        Data([actions.rawValue])
    }
}

struct SystemActions: OptionSet, Sendable, Equatable {
    let rawValue: UInt8
    static let powerDown = SystemActions(rawValue: 1 << 0)
    static let sleep = SystemActions(rawValue: 1 << 1)
    static let coldRestart = SystemActions(rawValue: 1 << 2)
    static let displayToggle = SystemActions(rawValue: 1 << 3)
    static let displayLCDAutoscale = SystemActions(rawValue: 1 << 4)
    static let mainMenu = SystemActions(rawValue: 1 << 5)
    static let appMenu = SystemActions(rawValue: 1 << 6)
    static let displayBrightnessDecrement = SystemActions(rawValue: 1 << 7)
}

struct ConsumerReport: Sendable, Equatable {
    var key: ConsumerKey = .none
    var acUsageA: UInt8 = 0
    var acUsageB: UInt8 = 0
    var sub: UInt8 = 0

    static let zero = ConsumerReport()

    var data: Data {
        let raw = key.rawValue
        return Data([
            UInt8(raw & 0xFF),
            UInt8(raw >> 8),
            acUsageA,
            acUsageB,
            sub
        ])
    }
}

enum ConsumerKey: UInt16, Sendable, Equatable {
    case none = 0x0000
    case playPause = 0x00CD
    case scanNext = 0x00B5
    case scanPrev = 0x00B6
    case stop = 0x00B7
    case rewind = 0x00B4
    case fastForward = 0x00B3
    case mute = 0x00E2
    case volumeUp = 0x00E9
    case volumeDown = 0x00EA
    case channelUp = 0x009C
    case channelDown = 0x009D
    case closedCaption = 0x0061
    case menu = 0x0040
    case menuPick = 0x0041
    case menuUp = 0x0042
    case menuDown = 0x0043
    case menuLeft = 0x0044
    case menuRight = 0x0045
    case power = 0x0030
}

extension ConsumerReport {
    static let acHome = ConsumerReport(acUsageB: 0x23)
    static let acBack = ConsumerReport(acUsageB: 0x24)
}
