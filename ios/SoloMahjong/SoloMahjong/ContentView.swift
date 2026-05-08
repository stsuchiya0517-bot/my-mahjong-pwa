import SwiftUI

struct ContentView: View {
    @StateObject private var game = MahjongGameViewModel()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.03, green: 0.17, blue: 0.11), Color(red: 0.02, green: 0.07, blue: 0.05)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                header
                tableArea
                handArea
                Spacer(minLength: 0)
                ActionBarView(game: game)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(game.roundTitle)
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("巡目 \(game.turnNumber) ・ 山 \(game.wall.count)枚")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("あなた")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                    Text("\(game.players.first?.score ?? 0)点")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.yellow)
                }
            }

            Text(game.message)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var tableArea: some View {
        VStack(spacing: 6) {
            if game.players.indices.contains(2) {
                OpponentView(player: game.players[2], isActive: game.currentPlayerIndex == 2)
            }

            HStack(spacing: 6) {
                if game.players.indices.contains(3) {
                    OpponentView(player: game.players[3], isActive: game.currentPlayerIndex == 3)
                }

                centerInfo
                    .frame(width: 96)

                if game.players.indices.contains(1) {
                    OpponentView(player: game.players[1], isActive: game.currentPlayerIndex == 1)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.08, green: 0.38, blue: 0.24), Color(red: 0.04, green: 0.22, blue: 0.14)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private var centerInfo: some View {
        VStack(spacing: 8) {
            Text(game.currentPlayerIndex == 0 ? "あなたの番" : "CPUの番")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(game.currentPlayerIndex == 0 ? .yellow : .white.opacity(0.8))

            VStack(spacing: 4) {
                Text("直前")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                if let lastDiscard = game.lastDiscard {
                    TileView(tile: lastDiscard, isSelected: true, isDiscard: true)
                } else {
                    Text("なし")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(height: 38)
                }
            }

            Button {
                withAnimation { game.startNewGame() }
            } label: {
                Text("新局")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.white)
        }
        .padding(8)
        .background(.black.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var handArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("あなたの手牌")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                    Text(game.selectedTile == nil ? "牌をタップして選択" : "下のボタンで捨てる")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                Text("\(game.players.first?.hand.count ?? 0)枚")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.yellow)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(game.players.first?.hand ?? []) { tile in
                        TileView(tile: tile, isSelected: game.selectedTileID == tile.id)
                            .onTapGesture {
                                game.select(tile: tile)
                            }
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 4)
            }
            .frame(height: 98)
            .background(.black.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text("あなたの捨て牌")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        ForEach(game.players.first?.discards ?? []) { tile in
                            TileView(tile: tile, isDiscard: true)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 2)
                }
                .frame(height: 48)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(game.currentPlayerIndex == 0 ? .yellow.opacity(0.75) : .white.opacity(0.12), lineWidth: game.currentPlayerIndex == 0 ? 2 : 1)
                )
        )
    }
}

#Preview {
    ContentView()
}
