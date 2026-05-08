import SwiftUI

struct OpponentView: View {
    let player: MahjongPlayer
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(player.name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                if player.isDealer {
                    Text("親")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.yellow)
                        .foregroundStyle(.black)
                        .clipShape(Capsule())
                }
                if player.isReach {
                    Text("リーチ")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.red)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                Spacer(minLength: 4)
                Text("\(player.score)")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
            }

            HStack(spacing: 3) {
                ForEach(0..<min(player.hand.count, 14), id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(LinearGradient(colors: [Color.blue.opacity(0.95), Color.blue.opacity(0.38)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 12, height: 22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(.white.opacity(0.16), lineWidth: 1)
                        )
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 4) {
                ForEach(player.discards.suffix(6)) { tile in
                    TileView(tile: tile, isDiscard: true)
                }
                Spacer(minLength: 0)
            }
            .frame(minHeight: 38, alignment: .leading)

            if player.isThinking {
                Text("考え中…")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.yellow)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(isActive ? 0.18 : 0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isActive ? .yellow.opacity(0.85) : .white.opacity(0.14), lineWidth: isActive ? 2 : 1)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: player.isThinking)
    }
}
