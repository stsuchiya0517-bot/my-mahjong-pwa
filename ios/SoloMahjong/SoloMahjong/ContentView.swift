import SwiftUI

struct ContentView: View {
    @StateObject private var game = MahjongGameViewModel()
    @State private var hasStarted = false
    @State private var showHowToPlay = false

    var body: some View {
        Group {
            if hasStarted {
                GameBoardView(
                    game: game,
                    onMenu: {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            hasStarted = false
                        }
                    }
                )
            } else {
                StartScreen(
                    onStart: { mode in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            game.startMatch(mode: mode)
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
                game.advanceToNextRound()
            }
        }
        .sheet(item: $game.roundNotice) { notice in
            RoundNoticeView(notice: notice) {
                game.roundNotice = nil
                game.isBusy = false
                game.advanceToNextRound()
            }
        }
        .sheet(item: $game.matchResult) { result in
            MatchResultView(result: result) {
                game.matchResult = nil
                hasStarted = false
            }
        }
    }
}

private struct MatchResultView: View {
    let result: MatchResult
    let onClose: () -> Void

    var body: some View {
        ZStack {
            FeltBackground()

            VStack(spacing: 18) {
                Text("\(result.modeName) 終了")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.yellow)

                VStack(spacing: 9) {
                    ForEach(result.standings) { standing in
                        HStack(spacing: 12) {
                            Text("\(standing.rank)位")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(standing.rank == 1 ? .yellow : .white.opacity(0.72))
                                .frame(width: 46, alignment: .leading)
                            Text(standing.playerName)
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(standing.score)点")
                                .font(.system(size: 17, weight: .black, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                        .padding(12)
                        .background(standing.rank == 1 ? Color.yellow.opacity(0.18) : Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .frame(maxWidth: 440)

                Text("最終持ち点で順位を決定しました。実戦ではここにウマ・オカを加えるルールもあります。")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)

                Button(action: onClose) {
                    Text("ホームへ")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .frame(width: 260, height: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding()
        }
    }
}

private struct RoundNoticeView: View {
    let notice: RoundNotice
    let onNext: () -> Void

    var body: some View {
        ZStack {
            FeltBackground()

            VStack(spacing: 18) {
                Text(notice.title)
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.yellow)

                Text(notice.body)
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(notice.detail)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
                    .padding(16)
                    .background(.black.opacity(0.30))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button(action: onNext) {
                    Text("次局へ")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .frame(width: 260, height: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding()
        }
    }
}

private struct StartScreen: View {
    let onStart: (MatchMode) -> Void
    let onHowToPlay: () -> Void
    @State private var selectedMode: MatchMode = .eastSouth

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let safe = geo.safeAreaInsets
            let contentWidth = min(geo.size.width - 44, 430)

            ZStack {
                FeltBackground()

                ScrollView(.vertical, showsIndicators: false) {
                    if isLandscape {
                        HStack(spacing: 34) {
                            introBlock(width: min(430, (geo.size.width - 120) * 0.56), compact: true)
                            menuBlock(width: 280, mode: selectedMode)
                        }
                        .frame(maxWidth: .infinity, minHeight: geo.size.height - safe.top - safe.bottom, alignment: .center)
                    } else {
                        VStack(spacing: 22) {
                            introBlock(width: contentWidth, compact: geo.size.height < 760)
                            menuBlock(width: contentWidth, mode: selectedMode)
                        }
                        .frame(maxWidth: .infinity, minHeight: geo.size.height - safe.top - safe.bottom, alignment: .center)
                    }
                }
                .safeAreaPadding(.top, 20)
                .safeAreaPadding(.bottom, 26)
            }
        }
    }

    private func introBlock(width: CGFloat, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 14) {
            Image("StartHeroMahjong")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: width)
                .frame(height: compact ? 142 : 176)
                .background(.black.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.38), radius: 18, x: 0, y: 10)

            Text("SoloMahjong")
                .font(.system(size: compact ? 34 : 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Text("卓を囲む感覚で打てる\nひとり麻雀練習アプリ")
                .font(.system(size: compact ? 14 : 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.82))
            VStack(alignment: .leading, spacing: 8) {
                menuPoint("縦横対応の本格卓上レイアウト")
                menuPoint("ダブルタップ打牌とCPU思考演出")
                menuPoint("東場から南場までスコア継続")
            }
            .padding(.top, compact ? 3 : 8)
        }
        .frame(width: width, alignment: .leading)
    }

    private func menuBlock(width: CGFloat, mode: MatchMode) -> some View {
        VStack(spacing: 13) {
            Picker("試合形式", selection: $selectedMode) {
                ForEach(MatchMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .tint(.green)

            Button {
                onStart(mode)
            } label: {
                Text("対局を始める")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

            Button(action: onHowToPlay) {
                Text("遊び方を見る")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
            }
            .buttonStyle(.bordered)
            .tint(.white)
        }
        .frame(width: min(width, 340))
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

struct HowToPlayView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    howToCard(title: "操作", text: "手牌は1回タップで選択、同じ牌を素早く2回タップすると即打牌します。操作バーの捨てるでも打牌できます。")
                    howToCard(title: "卓", text: "各プレイヤーの河は座席方向に合わせて中央へ伸びます。左右CPUの河は実卓に近い縦方向の並びです。")
                    howToCard(title: "試合", text: "東1局から南4局まで、親・本場・リーチ棒・点数を継続して進行します。流局は簡易処理です。")
                    howToCard(title: "役", text: "通常和了に加えて、国士無双・四暗刻・大三元・四喜和・字一色・清老頭・緑一色・九蓮宝燈などを判定します。")
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

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
