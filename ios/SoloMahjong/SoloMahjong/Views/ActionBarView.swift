import SwiftUI

struct ActionBarView: View {
    @ObservedObject var game: MahjongGameViewModel
    var isHorizontal: Bool = false
    @State private var helpTerm: ActionHelpTerm?

    var body: some View {
        Group {
            if isHorizontal {
                horizontalBody
            } else {
                verticalBody
            }
        }
        .padding(8)
        .background(
            ZStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.78), Color.black.opacity(0.52)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Rectangle().fill(.white.opacity(0.035))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 6)
        .sheet(item: $helpTerm) { term in
            NavigationStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text(term.reading)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(term.word)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                    Text(term.meaning)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Spacer()
                }
                .padding()
                .navigationTitle("用語")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium])
        }
    }

    private var verticalBody: some View {
        VStack(spacing: 8) {
            if let pending = game.pendingUserCall {
                callPanel(pending, compact: false)
            } else if let selected = game.selectedTile {
                selectedPanelVertical(selected)
            } else {
                normalPanelVertical
            }
        }
    }

    private var horizontalBody: some View {
        HStack(spacing: 8) {
            if let pending = game.pendingUserCall {
                callPanel(pending, compact: true)
            } else if let selected = game.selectedTile {
                selectedPanelHorizontal(selected)
            } else {
                normalPanelHorizontal
            }
        }
    }

    private func selectedPanelVertical(_ selected: MahjongTile) -> some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                Text("選択中")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                TileView(tile: selected, isSelected: true, displayStyle: .hand)
                    .frame(height: 52)
            }

            discardButton(height: 54)
            cancelButton(height: 40)
        }
    }

    private func selectedPanelHorizontal(_ selected: MahjongTile) -> some View {
        HStack(spacing: 8) {
            VStack(spacing: 3) {
                Text("選択中")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                TileView(tile: selected, isSelected: true, displayStyle: .handCompact)
            }
            .frame(width: 64)

            discardButton(height: 54)
            cancelButton(height: 54)
        }
    }

    private var normalPanelVertical: some View {
        VStack(spacing: 8) {
            tsumoButton(height: 54)
            reachButton(height: 46)
            kanButton(height: 46)
            resetButton(height: 54)
            Text(game.canTsumoWin ? "和了できます" : "牌を選んで打牌")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private var normalPanelHorizontal: some View {
        HStack(spacing: 8) {
            tsumoButton(height: 54)
            reachButton(height: 54)
            kanButton(height: 54)
            resetButton(height: 54)
        }
    }

    private func callPanel(_ pending: PendingUserCall, compact: Bool) -> some View {
        let stack = compact ? AnyLayout(HStackLayout(spacing: 7)) : AnyLayout(VStackLayout(spacing: 7))
        return stack {
            TileView(tile: pending.tile, isDiscard: true, displayStyle: .river)
                .frame(width: compact ? 38 : 44, height: compact ? 44 : 48)

            ForEach(pending.actions) { action in
                callButton(action, height: compact ? 54 : 44)
            }

            Button {
                game.skipUserCall()
            } label: {
                Text("スキップ")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: compact ? 54 : 40)
            }
            .buttonStyle(.plain)
            .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(.white.opacity(0.16)))
        }
    }

    private func callButton(_ action: UserCallAction, height: CGFloat) -> some View {
        Button {
            game.performUserCall(action)
        } label: {
            VStack(spacing: 0) {
                Text(reading(for: action.rawValue))
                    .font(.system(size: 7, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.70))
                Text(action.rawValue)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.35).onEnded { _ in
            helpTerm = ActionHelpTerm.term(for: action.rawValue)
        })
        .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Color(red: 0.82, green: 0.28, blue: 0.10)))
    }

    private func discardButton(height: CGFloat) -> some View {
        Button {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
                game.discardSelectedTile()
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("捨てる")
                    .font(.system(size: 15, weight: .black, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(game.canDiscard ? Color(red: 0.08, green: 0.52, blue: 0.22) : Color.gray.opacity(0.45))
                .overlay(
                    LinearGradient(colors: [.white.opacity(0.18), .clear], startPoint: .top, endPoint: .bottom)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                )
        )
        .disabled(!game.canDiscard)
    }

    private func cancelButton(height: CGFloat) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.16)) { game.cancelSelection() }
        } label: {
            Text("取消")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: height)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.18))
        )
    }

    private func tsumoButton(height: CGFloat) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) { game.winByTsumo() }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                Text("ツモ和了")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(game.canTsumoWin ? Color(red: 0.08, green: 0.40, blue: 0.92) : Color.gray.opacity(0.40))
                .overlay(
                    LinearGradient(colors: [.white.opacity(0.16), .clear], startPoint: .top, endPoint: .bottom)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                )
        )
        .disabled(!game.canTsumoWin)
    }

    private func reachButton(height: CGFloat) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) { game.declareReach() }
        } label: {
            VStack(spacing: 0) {
                Text("リーチ")
                    .font(.system(size: 7, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                Text("立直")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.35).onEnded { _ in
            helpTerm = ActionHelpTerm.term(for: "立直")
        })
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(game.canReach ? Color(red: 0.78, green: 0.06, blue: 0.10) : Color.gray.opacity(0.36)))
        .disabled(!game.canReach)
    }

    private func kanButton(height: CGFloat) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) { game.declareClosedKan() }
        } label: {
            VStack(spacing: 0) {
                Text("カン")
                    .font(.system(size: 7, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                Text("槓")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.35).onEnded { _ in
            helpTerm = ActionHelpTerm.term(for: "槓")
        })
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(game.canClosedKan ? Color(red: 0.46, green: 0.22, blue: 0.88) : Color.gray.opacity(0.36)))
        .disabled(!game.canClosedKan)
    }

    private func resetButton(height: CGFloat) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) { game.startNewGame() }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .bold))
                Text("最初から")
                    .font(.system(size: 14, weight: .black, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.18))
        )
    }

    private func reading(for word: String) -> String {
        ActionHelpTerm.term(for: word)?.reading ?? word
    }
}

private struct ActionHelpTerm: Identifiable {
    var id: String { word }
    let word: String
    let reading: String
    let meaning: String

    static func term(for word: String) -> ActionHelpTerm? {
        dictionary[word]
    }

    private static let dictionary: [String: ActionHelpTerm] = [
        "チー": ActionHelpTerm(word: "チー", reading: "チー", meaning: "左の人が捨てた牌だけを使って、同じ種類の連番3枚を作る鳴きです。例：3萬を鳴いて1萬2萬3萬にする。"),
        "ポン": ActionHelpTerm(word: "ポン", reading: "ポン", meaning: "誰かが捨てた牌と、自分の同じ牌2枚で同じ牌3枚の刻子を作る鳴きです。"),
        "カン": ActionHelpTerm(word: "カン", reading: "カン", meaning: "同じ牌4枚で槓子を作る行為です。成立すると嶺上牌を1枚引きます。"),
        "ロン": ActionHelpTerm(word: "ロン", reading: "ロン", meaning: "他家が捨てた牌で和了することです。役がない形ではロンできません。"),
        "槓": ActionHelpTerm(word: "槓", reading: "カン", meaning: "同じ牌4枚で作る面子です。暗槓は手牌の4枚だけで作ります。"),
        "立直": ActionHelpTerm(word: "立直", reading: "リーチ", meaning: "鳴いていない状態であと1枚で和了できる時に宣言します。1000点を供託に出し、リーチという役になります。")
    ]
}
