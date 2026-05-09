import SwiftUI

struct GameHUDView: View {
    @ObservedObject var game: MahjongGameViewModel
    let onMenu: () -> Void
    var compact: Bool

    var body: some View {
        Group {
            if compact {
                HStack(spacing: 9) {
                    menuButton
                    roundBlock
                    Spacer(minLength: 4)
                    thinkingBadge
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    menuButton
                    roundBlock
                    scoreList
                    thinkingBadge
                    Text(game.message)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))
                        .lineLimit(5)
                        .padding(9)
                        .background(.black.opacity(0.30))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(compact ? 8 : 0)
        .background(compact ? Color.black.opacity(0.16) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var menuButton: some View {
        Button(action: onMenu) {
            Label("メニュー", systemImage: "chevron.left")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(.black.opacity(0.36))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var roundBlock: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 5) {
                Text(game.roundState.detailTitle)
                    .font(.system(size: compact ? 19 : 23, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("供託\(game.roundState.riichiSticks)")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.black.opacity(0.36))
                    .clipShape(Capsule())
            }
            Text("山 \(game.wall.count)枚  巡目 \(game.turnNumber)")
                .font(.system(size: compact ? 10 : 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
        }
    }

    private var scoreList: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(game.players.enumerated()), id: \.element.id) { index, player in
                HStack(spacing: 5) {
                    Text(player.name)
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(index == game.currentPlayerIndex ? 1 : 0.74))
                    if player.isDealer { badge("親", color: .yellow, text: .black) }
                    if player.isReach { badge("リーチ", color: .red, text: .white) }
                    Spacer(minLength: 0)
                    Text("\(player.score)")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    @ViewBuilder
    private var thinkingBadge: some View {
        if let player = game.players[safe: game.currentPlayerIndex], player.isThinking {
            Text("\(player.name) 考え中")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.black)
                .padding(.horizontal, 8)
                .frame(height: 26)
                .background(Color.yellow)
                .clipShape(Capsule())
                .transition(.scale.combined(with: .opacity))
        } else if compact {
            Text(game.message)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.80))
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
    }

    private func badge(_ label: String, color: Color, text: Color) -> some View {
        Text(label)
            .font(.system(size: 8, weight: .black, design: .rounded))
            .foregroundStyle(text)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(color)
            .clipShape(Capsule())
    }
}
