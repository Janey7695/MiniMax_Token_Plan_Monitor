import SwiftUI

struct PopoverContentView: View {
    let usageData: ModelRemain?
    let apiStatus: AppDelegate.APIStatus
    let lastUpdateTime: Date?
    let onRefresh: () -> Void
    let onOpenSettings: () -> Void
    let onQuit: () -> Void
    let usageHistoryService: UsageHistoryService

    @State private var showSettings = false

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()

            if let data = usageData {
                contentView(data: data)
            } else {
                emptyStateView
            }

            Divider()
            footerView
        }
        .frame(width: 280, height: 450)
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "chart.pie.fill")
                .foregroundColor(.blue)
            Text("MiniMax Token Plan Monitor")
                .font(.headline)
            Spacer()
        }
        .padding()
    }

    private func contentView(data: ModelRemain) -> some View {
        VStack(spacing: 12) {
            ringSection(data: data)
            Divider()
            barChartSection
            Divider()
            detailsSection(data: data)
            Divider()
            statusSection
        }
        .padding()
    }

    private var barChartSection: some View {
        UsageWindowView(usageService: usageHistoryService)
    }

    private func ringSection(data: ModelRemain) -> some View {
        HStack(spacing: 16) {
            TokenRingView(percentage: data.percentage, lineWidth: 8)
                .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(data.modelName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(data.currentIntervalTotalCount - data.remainingCount) / \(data.currentIntervalTotalCount) 次")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(Int(100 - data.percentage * 100))% 剩余")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(String(data.remainingTimeFormatted)) 后刷新")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private func detailsSection(data: ModelRemain) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("已用次数")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(data.currentIntervalTotalCount - data.remainingCount)")
                    .fontWeight(.medium)
            }

            HStack {
                Text("剩余次数")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(data.remainingCount)")
                    .fontWeight(.medium)
                    .foregroundColor(data.remainingCount < 50 ? .orange : .primary)
            }

            HStack {
                Text("剩余时间")
                    .foregroundColor(.secondary)
                Spacer()
                Text(data.remainingTimeFormatted)
                    .fontWeight(.medium)
            }
        }
        .font(.caption)
    }

    private var statusSection: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            if let time = lastUpdateTime {
                Text("更新: \(dateFormatter.string(from: time))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var statusIcon: String {
        switch apiStatus {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }

    private var statusColor: Color {
        switch apiStatus {
        case .success:
            return .green
        case .error:
            return .orange
        case .unknown:
            return .gray
        }
    }

    private var statusText: String {
        switch apiStatus {
        case .success:
            return "API 正常"
        case .error(let msg):
            return msg
        case .unknown:
            return "状态未知"
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("暂无数据")
                .font(.subheadline)
            Text("请先在设置中配置 API Key")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var footerView: some View {
        HStack {
            Button(action: onOpenSettings) {
                Image(systemName: "gear")
            }
            .buttonStyle(.borderless)
            .help("设置")

            Spacer()

            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("刷新")

            Button(action: onQuit) {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("退出")
        }
        .padding()
    }
}
