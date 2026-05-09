import SwiftUI

struct PlayerHandView: View {
    @ObservedObject var game: MahjongGameViewModel
    let tileStyle: TileDisplayStyle

    var body: some View {
        GeometryReader { geo in
            let hand = game.players[safe: 0]?.hand ?? []
            let maxTileWidth = tileStyle == .hand ? 34.0 : 24.0
            let width = min(maxTileWidth, max(19, (geo.size.width - 12) / CGFloat(max(hand.count, 1))))
            let height = tileStyle == .hand ? 50.0 : 38.0
            let scale = width / maxTileWidth

            HStack(alignment: .bottom, spacing: 1) {
                ForEach(hand) { tile in
                    TileView(tile: tile, isSelected: game.selectedTileID == tile.id, displayStyle: tileStyle)
                        .scaleEffect(scale, anchor: .bottom)
                        .frame(width: width, height: height + 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            game.handleHandTap(tile)
                        }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [Color.black.opacity(0.46), Color.black.opacity(0.16)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    Rectangle()
                        .fill(Color(red: 0.11, green: 0.31, blue: 0.14).opacity(0.24))
                        .blur(radius: 10)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(game.currentPlayerIndex == 0 ? Color.yellow.opacity(0.72) : Color.white.opacity(0.10), lineWidth: 1.4)
            )
            .shadow(color: Color.yellow.opacity(game.currentPlayerIndex == 0 ? 0.18 : 0), radius: 12, x: 0, y: 0)
        }
    }
}
