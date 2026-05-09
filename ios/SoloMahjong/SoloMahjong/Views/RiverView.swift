import SwiftUI

struct RiverView: View {
    let tiles: [MahjongTile]
    let reachDiscardID: MahjongTile.ID?
    let seat: PlayerSeat

    var body: some View {
        Group {
            switch seat {
            case .bottom:
                LazyVGrid(columns: gridColumns, spacing: 2) {
                    ForEach(tiles) { tile in
                        riverTile(tile)
                    }
                }
            case .top:
                LazyVGrid(columns: gridColumns, spacing: 2) {
                    ForEach(tiles) { tile in
                        riverTile(tile).rotationEffect(.degrees(180))
                    }
                }
                .rotationEffect(.degrees(180))
            case .left:
                GeometryReader { geo in
                    ZStack(alignment: .topLeading) {
                        ForEach(Array(tiles.enumerated()), id: \.element.id) { index, tile in
                            riverTile(tile)
                                .rotationEffect(.degrees(90))
                                .position(leftPosition(for: index, in: geo.size))
                        }
                    }
                }
            case .right:
                GeometryReader { geo in
                    ZStack(alignment: .topLeading) {
                        ForEach(Array(tiles.enumerated()), id: \.element.id) { index, tile in
                            riverTile(tile)
                                .rotationEffect(.degrees(-90))
                                .position(rightPosition(for: index, in: geo.size))
                        }
                    }
                }
            }
        }
        .padding(3)
        .animation(.easeOut(duration: 0.18), value: tiles.count)
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.fixed(29), spacing: 2), count: 6)
    }

    private func leftPosition(for index: Int, in size: CGSize) -> CGPoint {
        let row = index % 6
        let column = index / 6
        let stepY = max(23, min(31, (size.height - 40) / 5))
        let stepX: CGFloat = 30
        return CGPoint(x: 18 + CGFloat(column) * stepX, y: 20 + CGFloat(row) * stepY)
    }

    private func rightPosition(for index: Int, in size: CGSize) -> CGPoint {
        let row = index % 6
        let column = index / 6
        let stepY = max(23, min(31, (size.height - 40) / 5))
        let stepX: CGFloat = 30
        return CGPoint(x: size.width - 18 - CGFloat(column) * stepX, y: size.height - 20 - CGFloat(row) * stepY)
    }

    private func riverTile(_ tile: MahjongTile) -> some View {
        TileView(tile: tile, isDiscard: true, displayStyle: .river)
            .rotationEffect(tile.id == reachDiscardID ? .degrees(90) : .zero)
            .transition(.scale(scale: 1.18).combined(with: .opacity))
    }
}
