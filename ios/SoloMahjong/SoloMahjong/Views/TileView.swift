import SwiftUI

enum TileDisplayStyle {
    case regular
    case hand
    case handCompact
    case river
}

struct TileView: View {
    let tile: MahjongTile
    var isSelected: Bool = false
    var isDiscard: Bool = false
    var isCompact: Bool = false
    var displayStyle: TileDisplayStyle = .regular

    private var effectiveStyle: TileDisplayStyle {
        if isDiscard || isCompact { return .river }
        return displayStyle
    }

    private var width: CGFloat {
        switch effectiveStyle {
        case .regular: return 46
        case .hand: return 34
        case .handCompact: return 24
        case .river: return 28
        }
    }

    private var height: CGFloat {
        switch effectiveStyle {
        case .regular: return 63
        case .hand: return 50
        case .handCompact: return 38
        case .river: return 39
        }
    }

    private var cornerRadius: CGFloat {
        switch effectiveStyle {
        case .regular: return 8
        case .hand: return 7
        case .handCompact: return 6
        case .river: return 6
        }
    }

    private var isDense: Bool { effectiveStyle != .regular }

    var body: some View {
        ZStack {
            if effectiveStyle == .hand || effectiveStyle == .handCompact || effectiveStyle == .regular || effectiveStyle == .river {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.80, green: 0.52, blue: 0.16),
                                Color(red: 0.58, green: 0.34, blue: 0.07)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(x: effectiveStyle == .river ? 1.2 : 2.2, y: effectiveStyle == .river ? 1.7 : 3.2)
            }

            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.99, green: 0.985, blue: 0.96),
                                Color(red: 0.93, green: 0.915, blue: 0.865)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color(red: 0.77, green: 0.74, blue: 0.66), lineWidth: 0.8)

                LinearGradient(
                    colors: [.white.opacity(0.42), .clear],
                    startPoint: .topLeading,
                    endPoint: .center
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

                RoundedRectangle(cornerRadius: cornerRadius - 1, style: .continuous)
                    .stroke(Color.white.opacity(0.75), lineWidth: 0.8)
                    .padding(1.2)

                if isSelected {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.yellow, lineWidth: 2.4)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.yellow.opacity(0.10))
                }

                TileFaceView(tile: tile, dense: isDense)
                    .padding(isDense ? 3 : 5.5)
            }
        }
        .frame(width: width, height: height + ((effectiveStyle == .river) ? 0 : 3))
        .shadow(color: .black.opacity(isSelected ? 0.30 : 0.20), radius: isSelected ? 8 : 4.2, x: 0, y: isSelected ? 5 : 2.6)
        .offset(y: isSelected ? (effectiveStyle == .hand || effectiveStyle == .handCompact ? -6 : -4) : 0)
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.74), value: isSelected)
        .accessibilityLabel(tile.label)
    }
}

private struct TileFaceView: View {
    let tile: MahjongTile
    let dense: Bool

    var body: some View {
        switch tile.suit {
        case .man:
            WanFace(rank: tile.rank, dense: dense)
        case .pin:
            PinFace(rank: tile.rank, dense: dense)
        case .sou:
            SouFace(rank: tile.rank, dense: dense)
        case .honor:
            HonorFace(rank: tile.rank, dense: dense)
        }
    }
}

private struct WanFace: View {
    let rank: Int
    let dense: Bool

    var body: some View {
        VStack(spacing: dense ? -1 : 1) {
            Text("\(rank)")
                .font(.system(size: dense ? 16 : 23, weight: .black, design: .serif))
                .foregroundStyle(Color.black.opacity(0.92))
                .shadow(color: .white.opacity(0.55), radius: 0.2, x: 0, y: 0.4)

            Text("萬")
                .font(.system(size: dense ? 8.5 : 12.5, weight: .black, design: .serif))
                .foregroundStyle(Color(red: 0.70, green: 0.04, blue: 0.04))
                .shadow(color: .white.opacity(0.45), radius: 0.2, x: 0, y: 0.3)

            Capsule()
                .fill(Color.black.opacity(0.65))
                .frame(width: dense ? 7 : 10, height: dense ? 1 : 1.4)
                .padding(.top, dense ? -1 : 0)
        }
    }
}

private struct HonorFace: View {
    let rank: Int
    let dense: Bool

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
        case 6: return Color(red: 0.02, green: 0.45, blue: 0.16)
        case 7: return Color(red: 0.76, green: 0.06, blue: 0.06)
        default: return Color.black.opacity(0.93)
        }
    }

    var body: some View {
        if rank == 5 {
            ZStack {
                RoundedRectangle(cornerRadius: dense ? 1.5 : 2.2)
                    .stroke(Color(red: 0.10, green: 0.22, blue: 0.62), lineWidth: dense ? 1.3 : 1.9)
                RoundedRectangle(cornerRadius: dense ? 0.8 : 1.3)
                    .stroke(Color(red: 0.10, green: 0.22, blue: 0.62).opacity(0.70), lineWidth: dense ? 0.7 : 1.0)
                    .padding(dense ? 2.2 : 3.0)
            }
            .frame(width: dense ? 11 : 18, height: dense ? 14 : 22)
        } else {
            Text(text)
                .font(.system(size: dense ? 18 : 28, weight: .black, design: .serif))
                .foregroundStyle(color)
                .shadow(color: .white.opacity(0.48), radius: 0.2, x: 0, y: 0.4)
        }
    }
}

