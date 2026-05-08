import SwiftUI

enum OpponentLayoutStyle {
    case top
    case side
}

struct OpponentView: View {
    let player: MahjongPlayer
    let isActive: Bool
    let layoutStyle: OpponentLayoutStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(player.name)
                    .font(.system(size: layoutStyle == .top ? 13 : 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if player.isDealer {
                    Text("親")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.yellow)
                        .foregroundStyle(.black)
                        .clipShape(Capsule())
                }

                Spacer(minLength: 2)

                Text("\(player.score)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            HStack(spacing: 3) {
                ForEach(0..<min(player.hand.count, layoutStyle == .top ? 13 : 8), id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.95), Color.blue.opacity(0.45)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: layoutStyle == .top ? 14 : 11, height: layoutStyle == .top ? 24 : 20)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 4) {
                ForEach(player.discards.suffix(layoutStyle == .top ? 6 : 3)) { tile in
                    TileView(tile: tile, isDiscard: true, isCompact: true)
                }
                Spacer(minLength: 0)
            }
            .frame(minHeight: 38, alignment: .leading)

            if player.isThinking {
                Text("考え中…")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.yellow)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(isActive ? 0.15 : 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isActive ? .yellow.opacity(0.8) : .white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}
