#if os(iOS)
    import SwiftUI
    import UIKit

    /// Tracks the button's finger independently of the touchpad's pan recognizer.
    struct MouseButtonTouchView: UIViewRepresentable {
        let onPressChanged: (Bool) -> Void

        func makeUIView(context: Context) -> Control {
            let control = Control()
            control.isAccessibilityElement = false
            control.isExclusiveTouch = false
            control.onPressChanged = onPressChanged
            return control
        }

        func updateUIView(_ control: Control, context: Context) {
            control.onPressChanged = onPressChanged
        }

        final class Control: UIControl {
            var onPressChanged: (Bool) -> Void = { _ in }

            override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
                onPressChanged(true)
                return true
            }

            override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
                super.endTracking(touch, with: event)
                onPressChanged(false)
            }

            override func cancelTracking(with event: UIEvent?) {
                super.cancelTracking(with: event)
                onPressChanged(false)
            }
        }
    }
#endif