private struct PinFace: View {
    let rank: Int
    let dense: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(layout(for: rank).enumerated()), id: \.offset) { index, point in
                    PinPip(style: pipStyle(index: index, rank: rank), dense: dense)
                        .position(x: geo.size.width * point.x, y: geo.size.height * point.y)
                }
            }
        }
    }

    private func pipStyle(index: Int, rank: Int) -> PinPipStyle {
        if rank == 1 { return .redBlue }
        if rank == 5 { return index == 2 ? .redCenter : [.black, .black, .redCenter, .black, .black][index] }
        let base: [PinPipStyle] = [.black, .black, .redCenter, .black, .black, .redCenter, .black, .black, .black]
        return base[index % base.count]
    }
}

private enum PinPipStyle { case black, redCenter, redBlue }

private struct PinPip: View {
    let style: PinPipStyle
    let dense: Bool

    var body: some View {
        let size: CGFloat = dense ? 7.8 : 12.0
        let ring: CGFloat = dense ? 1.0 : 1.5

        ZStack {
            Circle()
                .fill(Color(red: 0.98, green: 0.97, blue: 0.92))
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.12), radius: 0.6, x: 0, y: 0.5)

            switch style {
            case .black:
                Circle().stroke(Color.black.opacity(0.92), lineWidth: ring).frame(width: size, height: size)
                Circle().stroke(Color.black.opacity(0.70), lineWidth: ring * 0.72).frame(width: size * 0.58, height: size * 0.58)
                Circle().fill(Color.black.opacity(0.18)).frame(width: size * 0.20, height: size * 0.20)
            case .redCenter:
                Circle().stroke(Color.black.opacity(0.88), lineWidth: ring).frame(width: size, height: size)
                Circle().stroke(Color(red: 0.76, green: 0.06, blue: 0.07), lineWidth: ring * 0.9).frame(width: size * 0.58, height: size * 0.58)
                Circle().fill(Color(red: 0.76, green: 0.06, blue: 0.07).opacity(0.25)).frame(width: size * 0.22, height: size * 0.22)
            case .redBlue:
                Circle().stroke(Color(red: 0.10, green: 0.24, blue: 0.62), lineWidth: ring).frame(width: size * 1.05, height: size * 1.05)
                Circle().stroke(Color(red: 0.72, green: 0.07, blue: 0.07), lineWidth: ring * 0.92).frame(width: size * 0.68, height: size * 0.68)
                Circle().stroke(Color.black.opacity(0.72), lineWidth: ring * 0.55).frame(width: size * 0.38, height: size * 0.38)
                Circle().fill(Color.black.opacity(0.78)).frame(width: size * 0.12, height: size * 0.12)
            }

            Circle()
                .fill(.white.opacity(0.36))
                .frame(width: size * 0.22, height: size * 0.22)
                .offset(x: -size * 0.20, y: -size * 0.22)
        }
    }
}

private struct SouFace: View {
    let rank: Int
    let dense: Bool

    var body: some View {
        if rank == 1 {
            OneSouFace(dense: dense)
        } else {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(layout(for: rank).enumerated()), id: \.offset) { index, point in
                    BambooPip(color: bambooColor(index: index, rank: rank), dense: dense)
                        .position(x: geo.size.width * point.x, y: geo.size.height * point.y)
                }
            }
        }
        }
    }

    private func bambooColor(index: Int, rank: Int) -> BambooColor {
        if rank == 1 { return .green }
        if rank == 8 { return [ .green, .red, .green, .green, .red, .green, .green, .green ][index] }
        if rank == 6 { return [ .green, .green, .red, .red, .green, .green ][index] }
        return index % 3 == 1 ? .red : .green
    }
}

private enum BambooColor { case green, red, blue }

private struct BambooPip: View {
    let color: BambooColor
    let dense: Bool

    var body: some View {
        let h: CGFloat = dense ? 10.0 : 14.8
        let w: CGFloat = dense ? 3.5 : 5.0
        let main: Color = {
            switch color {
            case .green: return Color(red: 0.03, green: 0.43, blue: 0.15)
            case .red: return Color(red: 0.74, green: 0.05, blue: 0.06)
            case .blue: return Color(red: 0.14, green: 0.31, blue: 0.68)
            }
        }()

        return ZStack {
            VStack(spacing: dense ? 0.8 : 1.1) {
                ForEach(0..<3, id: \.self) { segment in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [main.opacity(0.92), main, main.opacity(0.72)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: w, height: h / 3.7)
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(segment == 1 ? 0.24 : 0.14), lineWidth: 0.35)
                        )
                }
            }
            Capsule()
                .fill(Color(red: 0.88, green: 0.84, blue: 0.62))
                .frame(width: w * 1.32, height: 0.72)
                .offset(y: -h * 0.17)
            Capsule()
                .fill(Color(red: 0.88, green: 0.84, blue: 0.62))
                .frame(width: w * 1.32, height: 0.72)
                .offset(y: h * 0.17)
        }
        .shadow(color: .black.opacity(0.13), radius: 0.6, x: 0, y: 0.5)
    }
}

