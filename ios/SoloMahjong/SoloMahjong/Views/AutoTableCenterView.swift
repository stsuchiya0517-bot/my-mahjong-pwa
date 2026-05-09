import SwiftUI

struct AutoTableCenterView: View {
    @ObservedObject var game: MahjongGameViewModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.22, green: 0.23, blue: 0.22), Color(red: 0.04, green: 0.045, blue: 0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.38), radius: 10, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 23, style: .continuous)
                        .stroke(Color(red: 0.80, green: 0.66, blue: 0.36).opacity(0.45), lineWidth: 2)
                )

            scoreRing

            VStack(spacing: 2) {
                Text(game.roundState.title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(game.wall.count)")
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.98, green: 0.16, blue: 0.18))
                Text("\(game.turnNumber)巡")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 0.50, green: 1.0, blue: 0.34))
            }
            .frame(width: 74, height: 78)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.black.opacity(0.90))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    )
            )

            wind("北").offset(y: -42).rotationEffect(.degrees(180))
            wind("南").offset(y: 42)
            wind("西").offset(x: -43).rotationEffect(.degrees(90))
            wind("東", active: true).offset(x: 43).rotationEffect(.degrees(-90))
        }
    }

    private var scoreRing: some View {
        ZStack {
            miniScore(game.players[safe: 2]?.score ?? 25000).offset(y: -58).rotationEffect(.degrees(180))
            miniScore(game.players[safe: 0]?.score ?? 25000).offset(y: 58)
            miniScore(game.players[safe: 3]?.score ?? 25000).offset(x: -58).rotationEffect(.degrees(90))
            miniScore(game.players[safe: 1]?.score ?? 25000).offset(x: 58).rotationEffect(.degrees(-90))
        }
    }

    private func miniScore(_ score: Int) -> some View {
        Text("\(score)")
            .font(.system(size: 8, weight: .black, design: .monospaced))
            .foregroundStyle(Color(red: 0.50, green: 1.0, blue: 0.35))
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .background(.black.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
    }

    private func wind(_ text: String, active: Bool = false) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .black, design: .serif))
            .foregroundStyle(active ? Color(red: 0.98, green: 0.15, blue: 0.12) : Color(red: 0.92, green: 0.82, blue: 0.43))
            .shadow(color: .black.opacity(0.55), radius: 1, x: 0, y: 1)
    }
}
