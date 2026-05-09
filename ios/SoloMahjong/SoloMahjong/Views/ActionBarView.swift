import SwiftUI

struct ActionBarView: View {
    @ObservedObject var game: MahjongGameViewModel
    var isHorizontal: Bool = false

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
    }

    private var verticalBody: some View {
        VStack(spacing: 8) {
            if let selected = game.selectedTile {
                selectedPanelVertical(selected)
            } else {
                normalPanelVertical
            }
        }
    }

    private var horizontalBody: some View {
        HStack(spacing: 8) {
            if let selected = game.selectedTile {
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
            resetButton(height: 54)
        }
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
}