private struct OneSouFace: View {
    let dense: Bool

    var body: some View {
        let size: CGFloat = dense ? 18 : 27
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                Capsule()
                    .fill(index.isMultiple(of: 2) ? Color(red: 0.05, green: 0.42, blue: 0.15) : Color(red: 0.72, green: 0.06, blue: 0.06))
                    .frame(width: dense ? 2.8 : 4.0, height: dense ? 9 : 13)
                    .offset(y: dense ? -4 : -6)
                    .rotationEffect(.degrees(Double(index) * 30 - 75))
            }
            Circle()
                .fill(Color(red: 0.05, green: 0.42, blue: 0.15))
                .frame(width: size * 0.44, height: size * 0.44)
            Circle()
                .stroke(Color.black.opacity(0.78), lineWidth: dense ? 0.9 : 1.2)
                .frame(width: size * 0.60, height: size * 0.60)
            Circle()
                .fill(Color(red: 0.72, green: 0.06, blue: 0.06))
                .frame(width: size * 0.16, height: size * 0.16)
                .offset(y: size * 0.05)
        }
        .frame(width: size, height: size)
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
        case 9: return [CGPoint(x: 0.28, y: 0.22), CGPoint(x: 0.50, y: 0.22), CGPoint(x: 0.72, y: 0.22), CGPoint(x: 0.28, y: 0.50), CGPoint(x: 0.50, y: 0.50), CGPoint(x: 0.72, y: 0.50), CGPoint(x: 0.28, y: 0.78), CGPoint(x: 0.50, y: 0.78), CGPoint(x: 0.72, y: 0.78)]
        default: return [CGPoint(x: 0.5, y: 0.5)]
        }
    }
}

private extension SouFace {
    func layout(for number: Int) -> [CGPoint] {
        switch number {
        case 1: return [CGPoint(x: 0.5, y: 0.5)]
        case 2: return [CGPoint(x: 0.40, y: 0.5), CGPoint(x: 0.60, y: 0.5)]
        case 3: return [CGPoint(x: 0.31, y: 0.5), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.69, y: 0.5)]
        case 4: return [CGPoint(x: 0.36, y: 0.3), CGPoint(x: 0.64, y: 0.3), CGPoint(x: 0.36, y: 0.7), CGPoint(x: 0.64, y: 0.7)]
        case 5: return [CGPoint(x: 0.36, y: 0.25), CGPoint(x: 0.64, y: 0.25), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.36, y: 0.75), CGPoint(x: 0.64, y: 0.75)]
        case 6: return [CGPoint(x: 0.36, y: 0.22), CGPoint(x: 0.64, y: 0.22), CGPoint(x: 0.36, y: 0.5), CGPoint(x: 0.64, y: 0.5), CGPoint(x: 0.36, y: 0.78), CGPoint(x: 0.64, y: 0.78)]
        case 7: return [CGPoint(x: 0.36, y: 0.18), CGPoint(x: 0.64, y: 0.18), CGPoint(x: 0.5, y: 0.38), CGPoint(x: 0.36, y: 0.58), CGPoint(x: 0.64, y: 0.58), CGPoint(x: 0.36, y: 0.82), CGPoint(x: 0.64, y: 0.82)]
        case 8: return [CGPoint(x: 0.36, y: 0.16), CGPoint(x: 0.64, y: 0.16), CGPoint(x: 0.36, y: 0.38), CGPoint(x: 0.64, y: 0.38), CGPoint(x: 0.36, y: 0.62), CGPoint(x: 0.64, y: 0.62), CGPoint(x: 0.36, y: 0.84), CGPoint(x: 0.64, y: 0.84)]
        case 9: return [CGPoint(x: 0.32, y: 0.22), CGPoint(x: 0.50, y: 0.22), CGPoint(x: 0.68, y: 0.22), CGPoint(x: 0.32, y: 0.50), CGPoint(x: 0.50, y: 0.50), CGPoint(x: 0.68, y: 0.50), CGPoint(x: 0.32, y: 0.78), CGPoint(x: 0.50, y: 0.78), CGPoint(x: 0.68, y: 0.78)]
        default: return [CGPoint(x: 0.5, y: 0.5)]
        }
    }
}

#Preview {
    HStack {
        TileView(tile: MahjongTile(suit: .man, rank: 2, copy: 0))
        TileView(tile: MahjongTile(suit: .pin, rank: 5, copy: 0), isSelected: true)
        TileView(tile: MahjongTile(suit: .sou, rank: 8, copy: 0), displayStyle: .hand)
        TileView(tile: MahjongTile(suit: .honor, rank: 7, copy: 0), isDiscard: true, displayStyle: .river)
    }
    .padding()
    .background(.green)
}
