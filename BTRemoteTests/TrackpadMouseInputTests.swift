@testable import BTRemote
import XCTest

final class TrackpadMouseInputTests: XCTestCase {
    func testDragKeepsLeftButtonInEveryMoveReportUntilRelease() {
        var input = TrackpadMouseInput()

        XCTAssertEqual(input.setButton(.left, pressed: true).map { Array($0.data) }, [1, 0, 0, 0])
        XCTAssertEqual(Array(input.move(dx: 5, dy: -3).data), [1, 5, 253, 0])
        XCTAssertEqual(Array(input.move(dx: -8, dy: 2).data), [1, 248, 2, 0])
        XCTAssertEqual(input.setButton(.left, pressed: false).map { Array($0.data) }, [0, 0, 0, 0])
    }

    func testCancelReleasesAllButtonsOnceAndRestoresOrdinaryMovement() {
        var input = TrackpadMouseInput()
        _ = input.setButton(.left, pressed: true)
        _ = input.setButton(.right, pressed: true)

        XCTAssertEqual(input.releaseAll().map { Array($0.data) }, [0, 0, 0, 0])
        XCTAssertNil(input.releaseAll())
        XCTAssertNil(input.setButton(.left, pressed: false))
        XCTAssertEqual(Array(input.move(dx: 4, dy: 6).data), [0, 4, 6, 0])
    }

    func testScrollAndClickDoNotClearHeldLeftButton() {
        var input = TrackpadMouseInput()
        _ = input.setButton(.left, pressed: true)

        XCTAssertEqual(input.scroll(-2).map { Array($0.data) }, [[1, 0, 0, 254], [1, 0, 0, 0]])
        XCTAssertEqual(input.click(.right).map { Array($0.data) }, [[3, 0, 0, 0], [1, 0, 0, 0]])
        XCTAssertTrue(input.click(.left).isEmpty)
        XCTAssertEqual(Array(input.move(dx: 1, dy: 2).data), [1, 1, 2, 0])
    }

    func testReleasingOneButtonKeepsTheOtherHeld() {
        var input = TrackpadMouseInput()
        _ = input.setButton(.left, pressed: true)

        XCTAssertNil(input.setButton(.left, pressed: true))
        XCTAssertEqual(input.setButton(.right, pressed: true).map { Array($0.data) }, [3, 0, 0, 0])
        XCTAssertEqual(input.setButton(.left, pressed: false).map { Array($0.data) }, [2, 0, 0, 0])
        XCTAssertEqual(Array(input.move(dx: 2, dy: 3).data), [2, 2, 3, 0])
        XCTAssertEqual(input.setButton(.right, pressed: false).map { Array($0.data) }, [0, 0, 0, 0])
    }
}
