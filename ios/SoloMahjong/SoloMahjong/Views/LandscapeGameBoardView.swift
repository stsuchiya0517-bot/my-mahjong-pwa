import SwiftUI

struct LandscapeGameBoardView: View {
    @ObservedObject var game: MahjongGameViewModel
    let onMenu: () -> Void

    var body: some View {
        GeometryReader { geo in
            let safe = geo.safeAreaInsets
            let w = geo.size.width
            let h = geo.size.height
            let leftRail: CGFloat = 132 + safe.leading
            let rightRail: CGFloat = 124 + safe.trailing
            let center = CGPoint(x: (leftRail + (w - rightRail)) / 2, y: h * 0.47)
            let boardWidth = w - leftRail - rightRail
            let spread = min(boardWidth * 0.31, 188)

            ZStack {
                GameHUDView(game: game, onMenu: onMenu, compact: false)
                    .frame(width: 118)
                    .position(x: safe.leading + 66, y: h / 2)

                ActionBarView(game: game, isHorizontal: false)
                    .frame(width: 104, height: h - safe.top - safe.bottom - 22)
                    .position(x: w - safe.trailing - 60, y: h / 2)

                WallTileBackView(count: game.players[safe: 2]?.hand.count ?? 13, orientation: .horizontal)
                    .frame(width: min(boardWidth * 0.48, 340), height: 28)
                    .position(x: center.x, y: safe.top + 32)

                WallTileBackView(count: game.players[safe: 3]?.hand.count ?? 13, orientation: .vertical)
                    .frame(width: 30, height: min(h * 0.55, 330))
                    .position(x: leftRail + 22, y: center.y)

                WallTileBackView(count: game.players[safe: 1]?.hand.count ?? 13, orientation: .vertical)
                    .frame(width: 30, height: min(h * 0.55, 330))
                    .position(x: w - rightRail - 22, y: center.y)

                AutoTableCenterView(game: game)
                    .frame(width: min(h * 0.34, 150), height: min(h * 0.34, 150))
                    .position(center)

                RiverView(tiles: game.players[safe: 2]?.discards ?? [], reachDiscardID: game.players[safe: 2]?.reachDiscardID, seat: .top)
                    .frame(width: 220, height: 70)
                    .position(x: center.x, y: center.y - 124)

                RiverView(tiles: game.players[safe: 0]?.discards ?? [], reachDiscardID: game.players[safe: 0]?.reachDiscardID, seat: .bottom)
                    .frame(width: 220, height: 70)
                    .position(x: center.x, y: center.y + 118)

                RiverView(tiles: game.players[safe: 3]?.discards ?? [], reachDiscardID: game.players[safe: 3]?.reachDiscardID, seat: .left)
                    .frame(width: 90, height: 170)
                    .position(x: center.x - spread, y: center.y)

                RiverView(tiles: game.players[safe: 1]?.discards ?? [], reachDiscardID: game.players[safe: 1]?.reachDiscardID, seat: .right)
                    .frame(width: 90, height: 170)
                    .position(x: center.x + spread, y: center.y)

                MeldAreaView(melds: game.players[safe: 0]?.melds ?? [], seat: .bottom)
                    .frame(width: 260, height: 34)
                    .position(x: center.x, y: h - safe.bottom - 84)

                PlayerHandView(game: game, tileStyle: .hand)
                    .frame(width: min(boardWidth - 24, 520), height: 60)
                    .position(x: center.x, y: h - safe.bottom - 30)
            }
            .onAppear { game.drawForUserIfNeeded() }
        }
    }
}
