import SwiftUI

struct OpponentView: View {
    let player: MahjongPlayer
    var isActive: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            Text(player.name)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            if player.isDealer { badge("親", color: .yellow, text: .black) }
            if player.isReach { badge("リーチ", color: .red, text: .white) }
            if player.isThinking {
                Image(systemName: "ellipsis")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 25)
        .background(.black.opacity(isActive ? 0.64 : 0.44))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(isActive ? Color.yellow.opacity(0.64) : Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
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
