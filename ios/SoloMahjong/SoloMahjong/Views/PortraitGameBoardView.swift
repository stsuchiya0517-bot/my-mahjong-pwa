import SwiftUI

struct PortraitGameBoardView: View {
    @ObservedObject var game: MahjongGameViewModel
    let onMenu: () -> Void

    var body: some View {
        GeometryReader { geo in
            let safe = geo.safeAreaInsets
            let w = geo.size.width
            let h = geo.size.height
            let center = CGPoint(x: w / 2, y: max(258, min(h * 0.43, h - 330)))
            let centerSize = min(w * 0.34, 146)
            let sideX = min(max(w * 0.105, 33), 45)
            let tableHalf = min(w * 0.34, 150)
            let handY = h - safe.bottom - 124

            ZStack {
                GameHUDView(game: game, onMenu: onMenu, compact: true)
                    .frame(width: w - 20)
                    .position(x: w / 2, y: safe.top + 34)

                WallTileBackView(count: game.players[safe: 2]?.hand.count ?? 13, orientation: .horizontal)
                    .frame(width: min(w * 0.70, 286), height: 28)
                    .position(x: w / 2, y: safe.top + 100)

                WallTileBackView(count: game.players[safe: 3]?.hand.count ?? 13, orientation: .vertical)
                    .frame(width: 30, height: min(h * 0.37, 295))
                    .position(x: sideX, y: center.y + 12)

                WallTileBackView(count: game.players[safe: 1]?.hand.count ?? 13, orientation: .vertical)
                    .frame(width: 30, height: min(h * 0.37, 295))
                    .position(x: w - sideX, y: center.y + 12)

                AutoTableCenterView(game: game)
                    .frame(width: centerSize, height: centerSize)
                    .position(center)

                RiverView(tiles: game.players[safe: 2]?.discards ?? [], reachDiscardID: game.players[safe: 2]?.reachDiscardID, seat: .top)
                    .frame(width: min(w * 0.50, 210), height: 74)
                    .position(x: center.x, y: center.y - tableHalf)

                RiverView(tiles: game.players[safe: 0]?.discards ?? [], reachDiscardID: game.players[safe: 0]?.reachDiscardID, seat: .bottom)
                    .frame(width: min(w * 0.50, 210), height: 74)
                    .position(x: center.x, y: center.y + tableHalf)

                RiverView(tiles: game.players[safe: 3]?.discards ?? [], reachDiscardID: game.players[safe: 3]?.reachDiscardID, seat: .left)
                    .frame(width: 88, height: min(h * 0.23, 162))
                    .position(x: center.x - min(w * 0.30, 135), y: center.y)

                RiverView(tiles: game.players[safe: 1]?.discards ?? [], reachDiscardID: game.players[safe: 1]?.reachDiscardID, seat: .right)
                    .frame(width: 88, height: min(h * 0.23, 162))
                    .position(x: center.x + min(w * 0.30, 135), y: center.y)

                MeldAreaView(melds: game.players[safe: 0]?.melds ?? [], seat: .bottom)
                    .frame(width: min(w * 0.70, 300), height: 36)
                    .position(x: center.x, y: center.y + tableHalf + 50)

                MeldAreaView(melds: game.players[safe: 3]?.melds ?? [], seat: .left)
                    .frame(width: 92, height: 48)
                    .position(x: sideX + 42, y: center.y + 158)

                MeldAreaView(melds: game.players[safe: 1]?.melds ?? [], seat: .right)
                    .frame(width: 92, height: 48)
                    .position(x: w - sideX - 42, y: center.y - 158)

                PlayerHandView(game: game, tileStyle: .handCompact)
                    .frame(width: w - 14, height: 78)
                    .position(x: w / 2, y: handY)

                assistStrip(width: w)
                    .position(x: w / 2, y: handY - 54)

                ActionBarView(game: game, isHorizontal: true)
                    .frame(width: w - 18, height: 72)
                    .position(x: w / 2, y: h - safe.bottom - 38)
            }
            .padding(.top, 2)
            .onAppear { game.drawForUserIfNeeded() }
        }
    }

    private func assistStrip(width: CGFloat) -> some View {
        HStack {
            Button {} label: {
                Label("アシスト", systemImage: "sparkle.magnifyingglass")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.97, green: 0.88, blue: 0.56))
                    .frame(width: 104, height: 34)
                    .background(.black.opacity(0.68))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Spacer()

            Text("\(game.shantenText)")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 74, height: 34)
                .background(.black.opacity(0.68))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .frame(width: width - 24)
    }
}
