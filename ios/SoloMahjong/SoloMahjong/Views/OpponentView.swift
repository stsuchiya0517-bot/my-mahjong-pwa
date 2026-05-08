import SwiftUI

enum OpponentLayoutStyle {
    case top
    case side
}

struct OpponentView: View {
    let player: MahjongPlayer
    let isActive: Bool
    let layoutStyle: OpponentLayoutStyle
    var riverRotation: Angle = .degrees(0)

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            topRow
            discardSection
            if !player.melds.isEmpty {
                MeldsView(melds: player.melds, rotation: riverRotation)
            }
            concealedHandRow

            if player.isThinking {
                HStack(spacing: 5) {
                    Circle().fill(.yellow).frame(width: 5, height: 5)
                    Text("考え中…")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.yellow)
                }
                .transition(.opacity)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(isActive ? 0.14 : 0.075))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isActive ? .yellow.opacity(0.8) : .white.opacity(0.12), lineWidth: isActive ? 1.6 : 1)
                )
        )
        .animation(.easeInOut(duration: 0.18), value: isActive)
        .animation(.easeInOut(duration: 0.18), value: player.isThinking)
    }

    private var topRow: some View {
        HStack(spacing: 5) {
            Text(player.name)
                .font(.system(size: layoutStyle == .top ? 13 : 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            if player.isDealer { badge("親", bg: .yellow, fg: .black) }
            if player.isReach { badge("リーチ", bg: .red, fg: .white) }

            Spacer(minLength: 4)

            Text("\(player.score)")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private var discardSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("河")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
            RiverGrid(tiles: player.discards, rotation: riverRotation, columns: layoutStyle == .top ? 10 : 4, tileSize: .small)
        }
    }

    private var concealedHandRow: some View {
        HStack(spacing: 3) {
            ForEach(0..<min(player.hand.count, layoutStyle == .top ? 13 : 8), id: \.self) { _ in
                HiddenTileBack(isTop: layoutStyle == .top)
            }
            Spacer(minLength: 0)
        }
    }

    private func badge(_ text: String, bg: Color, fg: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .black, design: .rounded))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(bg)
            .foregroundStyle(fg)
            .clipShape(Capsule())
    }
}

private struct HiddenTileBack: View {
    let isTop: Bool

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.93, green: 0.66, blue: 0.21), Color(red: 0.73, green: 0.45, blue: 0.08)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: isTop ? 15 : 12, height: isTop ? 23 : 19)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(red: 0.985, green: 0.985, blue: 0.965))
                .frame(width: isTop ? 15 : 12, height: isTop ? 3.8 : 3.2)
                .overlay(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .stroke(Color.white.opacity(0.7), lineWidth: 0.7)
                )
        }
        .shadow(color: .black.opacity(0.16), radius: 1.6, x: 0, y: 1.2)
    }
}


struct MeldsView: View {
    let melds: [MahjongMeld]
    var rotation: Angle = .degrees(0)

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("副露")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 6) {
                ForEach(melds) { meld in
                    MeldSetView(meld: meld, rotation: rotation)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

struct MeldSetView: View {
    let meld: MahjongMeld
    var rotation: Angle = .degrees(0)

    var body: some View {
        HStack(spacing: -2) {
            ForEach(Array(meld.tiles.enumerated()), id: \.element.id) { index, tile in
                TileView(tile: tile, isDiscard: true, isCompact: true, displayStyle: .river)
                    .rotationEffect(tile.id == meld.calledTile?.id ? rotation + .degrees(90) : rotation)
                    .zIndex(Double(index))
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .background(.black.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Text(meld.type.rawValue)
                .font(.system(size: 7, weight: .black, design: .rounded))
                .foregroundStyle(.yellow.opacity(0.9))
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(.black.opacity(0.35))
                .clipShape(Capsule())
                .offset(x: 2, y: -5)
        }
    }
}
