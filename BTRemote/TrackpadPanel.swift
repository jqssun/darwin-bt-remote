import SwiftUI
#if os(iOS)
    import UIKit
#endif

struct TrackpadPanel: View {
    let hid: HIDInput

    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppSettings.touchpadSensitivityKey) private var touchpadSensitivity = AppSettings.defaultPointerSensitivity
    @AppStorage(AppSettings.scrollSensitivityKey) private var scrollSensitivity = AppSettings.defaultScrollSensitivity
    @State private var mouseInput = TrackpadMouseInput()
    #if os(macOS)
        @State private var dragOffset: CGSize = .zero
    #endif

    var body: some View {
        VStack(spacing: cellGap) {
            HStack(spacing: cellGap) {
                surface
                scrollColumn.frame(width: 46)
            }
            .frame(maxHeight: .infinity)
            mouseButtonsRow.frame(height: 52)
        }
        .onDisappear(perform: releaseMouseButtons)
        .onChange(of: scenePhase) { phase in
            if phase != .active { releaseMouseButtons() }
        }
        .onChange(of: hid.isConnected) { isConnected in
            if !isConnected { releaseMouseButtons() }
        }
        #if os(iOS)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                releaseMouseButtons()
            }
        #endif
    }

    private var surface: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(groupFill)
            #if os(iOS)
                TouchpadView(
                    moveSensitivity: touchpadSensitivity,
                    scrollSensitivity: scrollSensitivity,
                    onMove: moveMouse,
                    onMoveCancelled: releaseMouseButtons,
                    onScroll: scrollMouse,
                    onLeftClick: { clickMouse(.left) },
                    onRightClick: { clickMouse(.right) }
                )
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(macOS)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let dx = HIDInput.clamp((value.translation.width - dragOffset.width) * touchpadSensitivity)
                        let dy = HIDInput.clamp((value.translation.height - dragOffset.height) * touchpadSensitivity)
                        dragOffset = value.translation
                        moveMouse(dx: dx, dy: dy)
                    }
                    .onEnded { _ in
                        dragOffset = .zero
                        moveMouse(dx: 0, dy: 0)
                    }
            )
        #endif
    }

    private var scrollAmount: Int8 {
        max(1, HIDInput.clamp(CGFloat(3 * scrollSensitivity)))
    }

    private var scrollColumn: some View {
        VStack(spacing: cellGap) {
            scrollButton("arrow.up", L10n.Mouse.wheelUp, scrollAmount)
            scrollButton("arrow.down", L10n.Mouse.wheelDown, -scrollAmount)
        }
    }

    private var mouseButtonsRow: some View {
        HStack(spacing: cellGap) {
            mouseButton(.left, L10n.Mouse.leftButton)
            mouseButton(.middle, L10n.Mouse.middleButton)
            mouseButton(.right, L10n.Mouse.rightButton)
        }
    }

    private func mouseButton(_ button: MouseButtons, _ label: LocalizedStringKey) -> some View {
        #if os(iOS)
            RoundedRectangle(cornerRadius: 12)
                .fill(groupFill)
                .opacity(mouseInput.buttons.contains(button) ? 0.5 : 1)
                .overlay {
                    MouseButtonTouchView { pressed in
                        setMouseButton(button, pressed: pressed)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { clickMouse(button) }
        #else
            HoldButton(
                onPress: { setMouseButton(button, pressed: true) },
                onRelease: { setMouseButton(button, pressed: false) },
                background: { RoundedRectangle(cornerRadius: 12).fill(groupFill) },
                label: { Color.clear }
            )
            .accessibilityLabel(label)
        #endif
    }

    private func scrollButton(_ icon: String, _ label: LocalizedStringKey, _ wheel: Int8) -> some View {
        HoldButton(
            onPress: { scrollMouse(wheel) },
            onRelease: {},
            background: { RoundedRectangle(cornerRadius: 12).fill(groupFill) },
            label: { Image(systemName: icon).font(.body) }
        )
        .accessibilityLabel(label)
    }

    private func setMouseButton(_ button: MouseButtons, pressed: Bool) {
        if pressed, scenePhase != .active || !hid.isConnected { return }
        guard let report = mouseInput.setButton(button, pressed: pressed) else { return }
        #if os(iOS)
            if pressed { Haptics.tap() }
        #endif
        hid.sendMouse(report)
    }

    private func releaseMouseButtons() {
        guard let report = mouseInput.releaseAll() else { return }
        hid.sendMouse(report)
    }

    private func moveMouse(dx: Int8, dy: Int8) {
        hid.sendMouse(mouseInput.move(dx: dx, dy: dy))
    }

    private func scrollMouse(_ wheel: Int8) {
        mouseInput.scroll(wheel).forEach(hid.sendMouse)
    }

    private func clickMouse(_ button: MouseButtons) {
        guard scenePhase == .active else { return }
        let reports = mouseInput.click(button)
        guard !reports.isEmpty else { return }
        Haptics.tap()
        reports.forEach(hid.sendMouse)
    }
}
