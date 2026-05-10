import SwiftUI

struct PlayerHandView: View {
    @ObservedObject var game: MahjongGameViewModel
    let tileStyle: TileDisplayStyle

    var body: some View {
        GeometryReader { geo in
            let hand = game.players[safe: 0]?.hand ?? []
            let recommendations = game.assistRecommendations
            let maxTileWidth = tileStyle == .hand ? 34.0 : 24.0
            let width = min(maxTileWidth, max(19, (geo.size.width - 12) / CGFloat(max(hand.count, 1))))
            let height = tileStyle == .hand ? 50.0 : 38.0
            let scale = width / maxTileWidth

            HStack(alignment: .bottom, spacing: 1) {
                ForEach(hand) { tile in
                    let canDiscard = game.canSelectForDiscard(tile)
                    let assistRank = recommendations.firstIndex { $0.tile.id == tile.id }.map { $0 + 1 }
                    TileView(tile: tile, isSelected: game.selectedTileID == tile.id, displayStyle: tileStyle)
                        .scaleEffect(scale, anchor: .bottom)
                        .frame(width: width, height: height + 8)
                        .opacity(canDiscard ? 1 : 0.42)
                        .brightness(canDiscard ? 0 : -0.18)
                        .saturation(canDiscard ? 1 : 0.30)
                        .overlay {
                            if !canDiscard {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(.black.opacity(0.24))
                                    .scaleEffect(scale, anchor: .bottom)
                            } else if let assistRank {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .stroke(assistColor(for: assistRank), lineWidth: assistRank == 1 ? 2.8 : 2.0)
                                    .scaleEffect(scale, anchor: .bottom)
                                    .shadow(color: assistColor(for: assistRank).opacity(0.60), radius: assistRank == 1 ? 8 : 4, x: 0, y: 0)
                            }
                        }
                        .overlay(alignment: .top) {
                            if let assistRank, canDiscard, !game.isDeclaringReach {
                                Text(assistLabel(for: assistRank))
                                    .font(.system(size: 7, weight: .black, design: .rounded))
                                    .foregroundStyle(assistRank == 1 ? .black : .white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.55)
                                    .padding(.horizontal, 3)
                                    .padding(.vertical, 1)
                                    .background(assistColor(for: assistRank))
                                    .clipShape(Capsule())
                                    .offset(y: -9)
                            } else if game.isDeclaringReach, canDiscard, let waits = game.reachWaitText(afterDiscarding: tile) {
                                Text("待 \(waits)")
                                    .font(.system(size: 7, weight: .black, design: .rounded))
                                    .foregroundStyle(.black)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.55)
                                    .padding(.horizontal, 3)
                                    .padding(.vertical, 1)
                                    .background(Color.yellow)
                                    .clipShape(Capsule())
                                    .offset(y: -9)
                            }
                        }
                        .offset(y: game.isAfterUserCall && canDiscard ? -3 : 0)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if canDiscard {
                                game.handleHandTap(tile)
                            }
                        }
                        .accessibilityHidden(!canDiscard)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [Color.black.opacity(0.46), Color.black.opacity(0.16)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    Rectangle()
                        .fill(Color(red: 0.11, green: 0.31, blue: 0.14).opacity(0.24))
                        .blur(radius: 10)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(game.currentPlayerIndex == 0 ? Color.yellow.opacity(0.72) : Color.white.opacity(0.10), lineWidth: 1.4)
            )
            .overlay(alignment: .topLeading) {
                if game.currentPlayerIndex == 0, !recommendations.isEmpty {
                    Text("狙い \(game.assistYakuFocusText)")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.34))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.62))
                        .clipShape(Capsule())
                        .padding(.leading, 8)
                        .offset(y: -14)
                }
            }
            .shadow(color: Color.yellow.opacity(game.currentPlayerIndex == 0 ? 0.18 : 0), radius: 12, x: 0, y: 0)
        }
    }

    private func assistColor(for rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.78, blue: 0.04)
        case 2: return Color(red: 0.18, green: 0.68, blue: 1.0)
        default: return Color(red: 0.22, green: 0.88, blue: 0.45)
        }
    }

    private func assistLabel(for rank: Int) -> String {
        switch rank {
        case 1: return "推奨"
        case 2: return "候補"
        default: return "別案"
        }
    }
}
