import SwiftUI

struct DPadView: View {
    let onPress: (ConsumerReport) -> Void
    let onRelease: () -> Void

    var body: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().fill(groupFill)

                wedge(.menuUp, 225, 315, L10n.Remote.up)
                wedge(.menuDown, 45, 135, L10n.Remote.down)
                wedge(.menuLeft, 135, 225, L10n.Remote.left)
                wedge(.menuRight, -45, 45, L10n.Remote.right)

                arrow("chevron.up").offset(y: -d * 0.34)
                arrow("chevron.down").offset(y: d * 0.34)
                arrow("chevron.left").offset(x: -d * 0.34)
                arrow("chevron.right").offset(x: d * 0.34)

                center.frame(width: d / 3, height: d / 3)
            }
            .frame(width: d, height: d)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func wedge(_ key: ConsumerKey, _ start: Double, _ end: Double, _ label: LocalizedStringKey) -> some View {
        PressableShape(
            shape: Wedge(start: start, end: end),
            onPress: { onPress(ConsumerReport(key: key)) },
            onRelease: onRelease
        )
        .accessibilityLabel(label)
    }

    private func arrow(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.title2.weight(.semibold))
            .foregroundColor(.primary)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var center: some View {
        PressableShape(
            shape: Circle(),
            onPress: { onPress(ConsumerReport(key: .menuPick)) },
            onRelease: onRelease,
            highlight: Color.primary.opacity(0.1)
        )
        .overlay(Circle().strokeBorder(Color.primary.opacity(0.22), lineWidth: 2))
        .accessibilityLabel(L10n.Remote.select)
    }
}

private struct PressableShape<S: Shape>: View {
    let shape: S
    let onPress: () -> Void
    let onRelease: () -> Void
    var highlight: Color = .primary.opacity(0.14)
    @State private var pressed = false

    var body: some View {
        shape
            .fill(pressed ? highlight : .clear)
            .contentShape(shape)
            .modifier(PressGesture(onPress: onPress, onRelease: onRelease, pressed: $pressed))
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
    }
}

private struct Wedge: Shape {
    let start: Double
    let end: Double
    var innerRatio: CGFloat = 1.0 / 3.0

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        var p = Path()
        p.addArc(center: c, radius: r, startAngle: .degrees(start), endAngle: .degrees(end), clockwise: false)
        p.addArc(center: c, radius: r * innerRatio, startAngle: .degrees(end), endAngle: .degrees(start), clockwise: true)
        p.closeSubpath()
        return p
    }
}
