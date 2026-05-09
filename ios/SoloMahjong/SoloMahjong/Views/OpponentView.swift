import SwiftUI

struct OpponentView: View {
    let player: MahjongPlayer

    var body: some View {
        HStack(spacing: 5) {
            Text(player.name)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            if player.isDealer { badge("親", color: .yellow, text: .black) }
            if player.isReach { badge("リーチ", color: .red, text: .white) }
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
