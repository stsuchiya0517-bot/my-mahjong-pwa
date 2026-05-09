import SwiftUI

struct AutoTableCenterView: View {
    @ObservedObject var game: MahjongGameViewModel

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let centerSize = max(66, side * 0.54)

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

                scoreLabel(game.players[safe: 2]?.score ?? 25000)
                    .position(x: side * 0.50, y: side * 0.14)
                scoreLabel(game.players[safe: 0]?.score ?? 25000)
                    .position(x: side * 0.50, y: side * 0.86)
                scoreLabel(game.players[safe: 3]?.score ?? 25000)
                    .position(x: side * 0.15, y: side * 0.50)
                scoreLabel(game.players[safe: 1]?.score ?? 25000)
                    .position(x: side * 0.85, y: side * 0.50)

                centerDisplay
                    .frame(width: centerSize, height: centerSize)
                    .position(x: side / 2, y: side / 2)
            }
            .frame(width: side, height: side)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }

    private var centerDisplay: some View {
        VStack(spacing: 1) {
            Text(game.roundState.title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.72)
            Text("\(game.wall.count)")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.98, green: 0.16, blue: 0.18))
                .minimumScaleFactor(0.78)
            Text("\(game.turnNumber)巡")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.50, green: 1.0, blue: 0.34))
            Text("\(game.roundState.honba)本場")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.92, green: 0.82, blue: 0.43))
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.black.opacity(0.90))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func scoreLabel(_ score: Int) -> some View {
        Text("\(score)")
            .font(.system(size: 8, weight: .black, design: .monospaced))
            .foregroundStyle(Color(red: 0.50, green: 1.0, blue: 0.35))
            .lineLimit(1)
            .padding(.horizontal, 4)
            .frame(width: 45, height: 14)
            .background(.black.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

}
