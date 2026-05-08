import SwiftUI

struct ActionBarView: View {
    @ObservedObject var game: MahjongGameViewModel

    var body: some View {
        VStack(spacing: 8) {
            if let selected = game.selectedTile {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("選択中")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.68))
                        Text(selected.label)
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.yellow)
                    }
                    .frame(width: 76, alignment: .leading)

                    Button {
                        game.discardSelectedTile()
                    } label: {
                        Text("捨てる")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(!game.canDiscard)

                    Button {
                        game.cancelSelection()
                    } label: {
                        Text("取消")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .frame(width: 54, height: 54)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }
            } else {
                HStack(spacing: 10) {
                    Button {
                        game.drawForUserIfNeeded()
                    } label: {
                        Text("ツモ")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(game.currentPlayerIndex != 0 || game.isBusy)

                    Button {
                        game.startNewGame()
                    } label: {
                        Text("最初から")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 22, x: 0, y: 12)
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
    }
}
