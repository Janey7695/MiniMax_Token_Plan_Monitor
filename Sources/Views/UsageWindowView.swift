import SwiftUI

struct UsageWindowView: View {
    @ObservedObject var usageService: UsageHistoryService

    var body: some View {
        VStack(spacing: 8) {
            // Window indicator with navigation
            HStack {
                Button(action: { usageService.previousWindow() }) {
                    Image(systemName: "chevron.left")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.borderless)
                .help("上一个窗口")

                Spacer()

                VStack(spacing: 2) {
                    Text("Window \(usageService.currentWindowIndex + 1)/5")
                        .font(.caption)
                        .fontWeight(.medium)

                    Text("(\(usageService.getWindowTimeRange()))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { usageService.nextWindow() }) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.borderless)
                .help("下一个窗口")
            }
            .padding(.horizontal, 8)

            // Bar chart for current window
            UsageBarChartView(
                buckets: usageService.getUsageBuckets(),
                maxUsage: usageService.getMaxUsage(),
                currentBucketIndex: usageService.displayedBucketIndex
            )
        }
    }
}
