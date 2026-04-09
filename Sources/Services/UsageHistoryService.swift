import Foundation

/// Service managing usage history across all 5 windows for the current day
class UsageHistoryService: ObservableObject {
    // MARK: - Constants
    private let bucketMinutes = 15

    /// Window definitions: (startHour, bucketCount)
    private let windowDefinitions: [(startHour: Int, bucketCount: Int)] = [
        (0, 20),    // Window 0: 00:00-05:00 (20 buckets)
        (5, 20),    // Window 1: 05:00-10:00 (20 buckets)
        (10, 20),   // Window 2: 10:00-15:00 (20 buckets)
        (15, 20),   // Window 3: 15:00-20:00 (20 buckets)
        (20, 16)    // Window 4: 20:00-24:00 (16 buckets - special case)
    ]

    // MARK: - Published State
    @Published private(set) var currentWindowIndex: Int = 0
    @Published private(set) var dailyData: DailyUsageData?
    @Published private(set) var currentBucketIndex: Int = 0
    @Published private(set) var liveWindowIndex: Int = 0  // The actual live window based on current time

    // MARK: - Private State
    private var previousRemainingCount: Int?
    private let storage = StorageManager.shared

    // MARK: - Initialization
    init() {
        loadTodayData()
        cleanupOldData()
    }

    // MARK: - Public API

    /// Called when API returns new usage data
    /// Maps API's startTime/endTime to the appropriate fixed daily window
    func setWindow(startTime: Int64, endTime: Int64) {
        // Convert API timestamps to calendar date/time
        let startDate = Date(timeIntervalSince1970: Double(startTime) / 1000)
        let calendar = Calendar.current

        let hour = calendar.component(.hour, from: startDate)
        let minute = calendar.component(.minute, from: startDate)

        // Determine which window this API window belongs to
        let windowIndex = hourToWindowIndex(hour: hour)

        // Get date string for this window
        let dateString = storage.dateString(from: startDate)

        // Load or create daily data
        if dailyData?.date != dateString {
            if let existing = storage.loadDailyData(for: dateString) {
                dailyData = existing
            } else {
                dailyData = DailyUsageData(date: dateString)
            }
        }

        currentWindowIndex = windowIndex
        liveWindowIndex = windowIndex

        // Calculate current bucket index based on elapsed time in window
        let windowInfo = windowDefinitions[windowIndex]
        let windowStartMinute = windowInfo.startHour * 60
        let currentMinute = hour * 60 + minute
        let elapsedMinutes = currentMinute - windowStartMinute
        currentBucketIndex = min(max(elapsedMinutes / bucketMinutes, 0), windowInfo.bucketCount - 1)
    }

    /// Adds a usage sample, calculating which bucket to increment
    func addSample(remainingCount: Int, timestamp: Date = Date()) {
        guard var data = dailyData else { return }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: timestamp)
        let minute = calendar.component(.minute, from: timestamp)

        // Determine which window this sample belongs to
        let windowIndex = hourToWindowIndex(hour: hour)
        let windowInfo = windowDefinitions[windowIndex]

        // Calculate bucket index within this window
        let minutesFromWindowStart = (hour * 60 + minute) - (windowInfo.startHour * 60)
        let bucketIndex = minutesFromWindowStart / bucketMinutes

        guard bucketIndex >= 0 && bucketIndex < windowInfo.bucketCount else { return }

        // Calculate usage delta
        if let prevRemaining = previousRemainingCount {
            let usage = max(0, prevRemaining - remainingCount)
            if usage > 0 {
                data.windows[windowIndex].buckets[bucketIndex] += usage
                data.windows[windowIndex].hasData = true
            }
        }

        previousRemainingCount = remainingCount
        dailyData = data

        // Persist to disk
        try? storage.saveDailyData(data)
    }

    /// Returns buckets for the specified window (default: current window)
    func getUsageBuckets(for windowIndex: Int? = nil) -> [Int] {
        let index = windowIndex ?? currentWindowIndex
        guard let data = dailyData, index < data.windows.count else {
            return Array(repeating: 0, count: 20)
        }
        return data.windows[index].buckets
    }

    /// Returns max usage value across all buckets in specified window
    func getMaxUsage(for windowIndex: Int? = nil) -> Int {
        let index = windowIndex ?? currentWindowIndex
        let buckets = getUsageBuckets(for: index)
        return max(buckets.max() ?? 1, 1)
    }

    /// Returns bucket count for specified window
    func getBucketCount(for windowIndex: Int? = nil) -> Int {
        let index = windowIndex ?? currentWindowIndex
        return windowDefinitions[index].bucketCount
    }

    /// Returns the bucket index to highlight for display
    /// Returns -1 if viewing a historical window (not the live one)
    var displayedBucketIndex: Int {
        if currentWindowIndex == liveWindowIndex {
            return currentBucketIndex
        }
        return -1  // No highlight for historical windows
    }

    /// Navigates to the next window (wraps from 4 to 0)
    func nextWindow() {
        currentWindowIndex = (currentWindowIndex + 1) % 5
    }

    /// Navigates to the previous window (wraps from 0 to 4)
    func previousWindow() {
        currentWindowIndex = (currentWindowIndex - 1 + 5) % 5
    }

    /// Returns window time range string (e.g., "10:00-15:00")
    func getWindowTimeRange(for index: Int? = nil) -> String {
        let i = index ?? currentWindowIndex
        if let data = dailyData, i < data.windows.count {
            return data.windows[i].timeRangeString
        }
        // Fallback to calculated values
        let def = windowDefinitions[i]
        return String(format: "%02d:00-%02d:00", def.startHour, def.startHour + (i == 4 ? 4 : 5))
    }

    // MARK: - Private Helpers

    private func hourToWindowIndex(hour: Int) -> Int {
        switch hour {
        case 0..<5: return 0
        case 5..<10: return 1
        case 10..<15: return 2
        case 15..<20: return 3
        case 20..<24: return 4
        default: return 0
        }
    }

    private func loadTodayData() {
        let todayString = storage.todayDateString()
        if let existing = storage.loadDailyData(for: todayString) {
            dailyData = existing
        } else {
            dailyData = DailyUsageData(date: todayString)
        }
    }

    private func cleanupOldData() {
        storage.cleanupOldFiles(olderThanDays: 1)
    }
}
