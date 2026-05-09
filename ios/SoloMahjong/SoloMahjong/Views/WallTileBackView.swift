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
                VStack(spacing: -1) {
                    ForEach(0..<min(count, 14), id: \.self) { _ in
                        singleBack.rotationEffect(.degrees(90))
                    }
                }
            }
        }
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
