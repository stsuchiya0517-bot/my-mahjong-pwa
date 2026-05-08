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
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.99, green: 0.985, blue: 0.955),
                            Color(red: 0.91, green: 0.90, blue: 0.86)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            RoundedRectangle(cornerRadius: compactMode ? 7 : 10, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
                .padding(1)

            RoundedRectangle(cornerRadius: compactMode ? 7 : 10, style: .continuous)
                .stroke(isSelected ? Color.yellow : Color.black.opacity(0.16), lineWidth: isSelected ? 3 : 1)

            TileFaceView(tile: tile, compact: compactMode)
                .padding(compactMode ? 4 : 6)
        }
        .frame(width: compactMode ? 32 : 50, height: compactMode ? 44 : 68)
        .shadow(color: .black.opacity(isSelected ? 0.24 : 0.12), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 6 : 3)
        .offset(y: isSelected ? -10 : 0)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.74), value: isSelected)
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
                .font(.system(size: compact ? 14 : 21, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.08))

            Text("萬")
                .font(.system(size: compact ? 8 : 12, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.72, green: 0.08, blue: 0.08))
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
        case 6: return Color(red: 0.00, green: 0.48, blue: 0.18)
        case 7: return Color(red: 0.78, green: 0.08, blue: 0.08)
        default: return Color(red: 0.06, green: 0.06, blue: 0.06)
        }
    }

    var body: some View {
        if rank == 5 {
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color(red: 0.08, green: 0.08, blue: 0.08), lineWidth: compact ? 1.8 : 2.4)
                .frame(width: compact ? 12 : 20, height: compact ? 16 : 24)
        } else {
            Text(text)
                .font(.system(size: compact ? 18 : 28, weight: .black, design: .rounded))
                .foregroundStyle(color)
        }
    }
}

private struct PinFace: View {
    let rank: Int
    let compact: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(layout(for: rank).enumerated()), id: \.offset) { index, point in
                    PinPip(style: pipStyle(index: index, rank: rank), compact: compact)
                        .position(x: geo.size.width * point.x, y: geo.size.height * point.y)
                }
            }
        }
    }

    private func pipStyle(index: Int, rank: Int) -> PinPipStyle {
        if rank == 1 { return .center }
        let styles: [PinPipStyle] = [.blue, .red, .green]
        return styles[index % styles.count]
    }
}

private enum PinPipStyle {
    case blue
    case red
    case green
    case center
}

private struct PinPip: View {
    let style: PinPipStyle
    let compact: Bool

    var body: some View {
        let size: CGFloat = compact ? 10 : 13

        ZStack {
            Circle()
                .fill(fillColor)
                .frame(width: size, height: size)

            Circle()
                .stroke(strokeColor, lineWidth: compact ? 1.4 : 1.8)
                .frame(width: size, height: size)

            Circle()
                .fill(Color(red: 0.98, green: 0.97, blue: 0.92))
                .frame(width: size * 0.38, height: size * 0.38)
        }
    }

    private var fillColor: Color {
        switch style {
        case .blue: return Color(red: 0.15, green: 0.38, blue: 0.72)
        case .red: return Color(red: 0.78, green: 0.12, blue: 0.12)
        case .green: return Color(red: 0.08, green: 0.50, blue: 0.24)
        case .center: return Color(red: 0.78, green: 0.12, blue: 0.12)
        }
    }

    private var strokeColor: Color {
        switch style {
        case .blue: return Color(red: 0.06, green: 0.22, blue: 0.56)
        case .red: return Color(red: 0.55, green: 0.05, blue: 0.05)
        case .green: return Color(red: 0.04, green: 0.34, blue: 0.16)
        case .center: return Color(red: 0.10, green: 0.30, blue: 0.62)
        }
    }
}

private struct SouFace: View {
    let rank: Int
    let compact: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(layout(for: rank).enumerated()), id: \.offset) { _, point in
                    BambooPip(compact: compact)
                        .position(x: geo.size.width * point.x, y: geo.size.height * point.y)
                }
            }
        }
    }
}

private struct BambooPip: View {
    let compact: Bool

    var body: some View {
        let h: CGFloat = compact ? 12 : 15
        let w: CGFloat = compact ? 4.5 : 5.5

        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.14, green: 0.48, blue: 0.20),
                            Color(red: 0.07, green: 0.32, blue: 0.14)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: w, height: h)

            VStack(spacing: h * 0.22) {
                Rectangle()
                    .fill(Color(red: 0.80, green: 0.73, blue: 0.52))
                    .frame(width: w * 1.1, height: 1)
                Rectangle()
                    .fill(Color(red: 0.80, green: 0.73, blue: 0.52))
                    .frame(width: w * 1.1, height: 1)
            }
        }
    }
}

