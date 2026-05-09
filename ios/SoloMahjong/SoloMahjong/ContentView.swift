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
                    onStart: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            game.startMatch()
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
    }
}

private struct StartScreen: View {
    let onStart: () -> Void
    let onHowToPlay: () -> Void

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height

            ZStack {
                FeltBackground()

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
            Text("SoloMahjong")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("卓を囲む感覚で打てる\nひとり麻雀練習アプリ")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.82))
            VStack(alignment: .leading, spacing: 8) {
                menuPoint("縦横対応の本格卓上レイアウト")
                menuPoint("ダブルタップ打牌とCPU思考演出")
                menuPoint("東場から南場までスコア継続")
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: 430, alignment: .leading)
    }

    private var menuBlock: some View {
        VStack(spacing: 14) {
            Button(action: onStart) {
                Text("対局を始める")
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
