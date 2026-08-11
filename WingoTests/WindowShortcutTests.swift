import XCTest

final class WindowShortcutTests: XCTestCase {
    func testMapsSupportedNumbersToZeroBasedListIndexes() {
        XCTAssertEqual(WindowShortcut.listIndex(for: 1, windowCount: 9), 0)
        XCTAssertEqual(WindowShortcut.listIndex(for: 5, windowCount: 9), 4)
        XCTAssertEqual(WindowShortcut.listIndex(for: 9, windowCount: 9), 8)
    }

    func testRejectsUnsupportedNumbers() {
        XCTAssertNil(WindowShortcut.listIndex(for: 0, windowCount: 10))
        XCTAssertNil(WindowShortcut.listIndex(for: 10, windowCount: 10))
    }

    func testRejectsNumberWithoutCorrespondingWindow() {
        XCTAssertNil(WindowShortcut.listIndex(for: 4, windowCount: 3))
    }

    func testMapsOnlyFirstNineIndexesToDisplayNumbers() {
        XCTAssertEqual(WindowShortcut.number(forListIndex: 0), 1)
        XCTAssertEqual(WindowShortcut.number(forListIndex: 8), 9)
        XCTAssertNil(WindowShortcut.number(forListIndex: 9))
    }
}