private extension PinFace {
    func layout(for number: Int) -> [CGPoint] {
        switch number {
        case 1: return [CGPoint(x: 0.5, y: 0.5)]
        case 2: return [CGPoint(x: 0.5, y: 0.28), CGPoint(x: 0.5, y: 0.72)]
        case 3: return [CGPoint(x: 0.5, y: 0.2), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.5, y: 0.8)]
        case 4: return [CGPoint(x: 0.3, y: 0.3), CGPoint(x: 0.7, y: 0.3), CGPoint(x: 0.3, y: 0.7), CGPoint(x: 0.7, y: 0.7)]
        case 5: return [CGPoint(x: 0.3, y: 0.25), CGPoint(x: 0.7, y: 0.25), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.3, y: 0.75), CGPoint(x: 0.7, y: 0.75)]
        case 6: return [CGPoint(x: 0.3, y: 0.2), CGPoint(x: 0.7, y: 0.2), CGPoint(x: 0.3, y: 0.5), CGPoint(x: 0.7, y: 0.5), CGPoint(x: 0.3, y: 0.8), CGPoint(x: 0.7, y: 0.8)]
        case 7: return [CGPoint(x: 0.3, y: 0.18), CGPoint(x: 0.7, y: 0.18), CGPoint(x: 0.5, y: 0.38), CGPoint(x: 0.3, y: 0.58), CGPoint(x: 0.7, y: 0.58), CGPoint(x: 0.3, y: 0.82), CGPoint(x: 0.7, y: 0.82)]
        case 8: return [CGPoint(x: 0.3, y: 0.16), CGPoint(x: 0.7, y: 0.16), CGPoint(x: 0.3, y: 0.38), CGPoint(x: 0.7, y: 0.38), CGPoint(x: 0.3, y: 0.62), CGPoint(x: 0.7, y: 0.62), CGPoint(x: 0.3, y: 0.84), CGPoint(x: 0.7, y: 0.84)]
        case 9:
            return [
                CGPoint(x: 0.28, y: 0.22), CGPoint(x: 0.50, y: 0.22), CGPoint(x: 0.72, y: 0.22),
                CGPoint(x: 0.28, y: 0.50), CGPoint(x: 0.50, y: 0.50), CGPoint(x: 0.72, y: 0.50),
                CGPoint(x: 0.28, y: 0.78), CGPoint(x: 0.50, y: 0.78), CGPoint(x: 0.72, y: 0.78)
            ]
        default: return [CGPoint(x: 0.5, y: 0.5)]
        }
    }
}

private extension SouFace {
    func layout(for number: Int) -> [CGPoint] {
        switch number {
        case 1: return [CGPoint(x: 0.5, y: 0.5)]
        case 2: return [CGPoint(x: 0.38, y: 0.5), CGPoint(x: 0.62, y: 0.5)]
        case 3: return [CGPoint(x: 0.3, y: 0.5), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.7, y: 0.5)]
        case 4: return [CGPoint(x: 0.35, y: 0.3), CGPoint(x: 0.65, y: 0.3), CGPoint(x: 0.35, y: 0.7), CGPoint(x: 0.65, y: 0.7)]
        case 5: return [CGPoint(x: 0.35, y: 0.25), CGPoint(x: 0.65, y: 0.25), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.35, y: 0.75), CGPoint(x: 0.65, y: 0.75)]
        case 6: return [CGPoint(x: 0.35, y: 0.22), CGPoint(x: 0.65, y: 0.22), CGPoint(x: 0.35, y: 0.5), CGPoint(x: 0.65, y: 0.5), CGPoint(x: 0.35, y: 0.78), CGPoint(x: 0.65, y: 0.78)]
        case 7: return [CGPoint(x: 0.35, y: 0.18), CGPoint(x: 0.65, y: 0.18), CGPoint(x: 0.5, y: 0.38), CGPoint(x: 0.35, y: 0.58), CGPoint(x: 0.65, y: 0.58), CGPoint(x: 0.35, y: 0.82), CGPoint(x: 0.65, y: 0.82)]
        case 8: return [CGPoint(x: 0.35, y: 0.16), CGPoint(x: 0.65, y: 0.16), CGPoint(x: 0.35, y: 0.38), CGPoint(x: 0.65, y: 0.38), CGPoint(x: 0.35, y: 0.62), CGPoint(x: 0.65, y: 0.62), CGPoint(x: 0.35, y: 0.84), CGPoint(x: 0.65, y: 0.84)]
        case 9:
            return [
                CGPoint(x: 0.32, y: 0.22), CGPoint(x: 0.50, y: 0.22), CGPoint(x: 0.68, y: 0.22),
                CGPoint(x: 0.32, y: 0.50), CGPoint(x: 0.50, y: 0.50), CGPoint(x: 0.68, y: 0.50),
                CGPoint(x: 0.32, y: 0.78), CGPoint(x: 0.50, y: 0.78), CGPoint(x: 0.68, y: 0.78)
            ]
        default: return [CGPoint(x: 0.5, y: 0.5)]
        }
    }
}

#Preview {
    HStack {
        TileView(tile: MahjongTile(suit: .man, rank: 1, copy: 0))
        TileView(tile: MahjongTile(suit: .pin, rank: 5, copy: 0), isSelected: true)
        TileView(tile: MahjongTile(suit: .sou, rank: 6, copy: 0))
        TileView(tile: MahjongTile(suit: .honor, rank: 7, copy: 0), isDiscard: true)
    }
    .padding()
    .background(.green)
}
