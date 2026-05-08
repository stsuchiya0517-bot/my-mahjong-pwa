import SwiftUI

struct TileView: View {
    let tile: MahjongTile
    var isSelected: Bool = false
    var isDiscard: Bool = false
    var isCompact: Bool = false

    private var compactMode: Bool { isDiscard || isCompact }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: compactMode ? 7 : 10, style: .continuous)
                .fill(.white)

            RoundedRectangle(cornerRadius: compactMode ? 7 : 10, style: .continuous)
                .stroke(isSelected ? Color.yellow : Color.black.opacity(0.12), lineWidth: isSelected ? 3 : 1)

            TileFaceView(tile: tile, compact: compactMode)
                .padding(compactMode ? 4 : 6)
        }
        .frame(width: compactMode ? 32 : 50, height: compactMode ? 44 : 68)
        .shadow(color: .black.opacity(isSelected ? 0.28 : 0.16), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 6 : 3)
        .offset(y: isSelected ? -10 : 0)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isSelected)
        .accessibilityLabel(tile.label)
    }
}

private struct TileFaceView: View {
    let tile: MahjongTile
    let compact: Bool

    var body: some View {
        switch tile.suit {
        case .man:
            WanFace(rank: tile.rank, compact: compact)
        case .pin:
            PinFace(rank: tile.rank, compact: compact)
        case .sou:
            SouFace(rank: tile.rank, compact: compact)
        case .honor:
            HonorFace(rank: tile.rank, compact: compact)
        }
    }
}

private struct WanFace: View {
    let rank: Int
    let compact: Bool

    var body: some View {
        VStack(spacing: compact ? 1 : 2) {
            Text("\(rank)")
                .font(.system(size: compact ? 14 : 22, weight: .black, design: .rounded))
                .foregroundStyle(.red)

            Text("萬")
                .font(.system(size: compact ? 8 : 12, weight: .black, design: .rounded))
                .foregroundStyle(.red)
        }
    }
}

private struct HonorFace: View {
    let rank: Int
    let compact: Bool

    private var text: String {
        switch rank {
        case 1: return "東"
        case 2: return "南"
        case 3: return "西"
        case 4: return "北"
        case 5: return "白"
        case 6: return "發"
        case 7: return "中"
        default: return "?"
        }
    }

    private var color: Color {
        switch rank {
        case 5: return .gray
        case 6: return .green
        case 7: return .red
        default: return .black
        }
    }

    var body: some View {
        Text(text)
            .font(.system(size: compact ? 18 : 28, weight: .black, design: .rounded))
            .foregroundStyle(color)
    }
}

private struct PinFace: View {
    let rank: Int
    let compact: Bool

    var body: some View {
        PipBoard(rank: rank, compact: compact) { color in
            Circle()
                .fill(color)
                .overlay(Circle().stroke(.white.opacity(0.72), lineWidth: 1))
        }
    }
}

private struct SouFace: View {
    let rank: Int
    let compact: Bool

    var body: some View {
        PipBoard(rank: rank, compact: compact) { color in
            BambooPip(color: color)
        }
    }
}

private struct BambooPip: View {
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 6, height: 16)

            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.8))
                .frame(width: 12, height: 3)

            RoundedRectangle(cornerRadius: 1.5)
                .fill(.white.opacity(0.35))
                .frame(width: 2, height: 12)
        }
    }
}

private struct PipBoard<Pip: View>: View {
    let rank: Int
    let compact: Bool
    let pip: (Color) -> Pip

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(layout(for: rank).enumerated()), id: \.offset) { index, point in
                    pip(pipColor(index: index))
                        .frame(width: compact ? 12 : 16, height: compact ? 12 : 16)
                        .position(
                            x: geo.size.width * point.x,
                            y: geo.size.height * point.y
                        )
                }
            }
        }
    }

    private func pipColor(index: Int) -> Color {
        let colors: [Color] = [.red, .blue, .green]
        return colors[index % colors.count]
    }

    private func layout(for number: Int) -> [CGPoint] {
        switch number {
        case 1:
            return [CGPoint(x: 0.5, y: 0.5)]
        case 2:
            return [CGPoint(x: 0.5, y: 0.28), CGPoint(x: 0.5, y: 0.72)]
        case 3:
            return [CGPoint(x: 0.5, y: 0.2), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.5, y: 0.8)]
        case 4:
            return [CGPoint(x: 0.3, y: 0.3), CGPoint(x: 0.7, y: 0.3), CGPoint(x: 0.3, y: 0.7), CGPoint(x: 0.7, y: 0.7)]
        case 5:
            return [CGPoint(x: 0.3, y: 0.25), CGPoint(x: 0.7, y: 0.25), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.3, y: 0.75), CGPoint(x: 0.7, y: 0.75)]
        case 6:
            return [CGPoint(x: 0.3, y: 0.2), CGPoint(x: 0.7, y: 0.2), CGPoint(x: 0.3, y: 0.5), CGPoint(x: 0.7, y: 0.5), CGPoint(x: 0.3, y: 0.8), CGPoint(x: 0.7, y: 0.8)]
        case 7:
            return [CGPoint(x: 0.3, y: 0.18), CGPoint(x: 0.7, y: 0.18), CGPoint(x: 0.5, y: 0.38), CGPoint(x: 0.3, y: 0.58), CGPoint(x: 0.7, y: 0.58), CGPoint(x: 0.3, y: 0.82), CGPoint(x: 0.7, y: 0.82)]
        case 8:
            return [CGPoint(x: 0.3, y: 0.16), CGPoint(x: 0.7, y: 0.16), CGPoint(x: 0.3, y: 0.38), CGPoint(x: 0.7, y: 0.38), CGPoint(x: 0.3, y: 0.62), CGPoint(x: 0.7, y: 0.62), CGPoint(x: 0.3, y: 0.84), CGPoint(x: 0.7, y: 0.84)]
        case 9:
            return [
                CGPoint(x: 0.28, y: 0.22), CGPoint(x: 0.5, y: 0.22), CGPoint(x: 0.72, y: 0.22),
                CGPoint(x: 0.28, y: 0.5), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.72, y: 0.5),
                CGPoint(x: 0.28, y: 0.78), CGPoint(x: 0.5, y: 0.78), CGPoint(x: 0.72, y: 0.78)
            ]
        default:
            return [CGPoint(x: 0.5, y: 0.5)]
        }
    }
}

#Preview {
    HStack {
        TileView(tile: MahjongTile(suit: .man, rank: 1, copy: 0))
        TileView(tile: MahjongTile(suit: .pin, rank: 5, copy: 0), isSelected: true)
        TileView(tile: MahjongTile(suit: .sou, rank: 8, copy: 0))
        TileView(tile: MahjongTile(suit: .honor, rank: 7, copy: 0), isDiscard: true)
    }
    .padding()
    .background(.green)
}
