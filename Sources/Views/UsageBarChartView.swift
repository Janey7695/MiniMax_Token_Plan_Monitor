import SwiftUI

struct UsageBarChartView: View {
    let buckets: [Int]
    let maxUsage: Int
    let currentBucketIndex: Int

    private var bucketCount: Int { buckets.count }
    private let bucketWidth: CGFloat = 8
    private let bucketSpacing: CGFloat = 2

    @State private var hoveredBucketIndex: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("用量分布 (每15分钟)")
                .font(.caption)
                .foregroundColor(.secondary)

            ZStack(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: bucketSpacing) {
                    ForEach(0..<bucketCount, id: \.self) { index in
                        barView(for: index)
                    }
                }
                .frame(height: 40)

                if let hoveredIndex = hoveredBucketIndex {
                    tooltipView(for: hoveredIndex)
                        .offset(y: -50)
                }
            }

            // Time labels - adjust based on window duration
            let isShortWindow = bucketCount <= 16  // Window 4 is only 4 hours
            HStack {
                Text("0h")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                Spacer()
                if !isShortWindow {
                    Text("2.5h")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                Text(isShortWindow ? "4h" : "5h")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func tooltipView(for index: Int) -> some View {
        let usage = index < buckets.count ? buckets[index] : 0
        return Text("\(usage) 次")
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.primary.opacity(0.9))
            .foregroundColor(Color(NSColor.windowBackgroundColor))
            .cornerRadius(4)
    }

    private func barView(for index: Int) -> some View {
        let usage = index < buckets.count ? buckets[index] : 0
        let heightRatio = maxUsage > 0 ? CGFloat(usage) / CGFloat(maxUsage) : 0
        let isCurrentBucket = index == currentBucketIndex

        return VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(barColor(usage: usage, isCurrentBucket: isCurrentBucket))
                .frame(width: bucketWidth, height: max(4, 36 * heightRatio))
                .onHover { isHovered in
                    hoveredBucketIndex = isHovered ? index : nil
                }

            if isCurrentBucket {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 4, height: 4)
            }
        }
    }

    private func barColor(usage: Int, isCurrentBucket: Bool) -> Color {
        if usage == 0 {
            return Color.gray.opacity(0.2)
        }

        if isCurrentBucket {
            return Color.blue
        }

        // Gradient from green (low usage) to orange (high usage)
        let intensity = maxUsage > 0 ? CGFloat(usage) / CGFloat(maxUsage) : 0
        let hue = 0.33 - (intensity * 0.2)  // Green (0.33) to Orange (0.1)
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
    }
}

struct UsageBarChartView_Previews: PreviewProvider {
    static var previews: some View {
        UsageBarChartView(
            buckets: [5, 10, 3, 15, 8, 0, 0, 12, 7, 4, 9, 2, 6, 11, 3, 8, 5, 1, 0, 0],
            maxUsage: 15,
            currentBucketIndex: 5
        )
        .padding()
        .frame(width: 260)
    }
}
