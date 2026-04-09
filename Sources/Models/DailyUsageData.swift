import Foundation

/// Represents complete usage data for a single calendar day
/// Stored as JSON in ~/.cache/minimonitor/usage_YYYY-MM-DD.json
struct DailyUsageData: Codable {
    let date: String  // "YYYY-MM-DD" format
    var windows: [WindowUsage]  // Always 5 windows (indices 0-4)

    init(date: String) {
        self.date = date
        self.windows = [
            WindowUsage(windowIndex: 0, bucketCount: 20),
            WindowUsage(windowIndex: 1, bucketCount: 20),
            WindowUsage(windowIndex: 2, bucketCount: 20),
            WindowUsage(windowIndex: 3, bucketCount: 20),
            WindowUsage(windowIndex: 4, bucketCount: 16)  // Special: only 16 buckets (20:00-24:00)
        ]
    }
}

/// Represents usage data for a single 5-hour window within a day
struct WindowUsage: Codable {
    let windowIndex: Int  // 0-4
    var buckets: [Int]     // Usage counts per 15-minute bucket
    var hasData: Bool      // Whether any usage was recorded in this window

    init(windowIndex: Int, bucketCount: Int) {
        self.windowIndex = windowIndex
        self.buckets = Array(repeating: 0, count: bucketCount)
        self.hasData = false
    }

    /// Returns the time range this window represents
    func windowTimeRange() -> (start: String, end: String) {
        switch windowIndex {
        case 0: return ("00:00", "05:00")
        case 1: return ("05:00", "10:00")
        case 2: return ("10:00", "15:00")
        case 3: return ("15:00", "20:00")
        case 4: return ("20:00", "24:00")
        default: return ("--:--", "--:--")
        }
    }

    /// Returns formatted time range string
    var timeRangeString: String {
        let range = windowTimeRange()
        return "\(range.start)-\(range.end)"
    }
}
