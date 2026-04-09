import SwiftUI

struct TokenRingView: View {
    let percentage: Double
    let lineWidth: CGFloat

    init(percentage: Double, lineWidth: CGFloat = 6) {
        self.percentage = percentage
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.gray.opacity(0.3),
                    lineWidth: lineWidth
                )

            Circle()
                .trim(from: 0, to: CGFloat(min(percentage, 1.0)))
                .stroke(
                    ringGradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: percentage)
        }
    }

    private var ringGradient: LinearGradient {
        // 剩余 100% → 绿色 (hue=0.33), 剩余 0% → 红色 (hue=0)
        let hue = (1 - percentage) * 0.33
        let color = Color(hue: hue, saturation: 0.8, brightness: 0.9)

        return LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct StatusItemView: View {
    let percentage: Int
    let isPlaceholder: Bool

    var body: some View {
        HStack(spacing: 4) {
            if isPlaceholder {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: 14, height: 14)
                Text("--")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            } else {
                TokenRingView(percentage: Double(percentage) / 100.0, lineWidth: 3)
                    .frame(width: 14, height: 14)

                Text(" \(percentage)%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
    }
}

//#Preview {
//    VStack(spacing: 20) {
//        TokenRingView(percentage: 0.75)
//            .frame(width: 60, height: 60)
//
//        StatusItemView(percentage: 75, isPlaceholder: false)
//        StatusItemView(percentage: 0, isPlaceholder: true)
//    }
//    .padding()
//}
