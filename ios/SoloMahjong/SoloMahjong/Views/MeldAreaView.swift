import SwiftUI

struct MeldAreaView: View {
    let melds: [MahjongMeld]
    let seat: PlayerSeat

    var body: some View {
        HStack(spacing: 5) {
            ForEach(melds) { meld in
                MeldSetView(meld: meld, seat: seat)
            }
            Spacer(minLength: 0)
        }
        .opacity(melds.isEmpty ? 0 : 1)
    }
}

struct MeldSetView: View {
    let meld: MahjongMeld
    let seat: PlayerSeat

    var body: some View {
        HStack(spacing: -2) {
            ForEach(Array(meld.tiles.enumerated()), id: \.element.id) { index, tile in
                TileView(tile: tile, isDiscard: true, displayStyle: .river)
                    .rotationEffect(rotation(for: tile))
                    .zIndex(Double(index))
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .background(.black.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Text(meld.type.rawValue)
                .font(.system(size: 7, weight: .black, design: .rounded))
                .foregroundStyle(.yellow.opacity(0.95))
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(.black.opacity(0.42))
                .clipShape(Capsule())
                .offset(x: 2, y: -5)
        }
    }

    private func rotation(for tile: MahjongTile) -> Angle {
        guard tile.id == meld.calledTile?.id else {
            switch seat {
            case .bottom: return .zero
            case .top: return .degrees(180)
            case .left: return .degrees(90)
            case .right: return .degrees(-90)
            }
        }

        switch meld.fromPlayerIndex {
        case 1: return .degrees(-90)
        case 2: return .degrees(180)
        case 3: return .degrees(90)
        default: return .degrees(90)
        }
    }
}
