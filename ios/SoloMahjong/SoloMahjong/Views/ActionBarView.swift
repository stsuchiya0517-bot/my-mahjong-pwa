import SwiftUI

struct ActionBarView: View {
    @ObservedObject var game: MahjongGameViewModel

    var body: some View {
        VStack(spacing: 8) {
            if let selected = game.selectedTile {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("選択中")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.68))
                        Text(selected.label)
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.yellow)
                    }
                    .frame(width: 76, alignment: .leading)

                    Button {
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
                            game.discardSelectedTile()
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text("捨てる")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(!game.canDiscard)

                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            game.cancelSelection()
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text("取消")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                        }
                        .frame(width: 58, height: 58)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }
            } else {
                HStack(spacing: 10) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            game.drawForUserIfNeeded()
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 17, weight: .bold))
                            Text("ツモ")
                                .font(.system(size: 17, weight: .black, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(game.currentPlayerIndex != 0 || game.isBusy)

                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            game.startNewGame()
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 17, weight: .bold))
                            Text("最初から")
                                .font(.system(size: 17, weight: .black, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.26), radius: 18, x: 0, y: 8)
    }
}
