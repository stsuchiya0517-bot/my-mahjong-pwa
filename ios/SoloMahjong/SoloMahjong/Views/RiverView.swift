import SwiftUI

struct RiverView: View {
    let tiles: [MahjongTile]
    let reachDiscardID: MahjongTile.ID?
    let seat: PlayerSeat

    var body: some View {
        GeometryReader { geo in
            let visibleTiles = Array(tiles.suffix(maxVisibleTiles))
            let layout = riverLayout(for: visibleTiles.count, in: geo.size)

            ZStack(alignment: .topLeading) {
                ForEach(Array(visibleTiles.enumerated()), id: \.element.id) { index, tile in
                    riverTile(tile)
                        .rotationEffect(rotation(for: tile))
                        .scaleEffect(layout.scale)
                        .position(position(for: index, layout: layout, in: geo.size))
                }

                if tiles.count > maxVisibleTiles {
                    overflowBadge(count: tiles.count - maxVisibleTiles)
                        .position(x: geo.size.width - 13, y: 13)
                }
            }
        }
        .padding(3)
        .clipped()
        .animation(.easeOut(duration: 0.18), value: tiles.count)
    }

    private var maxVisibleTiles: Int { 18 }
    private let tileWidth: CGFloat = 28
    private let tileHeight: CGFloat = 39
    private let spacing: CGFloat = 2

    private struct RiverLayout {
        let rows: Int
        let columns: Int
        let scale: CGFloat
        let usedSize: CGSize
    }

    private func riverLayout(for count: Int, in size: CGSize) -> RiverLayout {
        let rows: Int
        let columns: Int

        switch seat {
        case .bottom, .top:
            columns = min(6, max(1, count))
            rows = max(1, Int(ceil(Double(count) / 6.0)))
        case .left, .right:
            rows = min(6, max(1, count))
            columns = max(1, Int(ceil(Double(count) / 6.0)))
        }

        let baseW: CGFloat
        let baseH: CGFloat
        switch seat {
        case .bottom, .top:
            baseW = CGFloat(columns) * tileWidth + CGFloat(max(0, columns - 1)) * spacing
            baseH = CGFloat(rows) * tileHeight + CGFloat(max(0, rows - 1)) * spacing
        case .left, .right:
            baseW = CGFloat(columns) * tileHeight + CGFloat(max(0, columns - 1)) * spacing
            baseH = CGFloat(rows) * tileWidth + CGFloat(max(0, rows - 1)) * spacing
        }

        let scale = min(1, max(0.58, min((size.width - 4) / baseW, (size.height - 4) / baseH)))
        return RiverLayout(rows: rows, columns: columns, scale: scale, usedSize: CGSize(width: baseW * scale, height: baseH * scale))
    }

    private func position(for index: Int, layout: RiverLayout, in size: CGSize) -> CGPoint {
        let column: Int
        let row: Int

        switch seat {
        case .bottom, .top:
            column = index % 6
            row = index / 6
        case .left, .right:
            row = index % 6
            column = index / 6
        }

        let stepX: CGFloat
        let stepY: CGFloat
        let itemW: CGFloat
        let itemH: CGFloat

        switch seat {
        case .bottom, .top:
            itemW = tileWidth * layout.scale
            itemH = tileHeight * layout.scale
            stepX = (tileWidth + spacing) * layout.scale
            stepY = (tileHeight + spacing) * layout.scale
        case .left, .right:
            itemW = tileHeight * layout.scale
            itemH = tileWidth * layout.scale
            stepX = (tileHeight + spacing) * layout.scale
            stepY = (tileWidth + spacing) * layout.scale
        }

        let originX: CGFloat
        let originY: CGFloat
        switch seat {
        case .top:
            originX = (size.width - layout.usedSize.width) / 2
            originY = 2
        case .bottom:
            originX = (size.width - layout.usedSize.width) / 2
            originY = size.height - layout.usedSize.height - 2
        case .left:
            originX = 2
            originY = (size.height - layout.usedSize.height) / 2
        case .right:
            originX = size.width - layout.usedSize.width - 2
            originY = (size.height - layout.usedSize.height) / 2
        }

        return CGPoint(
            x: originX + itemW / 2 + CGFloat(column) * stepX,
            y: originY + itemH / 2 + CGFloat(row) * stepY
        )
    }

    private func rotation(for tile: MahjongTile) -> Angle {
        let reachRotation = tile.id == reachDiscardID ? 90.0 : 0.0
        switch seat {
        case .bottom:
            return .degrees(reachRotation)
        case .top:
            return .degrees(180 + reachRotation)
        case .left:
            return .degrees(90 + reachRotation)
        case .right:
            return .degrees(-90 + reachRotation)
        }
    }

    private func riverTile(_ tile: MahjongTile) -> some View {
        TileView(tile: tile, isDiscard: true, displayStyle: .river)
            .transition(.scale(scale: 1.18).combined(with: .opacity))
    }

    private func overflowBadge(count: Int) -> some View {
        Text("+\(count)")
            .font(.system(size: 8, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 24, height: 16)
            .background(.black.opacity(0.70))
            .clipShape(Capsule())
    }
}
