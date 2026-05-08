import SwiftUI

struct ContentView: View {
    @StateObject private var game = MahjongGameViewModel()
    @State private var hasStarted = false
    @State private var showHowToPlay = false

    var body: some View {
        Group {
            if hasStarted {
                gameScreen
            } else {
                LocalStartMenuView(
                    onStart: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            game.startNewGame()
                            hasStarted = true
                        }
                    },
                    onHowToPlay: {
                        showHowToPlay = true
                    }
                )
            }
        }
        .sheet(isPresented: $showHowToPlay) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        howToCard(title: "基本ルール", text: "14枚の手牌を『4メンツ + 1雀頭』にすると和了です。不要牌を1枚ずつ切って形を整えていきます。")
                        howToCard(title: "このアプリの目的", text: "初心者でも、牌の種類・捨て方・対局の流れを感覚的に覚えられるようにすることを目的にしています。")
                        howToCard(title: "操作方法", text: "自分の手牌をタップして選択し、下のアクションボタンから捨て牌・ツモ・局の進行を行います。")
                        howToCard(title: "牌の見方", text: "萬子は『萬』、筒子は丸紋、索子は竹模様で表示しています。")
                    }
                    .padding()
                }
                .navigationTitle("遊び方")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private var gameScreen: some View {
        ZStack {
            tableBackground

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    header
                    topOpponent
                    middleArea
                    playerArea
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
        }
        .safeAreaInset(edge: .bottom) {
            ActionBarView(game: game)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
                .background(.clear)
        }
    }

    private var tableBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.22, blue: 0.13),
                    Color(red: 0.01, green: 0.10, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [.white.opacity(0.08), .clear],
                center: .center,
                startRadius: 10,
                endRadius: 500
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        hasStarted = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("メニュー")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.10))
                    .clipShape(Capsule())
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(game.roundTitle)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("山 \(game.wall.count)枚")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }

            Text(game.message)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var topOpponent: some View {
        Group {
            if game.players.indices.contains(2) {
                OpponentView(player: game.players[2], isActive: game.currentPlayerIndex == 2, layoutStyle: .top)
            }
        }
    }

    private var middleArea: some View {
        HStack(spacing: 10) {
            if game.players.indices.contains(3) {
                OpponentView(player: game.players[3], isActive: game.currentPlayerIndex == 3, layoutStyle: .side)
            }

            centerPanel

            if game.players.indices.contains(1) {
                OpponentView(player: game.players[1], isActive: game.currentPlayerIndex == 1, layoutStyle: .side)
            }
        }
    }

    private var centerPanel: some View {
        VStack(spacing: 12) {
            Text(game.currentPlayerIndex == 0 ? "あなたの番" : "CPUの番")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(game.currentPlayerIndex == 0 ? .yellow : .white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            VStack(spacing: 4) {
                Text("直前の打牌")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))

                if let lastDiscard = game.lastDiscard {
                    TileView(tile: lastDiscard, isSelected: true, isDiscard: true)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.white.opacity(0.08))
                        .frame(width: 44, height: 60)
                }
            }

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    game.startNewGame()
                }
            } label: {
                Text("新局")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(.gray.opacity(0.6))
        }
        .padding(10)
        .frame(width: 110)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.black.opacity(0.20))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.yellow.opacity(0.35), lineWidth: 1)
                )
        )
    }

    private var playerArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("あなたの手牌")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))

                    Text(game.selectedTile == nil ? "牌をタップして選択" : "下のアクションから打牌")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text("\(game.players.first?.score ?? 0)")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.yellow)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("あなたの捨て牌")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))

                discardPool(tiles: game.players.first?.discards ?? [], maxColumns: 6, compact: true)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(game.players.first?.hand ?? []) { tile in
                        TileView(tile: tile, isSelected: game.selectedTileID == tile.id)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.22, dampingFraction: 0.74)) {
                                    game.select(tile: tile)
                                }
                            }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 14)
            }
            .frame(height: 106)
            .background(.black.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(game.currentPlayerIndex == 0 ? .yellow.opacity(0.75) : .white.opacity(0.12), lineWidth: game.currentPlayerIndex == 0 ? 2 : 1)
                )
        )
    }

    private func discardPool(tiles: [MahjongTile], maxColumns: Int, compact: Bool) -> some View {
        let columns = Array(repeating: GridItem(.fixed(compact ? 34 : 40), spacing: 4), count: maxColumns)

        return LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
            ForEach(tiles) { tile in
                TileView(tile: tile, isDiscard: true, isCompact: compact)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.black.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .animation(.easeInOut(duration: 0.20), value: tiles.count)
    }

    private func howToCard(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .black, design: .rounded))
            Text(text)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct LocalStartMenuView: View {
    let onStart: () -> Void
    let onHowToPlay: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.02, green: 0.19, blue: 0.12), Color(red: 0.01, green: 0.06, blue: 0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 12) {
                    Text("ひとり麻雀")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("本物の卓っぽく覚えられる\niPhone向け麻雀練習アプリ")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    Button(action: onStart) {
                        Text("練習を始める")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Button(action: onHowToPlay) {
                        Text("遊び方を見る")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 10) {
                    menuPoint("牌の見た目を本物寄りに再現")
                    menuPoint("CPUの流れを見ながら練習できる")
                    menuPoint("初心者が卓で打てるレベルを目指す")
                }
                .padding(18)
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    private func menuPoint(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.yellow)
            Text(text)
                .foregroundStyle(.white)
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
    }
}

#Preview {
    ContentView()
}
