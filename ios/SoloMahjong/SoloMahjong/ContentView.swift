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
                        game.startNewGame()
                        hasStarted = true
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
                        howToCard(title: "基本ルール", text: "14枚の手牌を『4メンツ + 1雀頭』にすると和了です。まずは、いらない牌を1枚ずつ捨てながら形を整えます。")
                        howToCard(title: "このアプリの目的", text: "初心者でも、牌の種類・捨て方・対局の流れを感覚的に覚えられるようにすることを目的にしています。")
                        howToCard(title: "操作方法", text: "下の自分の手牌をタップして選択し、画面下の『捨てる』ボタンで打牌します。")
                        howToCard(title: "牌の見方", text: "萬子は『萬』、筒子は丸い模様、索子は竹の模様で表示しています。")
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
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.20, blue: 0.12),
                    Color(red: 0.01, green: 0.08, blue: 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    header
                    topOpponent
                    middleArea
                    playerArea
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 110)
            }
        }
        .safeAreaInset(edge: .bottom) {
            ActionBarView(game: game)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
                .background(.clear)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    hasStarted = false
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("メニュー")
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.12))
                    .clipShape(Capsule())
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(game.roundTitle)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("山 \(game.wall.count)枚")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                }
            }

            Text(game.message)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var topOpponent: some View {
        Group {
            if game.players.indices.contains(2) {
                OpponentView(
                    player: game.players[2],
                    isActive: game.currentPlayerIndex == 2,
                    layoutStyle: .top
                )
            }
        }
    }

    private var middleArea: some View {
        HStack(spacing: 8) {
            if game.players.indices.contains(3) {
                OpponentView(
                    player: game.players[3],
                    isActive: game.currentPlayerIndex == 3,
                    layoutStyle: .side
                )
            }

            centerPanel

            if game.players.indices.contains(1) {
                OpponentView(
                    player: game.players[1],
                    isActive: game.currentPlayerIndex == 1,
                    layoutStyle: .side
                )
            }
        }
    }

    private var centerPanel: some View {
        VStack(spacing: 9) {
            Text(game.currentPlayerIndex == 0 ? "あなたの番" : "CPUの番")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(game.currentPlayerIndex == 0 ? .yellow : .white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            VStack(spacing: 4) {
                Text("直前")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                if let lastDiscard = game.lastDiscard {
                    TileView(tile: lastDiscard, isSelected: true, isDiscard: true)
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white.opacity(0.08))
                        .frame(width: 42, height: 56)
                        .overlay(Text("なし").font(.system(size: 11, weight: .bold)).foregroundStyle(.white.opacity(0.55)))
                }
            }

            Button {
                game.startNewGame()
            } label: {
                Text("新局")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
            }
            .buttonStyle(.borderedProminent)
            .tint(.gray.opacity(0.55))
        }
        .padding(8)
        .frame(width: 92)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.black.opacity(0.22))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.yellow.opacity(0.35), lineWidth: 1)
                )
        )
    }

    private var playerArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("あなたの手牌")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))

                    Text(game.selectedTile == nil ? "牌をタップして選択" : "下の『捨てる』で打牌")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text("\(game.players.first?.score ?? 0)")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.yellow)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(game.players.first?.hand ?? []) { tile in
                        TileView(tile: tile, isSelected: game.selectedTileID == tile.id)
                            .onTapGesture {
                                game.select(tile: tile)
                            }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 14)
            }
            .frame(height: 100)
            .background(.black.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text("あなたの捨て牌")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(game.players.first?.discards ?? []) { tile in
                            TileView(tile: tile, isDiscard: true)
                        }
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 2)
                }
                .frame(height: 52)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(game.currentPlayerIndex == 0 ? .yellow.opacity(0.7) : .white.opacity(0.1), lineWidth: 1.5)
                )
        )
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
                colors: [
                    Color(red: 0.02, green: 0.19, blue: 0.12),
                    Color(red: 0.01, green: 0.06, blue: 0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 12) {
                    Text("ひとり麻雀")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("iPhoneで遊びやすい\n麻雀練習アプリ")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    Button(action: onStart) {
                        Text("練習を始める")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Button(action: onHowToPlay) {
                        Text("遊び方を見る")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 8) {
                    menuPoint("牌をタップして捨てる")
                    menuPoint("CPUの動きを見ながら流れを覚える")
                    menuPoint("初心者向けの練習用")
                }
                .padding(16)
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
