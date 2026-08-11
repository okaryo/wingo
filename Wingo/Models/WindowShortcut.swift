enum WindowShortcut {
    static let supportedNumbers = 1...9

    static func listIndex(for number: Int, windowCount: Int) -> Int? {
        guard supportedNumbers.contains(number) else {
            return nil
        }

        let index = number - 1
        return index < windowCount ? index : nil
    }

    static func number(forListIndex index: Int) -> Int? {
        let number = index + 1
        return supportedNumbers.contains(number) ? number : nil
    }
}
