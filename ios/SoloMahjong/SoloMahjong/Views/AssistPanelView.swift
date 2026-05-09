import SwiftUI

struct AssistPanelView: View {
    @ObservedObject var game: MahjongGameViewModel
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("アシスト", systemImage: "sparkle.magnifyingglass")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.98, green: 0.88, blue: 0.54))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white.opacity(0.78))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                metric(title: "向聴", value: game.shantenText)
                metric(title: "山", value: "\(game.wall.count)")
                metric(title: "巡目", value: "\(game.turnNumber)")
            }

            VStack(alignment: .leading, spacing: 7) {
                ForEach(Array(game.assistRecommendations.enumerated()), id: \.element.id) { index, item in
                    Button {
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.78)) {
                            game.selectRecommendation(item)
                            onClose()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("\(index + 1)")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(.black)
                                .frame(width: 19, height: 19)
                                .background(Color(red: 0.98, green: 0.86, blue: 0.34))
                                .clipShape(Circle())

                            TileView(tile: item.tile, displayStyle: .river)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.tile.label)
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(item.reason)
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.64))
                                    .lineLimit(2)
                            }

                            Spacer()
                        }
                        .padding(7)
                        .background(.white.opacity(0.075))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(.black.opacity(0.76))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(red: 0.92, green: 0.76, blue: 0.30).opacity(0.46), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.40), radius: 18, x: 0, y: 8)
    }

    private func metric(title: String, value: String) -> some View {
        VStack(spacing: 1) {
            Text(title)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.48))
            Text(value)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
