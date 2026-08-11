import Foundation

@MainActor
final class WindowHistory {
    private let maximumEntryCount: Int
    private(set) var currentWindowIdentifier: WindowIdentifier?
    private var recentWindowIdentifiers: [WindowIdentifier] = []

    init(maximumEntryCount: Int = 200) {
        self.maximumEntryCount = maximumEntryCount
    }

    func recordFocusedWindow(_ identifier: WindowIdentifier) {
        currentWindowIdentifier = identifier
        recentWindowIdentifiers.removeAll { $0 == identifier }
        recentWindowIdentifiers.insert(identifier, at: 0)

        if recentWindowIdentifiers.count > maximumEntryCount {
            recentWindowIdentifiers.removeLast(
                recentWindowIdentifiers.count - maximumEntryCount
            )
        }
    }

    func orderedWindows(_ windows: [WindowItem]) -> [WindowItem] {
        let historyRanks = Dictionary(
            uniqueKeysWithValues: recentWindowIdentifiers.enumerated().map { ($1, $0) }
        )

        return windows.enumerated()
            .sorted { left, right in
                let leftRank = historyRanks[left.element.id]
                let rightRank = historyRanks[right.element.id]

                switch (leftRank, rightRank) {
                case let (leftRank?, rightRank?):
                    return leftRank < rightRank
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return left.offset < right.offset
                }
            }
            .map(\.element)
    }

    func initialSelection(in windows: [WindowItem]) -> WindowIdentifier? {
        guard let currentWindowIdentifier else {
            return windows.first?.id
        }

        return windows.first(where: { $0.id != currentWindowIdentifier })?.id
            ?? windows.first?.id
    }
}
