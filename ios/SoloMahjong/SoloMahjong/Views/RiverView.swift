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
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(rowsForLeft, id: \.self) { row in
                        HStack(spacing: 2) {
                            ForEach(row, id: \.id) { tile in
                                riverTile(tile).rotationEffect(.degrees(90))
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
            case .right:
                VStack(alignment: .trailing, spacing: 2) {
                    ForEach(rowsForRight, id: \.self) { row in
                        HStack(spacing: 2) {
                            ForEach(row, id: \.id) { tile in
                                riverTile(tile).rotationEffect(.degrees(-90))
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(3)
        .animation(.easeOut(duration: 0.18), value: tiles.count)
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.fixed(29), spacing: 2), count: 6)
    }

    private var rowsForLeft: [[MahjongTile]] {
        stride(from: 0, to: tiles.count, by: 3).map { start in
            Array(tiles[start..<min(start + 3, tiles.count)])
        }
    }

    private var rowsForRight: [[MahjongTile]] {
        stride(from: 0, to: tiles.count, by: 3).map { start in
            Array(tiles[start..<min(start + 3, tiles.count)])
        }.reversed()
    }

    private func riverTile(_ tile: MahjongTile) -> some View {
        TileView(tile: tile, isDiscard: true, displayStyle: .river)
            .rotationEffect(tile.id == reachDiscardID ? .degrees(90) : .zero)
            .transition(.scale(scale: 1.18).combined(with: .opacity))
    }
}
