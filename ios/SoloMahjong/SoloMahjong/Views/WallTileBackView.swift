import SwiftUI

enum WallOrientation {
    case horizontal
    case vertical
}

struct WallTileBackView: View {
    let count: Int
    let orientation: WallOrientation

    var body: some View {
        Group {
            if orientation == .horizontal {
                HStack(spacing: -1) {
                    ForEach(0..<min(count, 14), id: \.self) { _ in
                        singleBack
                    }
                }
            } else {
                GeometryReader { geo in
                    let tileCount = min(count, 14)
                    let step = verticalStep(for: tileCount, height: geo.size.height)

                    ZStack {
                        ForEach(0..<tileCount, id: \.self) { index in
                            singleBack
                                .rotationEffect(.degrees(90))
                                .position(
                                    x: geo.size.width / 2,
                                    y: 12 + CGFloat(index) * step
                                )
                        }
                    }
                }
            }
        }
    }

    private func verticalStep(for tileCount: Int, height: CGFloat) -> CGFloat {
        guard tileCount > 1 else { return 0 }
        let fitted = (height - 24) / CGFloat(tileCount - 1)
        return max(20, min(24, fitted))
    }

    private var singleBack: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.96, green: 0.66, blue: 0.22),
                            Color(red: 0.74, green: 0.42, blue: 0.07),
                            Color(red: 0.56, green: 0.30, blue: 0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 22, height: 34)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(red: 0.98, green: 0.96, blue: 0.90))
                .frame(width: 22, height: 5)
                .overlay(
                    Rectangle()
                        .fill(.white.opacity(0.35))
                        .frame(height: 1),
                    alignment: .top
                )
        }
        .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1.4)
    }
}
