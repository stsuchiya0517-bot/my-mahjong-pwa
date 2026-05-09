import SwiftUI

struct WinResultView: View {
    let result: WinResult
    let onNext: () -> Void

    var body: some View {
        ZStack {
            FeltBackground()

            VStack(spacing: 16) {
                Text(result.title)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.yellow)

                Text("\(result.winnerName) / \(result.method)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))

                VStack(alignment: .leading, spacing: 10) {
                    resultRow("役", result.yaku.joined(separator: "・"))
                    resultRow("翻", result.hanText)
                    resultRow("符", result.fuText)
                    resultRow("点数", result.scoreText)
                }
                .padding(18)
                .frame(maxWidth: 520)
                .background(.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text(result.explanation)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.70))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)

                Button(action: onNext) {
                    Text("次局へ")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .frame(width: 260, height: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding()
        }
    }

    private func resultRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
                .frame(width: 42, alignment: .leading)
            Text(value)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
        }
    }
}
