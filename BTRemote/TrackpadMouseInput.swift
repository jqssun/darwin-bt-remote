struct TrackpadMouseInput {
    private(set) var buttons: MouseButtons = []

    mutating func setButton(_ button: MouseButtons, pressed: Bool) -> MouseReport? {
        let next = pressed ? buttons.union(button) : buttons.subtracting(button)
        guard next != buttons else { return nil }
        buttons = next
        return MouseReport(buttons: buttons)
    }

    func move(dx: Int8, dy: Int8) -> MouseReport {
        MouseReport(buttons: buttons, dX: dx, dY: dy)
    }

    func scroll(_ wheel: Int8) -> [MouseReport] {
        [MouseReport(buttons: buttons, wheel: wheel), MouseReport(buttons: buttons)]
    }

    func click(_ button: MouseButtons) -> [MouseReport] {
        guard !buttons.contains(button) else { return [] }
        return [MouseReport(buttons: buttons.union(button)), MouseReport(buttons: buttons)]
    }

    mutating func releaseAll() -> MouseReport? {
        guard !buttons.isEmpty else { return nil }
        buttons = []
        return .zero
    }
}
