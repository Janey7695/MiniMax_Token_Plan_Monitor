import Foundation

struct UsageResponse: Codable {
    let modelRemains: [ModelRemain]
    let baseResp: BaseResp

    enum CodingKeys: String, CodingKey {
        case modelRemains = "model_remains"
        case baseResp = "base_resp"
    }
}

struct BaseResp: Codable {
    let statusCode: Int
    let statusMsg: String

    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case statusMsg = "status_msg"
    }
}

struct ModelRemain: Codable, Identifiable {
    let modelName: String
    let currentIntervalTotalCount: Int
    let currentIntervalRemainUsageCount: Int
    let remainsTime: Int
    let startTime: Int64
    let endTime: Int64

    var id: String { modelName }

    enum CodingKeys: String, CodingKey {
        case modelName = "model_name"
        case currentIntervalTotalCount = "current_interval_total_count"
        case currentIntervalRemainUsageCount = "current_interval_usage_count"// minimax api 有问题，返回的json文件中，居然是用current_interval_usage_count表示剩余用量的？？？
//        case currentIntervalUsageCount = "current_interval_usage_count"
        case remainsTime = "remains_time"
        case startTime = "start_time"
        case endTime = "end_time"
    }

    var remainingCount: Int {
        return currentIntervalRemainUsageCount
    }

    var percentage: Double {
        guard currentIntervalTotalCount > 0 else { return 0 }
        return Double(currentIntervalTotalCount - remainingCount) / Double(currentIntervalTotalCount)
    }

    var remainingTimeFormatted: String {
        let seconds = remainsTime / 1000
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}
