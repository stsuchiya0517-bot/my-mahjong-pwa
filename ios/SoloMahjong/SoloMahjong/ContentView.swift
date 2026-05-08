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
                StartScreen(
                    onStart: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            game.startNewGame()
                            hasStarted = true
                        }
                    },
                    onHowToPlay: { showHowToPlay = true }
                )
            }
        }
        .sheet(isPresented: $showHowToPlay) {
            HowToPlayView()
        }
        .sheet(item: $game.winningResult) { result in
            WinResultView(result: result) {
                game.winningResult = nil
                game.startNewGame()
            }
        }
    }

    private var gameScreen: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height

            ZStack {
                tableBackground

                if isLandscape {
                    landscapeLayout(in: geo)
                } else {
                    portraitLayout(in: geo)
                }
            }
        }
    }

    private var tableBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.015, green: 0.18, blue: 0.105),
                    Color(red: 0.01, green: 0.08, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.white.opacity(0.08), Color.clear],
                center: .center,
                startRadius: 10,
                endRadius: 520
            )
            .ignoresSafeArea()
        }
    }

    private func landscapeLayout(in geo: GeometryProxy) -> some View {
        HStack(spacing: 12) {
            leftStatusRail(compact: false)
                .frame(width: 124)

            landscapeTable
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            ActionBarView(game: game, isHorizontal: false)
                .frame(width: 118)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func portraitLayout(in geo: GeometryProxy) -> some View {
        VStack(spacing: 8) {
            portraitTopBar

            if game.players.indices.contains(2) {
                OpponentView(player: game.players[2], isActive: game.currentPlayerIndex == 2, layoutStyle: .top, riverRotation: .degrees(180))
                    .frame(height: 88)
            }

            HStack(spacing: 8) {
                if game.players.indices.contains(3) {
                    OpponentView(player: game.players[3], isActive: game.currentPlayerIndex == 3, layoutStyle: .side, riverRotation: .degrees(90))
                }

                centerMat(isCompact: true)
                    .frame(width: 96)

                if game.players.indices.contains(1) {
                    OpponentView(player: game.players[1], isActive: game.currentPlayerIndex == 1, layoutStyle: .side, riverRotation: .degrees(-90))
                }
            }
            .frame(height: 112)

            playerArea(isPortrait: true)

            ActionBarView(game: game, isHorizontal: true)
                .frame(height: 92)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
    }

    private var landscapeTable: some View {
        VStack(spacing: 10) {
            if game.players.indices.contains(2) {
                OpponentView(player: game.players[2], isActive: game.currentPlayerIndex == 2, layoutStyle: .top, riverRotation: .degrees(180))
                    .frame(height: 88)
            }

            HStack(spacing: 10) {
                if game.players.indices.contains(3) {
                    OpponentView(player: game.players[3], isActive: game.currentPlayerIndex == 3, layoutStyle: .side, riverRotation: .degrees(90))
                }

                centerMat(isCompact: false)
                    .frame(width: 108)

                if game.players.indices.contains(1) {
                    OpponentView(player: game.players[1], isActive: game.currentPlayerIndex == 1, layoutStyle: .side, riverRotation: .degrees(-90))
                }
            }
            .frame(height: 120)

            playerArea(isPortrait: false)
                .frame(maxHeight: .infinity)
        }
    }

    private func leftStatusRail(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) { hasStarted = false }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("メニュー")
                }
                .font(.system(size: compact ? 12 : 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.white.opacity(0.10))
                .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(game.roundTitle)
                    .font(.system(size: compact ? 22 : 26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("山 \(game.wall.count)枚")
                    .font(.system(size: compact ? 12 : 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                Text("巡目 \(game.turnNumber)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
            }

            Text(game.message)
                .font(.system(size: compact ? 11 : 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(compact ? 3 : 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text("直前の打牌")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                HStack(spacing: 8) {
                    if let last = game.lastDiscard {
                        TileView(tile: last, isSelected: true, isDiscard: true, displayStyle: .river)
                    } else {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(.black.opacity(0.14))
                            .frame(width: 28, height: 40)
                    }
                    Text(lastDiscardOwnerText)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(2)
                }
            }
            .padding(10)
            .background(.black.opacity(0.13))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Spacer(minLength: 0)
        }
    }

    private var portraitTopBar: some View {
        HStack(alignment: .top, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) { hasStarted = false }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("メニュー")
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.white.opacity(0.10))
                .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(game.roundTitle)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("山 \(game.wall.count)枚 / 巡目 \(game.turnNumber)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.70))
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 2) {
                Text("直前")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                if let last = game.lastDiscard {
                    TileView(tile: last, isSelected: true, isDiscard: true, displayStyle: .river)
                }
            }
        }
        .overlay(alignment: .bottomLeading) {
            Text(game.message)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .padding(.top, 54)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(height: 98)
    }

    private var lastDiscardOwnerText: String {
        guard let index = game.lastDiscardPlayerIndex, game.players.indices.contains(index) else { return "まだありません" }
        return game.players[index].name
    }

    private func centerMat(isCompact: Bool) -> some View {
        AutoTableCenterView(
            roundTitle: game.roundTitle,
            turnNumber: game.turnNumber,
            players: game.players,
            lastDiscard: game.lastDiscard,
            isCompact: isCompact
        ) {
            withAnimation(.easeInOut(duration: 0.22)) { game.startNewGame() }
        }
    }

    private func playerArea(isPortrait: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("あなたの河")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                    RiverGrid(tiles: game.players.first?.discards ?? [], rotation: .degrees(0), columns: isPortrait ? 7 : 10, tileSize: .small)
                    if let melds = game.players.first?.melds, !melds.isEmpty {
                        MeldsView(melds: melds, rotation: .degrees(0))
                    }
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("あなた")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                    Text("\(game.players.first?.score ?? 0)")
                        .font(.system(size: isPortrait ? 18 : 20, weight: .black, design: .rounded))
                        .foregroundStyle(.yellow)
                }
            }

            Text(game.selectedTile == nil ? "牌をタップして選択" : (isPortrait ? "下の『捨てる』で打牌" : "右の『捨てる』で打牌"))
                .font(.system(size: isPortrait ? 13 : 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            HStack(alignment: .bottom, spacing: isPortrait ? 2 : 4) {
                ForEach(game.players.first?.hand ?? []) { tile in
                    TileView(tile: tile, isSelected: game.selectedTileID == tile.id, displayStyle: isPortrait ? .handCompact : .hand)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.22, dampingFraction: 0.74)) {
                                game.select(tile: tile)
                            }
                        }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, isPortrait ? 6 : 8)
            .padding(.horizontal, isPortrait ? 4 : 6)
            .frame(height: isPortrait ? 58 : 68, alignment: .bottomLeading)
            .background(.black.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(game.currentPlayerIndex == 0 ? .yellow.opacity(0.75) : .white.opacity(0.12), lineWidth: game.currentPlayerIndex == 0 ? 2 : 1)
                )
        )
    }
}


struct AutoTableCenterView: View {
    let roundTitle: String
    let turnNumber: Int
    let players: [MahjongPlayer]
    let lastDiscard: MahjongTile?
    let isCompact: Bool
    let onNewRound: () -> Void

    var body: some View {
        VStack(spacing: isCompact ? 5 : 7) {
            Text(currentTurnText)
                .font(.system(size: isCompact ? 11 : 13, weight: .black, design: .rounded))
                .foregroundStyle(.yellow)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            ZStack {
                tableBase
                scoreRing
                centerScreen
                directionalLabels
            }
            .frame(width: isCompact ? 86 : 102, height: isCompact ? 86 : 102)

            Button(action: onNewRound) {
                Text("新局")
                    .font(.system(size: isCompact ? 11 : 12, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: isCompact ? 26 : 30)
            }
            .buttonStyle(.borderedProminent)
            .tint(.gray.opacity(0.60))
        }
        .padding(isCompact ? 7 : 9)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.yellow.opacity(0.35), lineWidth: 1)
                )
        )
    }

    private var currentTurnText: String {
        guard !players.isEmpty else { return "対局中" }
        return "巡目 \(turnNumber)"
    }

    private var tableBase: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.18, green: 0.19, blue: 0.19),
                        Color(red: 0.06, green: 0.065, blue: 0.07)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
    }

    private var centerScreen: some View {
        VStack(spacing: 2) {
            Text(roundTitle.replacingOccurrences(of: "局", with: ""))
                .font(.system(size: isCompact ? 12 : 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("49")
                .font(.system(size: isCompact ? 23 : 28, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 1.0, green: 0.20, blue: 0.24))

            Text("27000")
                .font(.system(size: isCompact ? 10 : 11, weight: .black, design: .monospaced))
                .foregroundStyle(Color(red: 0.42, green: 1.0, blue: 0.32))
        }
        .frame(width: isCompact ? 48 : 58, height: isCompact ? 54 : 64)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
    }

    private var scoreRing: some View {
        ZStack {
            miniScore(text: players.indices.contains(2) ? "\(players[2].score)" : "25000")
                .offset(y: isCompact ? -34 : -40)
                .rotationEffect(.degrees(180))
            miniScore(text: players.indices.contains(0) ? "\(players[0].score)" : "25000")
                .offset(y: isCompact ? 34 : 40)
            miniScore(text: players.indices.contains(3) ? "\(players[3].score)" : "25000")
                .offset(x: isCompact ? -35 : -42)
                .rotationEffect(.degrees(90))
            miniScore(text: players.indices.contains(1) ? "\(players[1].score)" : "25000")
                .offset(x: isCompact ? 35 : 42)
                .rotationEffect(.degrees(-90))
        }
    }

    private func miniScore(text: String) -> some View {
        Text(text)
            .font(.system(size: isCompact ? 7 : 8, weight: .black, design: .monospaced))
            .foregroundStyle(Color(red: 0.46, green: 1.0, blue: 0.32))
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .background(.black.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private var directionalLabels: some View {
        ZStack {
            direction("北").offset(y: isCompact ? -22 : -27)
            direction("南").offset(y: isCompact ? 22 : 27)
            direction("西").offset(x: isCompact ? -23 : -28)
            direction("東").offset(x: isCompact ? 23 : 28)
        }
    }

    private func direction(_ text: String) -> some View {
        Text(text)
            .font(.system(size: isCompact ? 10 : 12, weight: .black, design: .serif))
            .foregroundStyle(text == "東" ? .red : .yellow.opacity(0.88))
            .shadow(color: .black.opacity(0.45), radius: 1, x: 0, y: 1)
    }
}

struct RiverGrid: View {
    enum TileSize { case small, regular }
    let tiles: [MahjongTile]
    let rotation: Angle
    let columns: Int
    let tileSize: TileSize

    var body: some View {
        let columnWidth: CGFloat = tileSize == .small ? 27 : 31
        let gridColumns = Array(repeating: GridItem(.fixed(columnWidth), spacing: 3), count: columns)
        LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 3) {
            ForEach(tiles) { tile in
                TileView(tile: tile, isDiscard: true, isCompact: true, displayStyle: .river)
                    .rotationEffect(rotation)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .animation(.easeInOut(duration: 0.20), value: tiles.count)
    }
}

struct WinResultView: View {
    let result: WinResult
    let onNext: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.06, green: 0.16, blue: 0.10), Color.black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(result.title)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.yellow)

                Text("\(result.winnerName) / \(result.method)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))

                VStack(alignment: .leading, spacing: 10) {
                    resultRow("役", result.yaku.joined(separator: "・"))
                    resultRow("翻", result.hanText)
                    resultRow("符", result.fuText)
                    resultRow("点数", result.scoreText)
                }
                .padding(18)
                .frame(maxWidth: 520)
                .background(.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                Text(result.explanation)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.70))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)

                Button(action: onNext) {
                    Text("次の局へ")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .frame(width: 260, height: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding()
        }
    }

    private func resultRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
                .frame(width: 42, alignment: .leading)
            Text(value)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
        }
    }
}

