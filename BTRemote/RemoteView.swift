import BTHIDKit
import SwiftUI

private struct ConsumerButton {
    let report: ConsumerReport
    let icon: String
    let label: LocalizedStringKey

    init(_ key: ConsumerKey, _ icon: String, _ label: LocalizedStringKey) {
        report = ConsumerReport(key: key)
        self.icon = icon
        self.label = label
    }

    init(_ report: ConsumerReport, _ icon: String, _ label: LocalizedStringKey) {
        self.report = report
        self.icon = icon
        self.label = label
    }
}

struct RemoteView: View {
    let goToSetup: () -> Void

    @Environment(\.hid) private var hid
    @AppStorage(HIDSettings.developerModeKey) private var developerMode = false

    var body: some View {
        if hid.isActive || developerMode {
            controls
        } else {
            NotConnectedView(icon: "gamecontroller", goToSetup: goToSetup)
        }
    }

    private var controls: some View {
        GeometryReader { geo in
            if geo.size.width > geo.size.height {
                landscapeControls(geo.size)
            } else {
                portraitControls(geo.size)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func portraitControls(_ size: CGSize) -> some View {
        let h = size.height
        return VStack(spacing: cellGap) {
            mediaPill.frame(height: h * 0.11)
            grid.frame(maxHeight: .infinity)
            bottomRow.frame(height: h * 0.11)
            dpad.frame(height: h * 0.42)
        }
        .frame(width: size.width, height: size.height)
    }

    private func landscapeControls(_ size: CGSize) -> some View {
        let h = size.height
        return HStack(spacing: cellGap * 2) {
            VStack(spacing: cellGap) {
                mediaPill.frame(height: h * 0.16)
                grid.frame(maxHeight: .infinity)
                bottomRow.frame(height: h * 0.16)
            }
            dpad.frame(width: min(h, size.width * 0.42))
        }
        .frame(width: size.width, height: size.height)
    }

    private var mediaPill: some View {
        HStack(spacing: 0) {
            consumerMember(.init(.rewind, "backward.fill", L10n.Media.rewind))
            consumerMember(.init(.playPause, "playpause.fill", L10n.Media.playPause))
            consumerMember(.init(.fastForward, "forward.fill", L10n.Media.fastForward))
        }
        .background(RoundedRectangle(cornerRadius: 26).fill(groupFill))
    }

    private var grid: some View {
        HStack(spacing: cellGap) {
            sideColumn(
                pill: { verticalPill(
                    .init(.volumeUp, "speaker.wave.3.fill", L10n.Media.volumeUp),
                    .init(.volumeDown, "speaker.wave.1.fill", L10n.Media.volumeDown)
                ) },
                tail: { consumerCircle(.init(.mute, "speaker.slash.fill", L10n.Media.mute)) }
            )
            numberColumn([(1, .digit1), (4, .digit4), (7, .digit7)])
            numberColumn([(2, .digit2), (5, .digit5), (8, .digit8)])
            numberColumn([(3, .digit3), (6, .digit6), (9, .digit9)])
            sideColumn(
                pill: { verticalPill(
                    .init(.channelUp, "plus", L10n.Remote.channelUp),
                    .init(.channelDown, "minus", L10n.Remote.channelDown)
                ) },
                tail: { consumerCircle(.init(.closedCaption, "captions.bubble", L10n.Remote.closedCaptions)) }
            )
        }
    }

    private func numberColumn(_ keys: [(Int, Keycode)]) -> some View {
        VStack(spacing: cellGap) {
            ForEach(keys, id: \.0) { number, key in
                numberCircle(number, key)
            }
        }
    }

    private func sideColumn(
        @ViewBuilder pill: @escaping () -> some View,
        @ViewBuilder tail: @escaping () -> some View
    ) -> some View {
        GeometryReader { g in
            VStack(spacing: cellGap) {
                pill().frame(height: (g.size.height - cellGap) * 2 / 3)
                tail().frame(height: (g.size.height - cellGap) / 3)
            }
            .frame(width: g.size.width, height: g.size.height)
        }
    }

    private func verticalPill(_ top: ConsumerButton, _ bottom: ConsumerButton) -> some View {
        VStack(spacing: 0) {
            consumerMember(top)
            consumerMember(bottom)
        }
        .background(Capsule().fill(groupFill))
    }

    private var bottomRow: some View {
        HStack(spacing: cellGap) {
            consumerCircle(.init(.acBack, "arrow.left", L10n.Remote.back))
            consumerCircle(.init(.acHome, "house.fill", L10n.Remote.home))
            numberCircle(0, .digit0)
            consumerCircle(.init(.menu, "list.bullet", L10n.Remote.menu))
            consumerCircle(.init(.power, "power", L10n.Remote.power))
        }
    }

    private var dpad: some View {
        DPadView(
            onPress: { hid.sendConsumer($0) },
            onRelease: { hid.sendConsumer(.zero) }
        )
    }

    private func consumerCircle(_ button: ConsumerButton) -> some View {
        HoldButton(
            onPress: { hid.sendConsumer(button.report) },
            onRelease: { hid.sendConsumer(.zero) },
            background: { Circle().fill(groupFill) },
            label: { Image(systemName: button.icon).font(.title3) }
        )
        .accessibilityLabel(button.label)
    }

    private func consumerMember(_ button: ConsumerButton) -> some View {
        HoldButton(
            onPress: { hid.sendConsumer(button.report) },
            onRelease: { hid.sendConsumer(.zero) },
            background: { Color.clear },
            label: { Image(systemName: button.icon).font(.title3) }
        )
        .accessibilityLabel(button.label)
    }

    private func numberCircle(_ number: Int, _ key: Keycode) -> some View {
        HoldButton(
            onPress: { hid.sendKeyboard(KeyboardReport(keys: [key])) },
            onRelease: { hid.sendKeyboard(.zero) },
            background: { Circle().fill(groupFill) },
            label: { Text(verbatim: "\(number)").font(.title3.weight(.medium)) }
        )
    }
}

#if DEBUG
    #Preview {
        RemoteView(goToSetup: {})
    }
#endif
