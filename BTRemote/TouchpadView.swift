#if os(iOS)
    import SwiftUI
    import UIKit

    /// 1-finger drag: moves
    /// 1-finger tap: left-clicks
    /// 2-finger tap: right-clicks
    /// 2-finger drag: scrolls
    struct TouchpadView: UIViewRepresentable {
        var moveSensitivity: CGFloat
        var scrollSensitivity: CGFloat
        var onMove: (Int8, Int8) -> Void
        var onMoveCancelled: () -> Void
        var onScroll: (Int8) -> Void
        var onLeftClick: () -> Void
        var onRightClick: () -> Void

        func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        func makeUIView(context: Context) -> UIView {
            let view = UIView()
            view.backgroundColor = .clear
            view.isMultipleTouchEnabled = true
            let c = context.coordinator

            let move = UIPanGestureRecognizer(target: c, action: #selector(Coordinator.handleMove(_:)))
            move.minimumNumberOfTouches = 1
            move.maximumNumberOfTouches = 1
            move.delegate = c

            let scroll = UIPanGestureRecognizer(target: c, action: #selector(Coordinator.handleScroll(_:)))
            scroll.minimumNumberOfTouches = 2
            scroll.maximumNumberOfTouches = 2
            scroll.delegate = c

            let left = UITapGestureRecognizer(target: c, action: #selector(Coordinator.handleLeft))
            left.numberOfTouchesRequired = 1
            left.delegate = c

            let right = UITapGestureRecognizer(target: c, action: #selector(Coordinator.handleRight))
            right.numberOfTouchesRequired = 2
            right.delegate = c

            [move, scroll, left, right].forEach { view.addGestureRecognizer($0) }
            return view
        }

        func updateUIView(_ uiView: UIView, context: Context) {
            let c = context.coordinator
            c.moveSensitivity = moveSensitivity
            c.scrollSensitivity = scrollSensitivity
            c.onMove = onMove
            c.onMoveCancelled = onMoveCancelled
            c.onScroll = onScroll
            c.onLeftClick = onLeftClick
            c.onRightClick = onRightClick
        }

        @MainActor
        final class Coordinator: NSObject, UIGestureRecognizerDelegate {
            var moveSensitivity: CGFloat = 1
            var scrollSensitivity: CGFloat = 1
            var onMove: (Int8, Int8) -> Void = { _, _ in }
            var onMoveCancelled: () -> Void = {}
            var onScroll: (Int8) -> Void = { _ in }
            var onLeftClick: () -> Void = {}
            var onRightClick: () -> Void = {}

            private var scrollAccumulator: CGFloat = 0
            private let scrollStep: CGFloat = 6

            @objc func handleMove(_ pan: UIPanGestureRecognizer) {
                if pan.state == .cancelled {
                    onMoveCancelled()
                    return
                }
                guard pan.state == .began || pan.state == .changed || pan.state == .ended else { return }
                guard let view = pan.view else { return }
                let t = pan.translation(in: view)
                onMove(HIDInput.clamp(t.x * moveSensitivity), HIDInput.clamp(t.y * moveSensitivity))
                pan.setTranslation(.zero, in: view)
            }

            @objc func handleScroll(_ pan: UIPanGestureRecognizer) {
                guard let view = pan.view else { return }
                if pan.state == .began { scrollAccumulator = 0 }
                scrollAccumulator += pan.translation(in: view).y
                pan.setTranslation(.zero, in: view)
                let step = scrollStep / max(scrollSensitivity, 0.1)
                while abs(scrollAccumulator) >= step {
                    // drag up: scroll up (positive wheel)
                    onScroll(scrollAccumulator > 0 ? -1 : 1)
                    scrollAccumulator -= scrollAccumulator > 0 ? step : -step
                }
            }

            @objc func handleLeft() {
                onLeftClick()
            }

            @objc func handleRight() {
                onRightClick()
            }

            nonisolated func gestureRecognizer(
                _ gestureRecognizer: UIGestureRecognizer,
                shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
            ) -> Bool {
                true
            }
        }
    }
#endif