struct HowToPlayView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    howToCard(title: "目的", text: "14枚で4メンツ+1雀頭を作ります。牌を選んで河に捨てる流れを、縦横どちらの画面でも練習できます。")
                    howToCard(title: "操作", text: "牌をタップして選択し、縦画面では下の、横画面では右の操作バーから『捨てる』を押します。和了形なら『ツモ和了』が押せます。")
                    howToCard(title: "河", text: "各プレイヤーの捨て牌は、実際の麻雀卓に近いイメージでプレイヤーごとの河に並びます。")
                    howToCard(title: "役満", text: "国士無双・四暗刻・大三元・四喜和・字一色・清老頭・緑一色・九蓮宝燈などを練習用に判定します。")
                }
                .padding()
            }
            .navigationTitle("遊び方")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func howToCard(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 17, weight: .black, design: .rounded))
            Text(text).font(.system(size: 14, weight: .regular, design: .rounded)).foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct StartScreen: View {
    let onStart: () -> Void
    let onHowToPlay: () -> Void

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height

            ZStack {
                LinearGradient(colors: [Color(red: 0.02, green: 0.19, blue: 0.12), Color(red: 0.01, green: 0.06, blue: 0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                Group {
                    if isLandscape {
                        HStack(spacing: 34) {
                            introBlock
                            menuBlock
                        }
                    } else {
                        VStack(spacing: 26) {
                            introBlock
                            menuBlock
                        }
                    }
                }
                .padding(28)
            }
        }
    }

    private var introBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ひとり麻雀")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("縦画面でも横画面でも\n本物の卓に近い流れを覚える麻雀練習アプリ")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.82))
            VStack(alignment: .leading, spacing: 8) {
                menuPoint("縦横どちらでも遊べる対局画面")
                menuPoint("手牌が見切れにくい調整済み")
                menuPoint("国士無双などの役満判定入り")
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: 430, alignment: .leading)
    }

    private var menuBlock: some View {
        VStack(spacing: 14) {
            Button(action: onStart) {
                Text("練習を始める")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .frame(width: 260, height: 62)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

            Button(action: onHowToPlay) {
                Text("遊び方を見る")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .frame(width: 260, height: 62)
            }
            .buttonStyle(.bordered)
            .tint(.white)
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
