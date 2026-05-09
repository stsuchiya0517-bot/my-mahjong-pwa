import SwiftUI

struct GameBoardView: View {
    @ObservedObject var game: MahjongGameViewModel
    let onMenu: () -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack {
                FeltBackground()

                if geo.size.width > geo.size.height {
                    LandscapeGameBoardView(game: game, onMenu: onMenu)
                } else {
                    PortraitGameBoardView(game: game, onMenu: onMenu)
                }
            }
            .sensoryFeedback(.selection, trigger: game.lastDiscard?.id)
            .sensoryFeedback(.success, trigger: game.winningResult?.id)
        }
    }
}

struct FeltBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.30, blue: 0.13),
                    Color(red: 0.03, green: 0.17, blue: 0.08),
                    Color(red: 0.01, green: 0.08, blue: 0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Rectangle()
                .fill(Color.white.opacity(0.035))
                .overlay {
                    Canvas { context, size in
                        for x in stride(from: 0, through: size.width, by: 7) {
                            var path = Path()
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x + size.height * 0.18, y: size.height))
                            context.stroke(path, with: .color(.white.opacity(0.025)), lineWidth: 0.7)
                        }
                    }
                }
                .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 12)
                .padding(18)
                .ignoresSafeArea()
        }
    }
}

enum PlayerSeat {
    case bottom
    case right
    case top
    case left
}
