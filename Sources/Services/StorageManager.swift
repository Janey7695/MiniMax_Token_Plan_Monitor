import Foundation

/// Manages JSON file storage in ~/.cache/minimonitor/
class StorageManager {
    static let shared = StorageManager()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        let homeDir = fileManager.homeDirectoryForCurrentUser
        cacheDirectory = homeDir.appendingPathComponent(".cache/minimonitor")

        // Create directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Returns URL for a daily usage file
    func fileURL(for date: String) -> URL {
        return cacheDirectory.appendingPathComponent("usage_\(date).json")
    }

    /// Returns today's date string in YYYY-MM-DD format
    func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    /// Returns date string for a given Date
    func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    /// Loads DailyUsageData for a given date string
    func loadDailyData(for date: String) -> DailyUsageData? {
        let url = fileURL(for: date)
        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let dailyData = try? JSONDecoder().decode(DailyUsageData.self, from: data) else {
            return nil
        }
        return dailyData
    }

    /// Saves DailyUsageData for a given date
    func saveDailyData(_ dailyData: DailyUsageData) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(dailyData)
        let url = fileURL(for: dailyData.date)
        try data.write(to: url)
    }

    /// Deletes usage files older than the specified number of days
    func cleanupOldFiles(olderThanDays: Int = 1) {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -olderThanDays, to: Date())!

        for fileURL in files {
            guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                  let creationDate = attributes[.creationDate] as? Date,
                  creationDate < cutoffDate else {
                continue
            }
            try? fileManager.removeItem(at: fileURL)
        }
    }
}
