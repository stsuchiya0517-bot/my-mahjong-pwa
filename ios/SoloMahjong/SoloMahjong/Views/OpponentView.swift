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
        VStack(alignment: .leading, spacing: 8) {
            topRow
            concealedHandRow
            discardSection

            if player.isThinking {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.yellow)
                        .frame(width: 6, height: 6)
                    Text("考え中…")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.yellow)
                }
                .transition(.opacity)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(isActive ? 0.14 : 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isActive ? .yellow.opacity(0.8) : .white.opacity(0.12), lineWidth: isActive ? 1.6 : 1)
                )
        )
        .animation(.easeInOut(duration: 0.18), value: isActive)
        .animation(.easeInOut(duration: 0.18), value: player.isThinking)
    }

    private var topRow: some View {
        HStack(spacing: 6) {
            Text(player.name)
                .font(.system(size: layoutStyle == .top ? 14 : 13, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            if player.isDealer {
                badge("親", bg: .yellow, fg: .black)
            }

            if player.isReach {
                badge("リーチ", bg: .red, fg: .white)
            }

            Spacer(minLength: 4)

            Text("\(player.score)")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private var concealedHandRow: some View {
        HStack(spacing: 3) {
            ForEach(0..<min(player.hand.count, layoutStyle == .top ? 13 : 8), id: \.self) { _ in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.44, blue: 0.78),
                                Color(red: 0.07, green: 0.30, blue: 0.62)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: layoutStyle == .top ? 16 : 12, height: layoutStyle == .top ? 26 : 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(.white.opacity(0.16), lineWidth: 1)
                    )
            }
            Spacer(minLength: 0)
        }
    }

    private var discardSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("捨て牌")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))

            discardGrid
        }
    }

    private var discardGrid: some View {
        let maxColumns = layoutStyle == .top ? 6 : 3
        let columns = Array(repeating: GridItem(.fixed(34), spacing: 4), count: maxColumns)

        return LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
            ForEach(player.discards) { tile in
                TileView(tile: tile, isDiscard: true, isCompact: true)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)
        .background(.black.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func badge(_ text: String, bg: Color, fg: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(bg)
            .foregroundStyle(fg)
            .clipShape(Capsule())
    }
}
