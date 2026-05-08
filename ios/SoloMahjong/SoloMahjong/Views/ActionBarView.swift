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
        .background(.ultraThinMaterial.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.26), radius: 18, x: 0, y: 8)
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
            .frame(maxWidth: .infinity)
            .frame(height: height)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .disabled(!game.canDiscard)
    }

    private func cancelButton(height: CGFloat) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.16)) { game.cancelSelection() }
        } label: {
            Text("取消")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: height)
        }
        .buttonStyle(.bordered)
        .tint(.white)
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
            .frame(maxWidth: .infinity)
            .frame(height: height)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
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
            .frame(maxWidth: .infinity)
            .frame(height: height)
        }
        .buttonStyle(.bordered)
        .tint(.white)
    }
}
