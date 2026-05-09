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
                        RealBambooMark(color: bambooColor(index: index, rank: rank), dense: dense)
                            .position(x: geo.size.width * point.x, y: geo.size.height * point.y)
                    }
                }
            }
        }
    }

    private func bambooColor(index: Int, rank: Int) -> BambooColor {
        switch rank {
        case 5:
            return index == 2 ? .red : .green
        case 6:
            return [ .green, .green, .red, .red, .green, .green ][index]
        case 7:
            return index == 2 ? .red : .green
        case 8:
            return [ .green, .red, .green, .green, .red, .green, .green, .green ][index]
        case 9:
            return [ .green, .red, .green, .green, .green, .green, .green, .red, .green ][index]
        default:
            return .green
        }
    }
}

private enum BambooColor { case green, red, blue }

private struct RealBambooMark: View {
    let color: BambooColor
    let dense: Bool

    var body: some View {
        let h: CGFloat = dense ? 10.8 : 16.2
        let w: CGFloat = dense ? 4.6 : 6.4
        let main: Color = {
            switch color {
            case .green: return Color(red: 0.00, green: 0.38, blue: 0.13)
            case .red: return Color(red: 0.70, green: 0.035, blue: 0.045)
            case .blue: return Color(red: 0.08, green: 0.24, blue: 0.58)
            }
        }()

        return ZStack {
            RoundedRectangle(cornerRadius: w * 0.42, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [main.opacity(0.78), main, main.opacity(0.94)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: w, height: h)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.22))
                        .frame(width: w * 0.22, height: h * 0.80)
                        .padding(.leading, w * 0.18)
                }

            ForEach([-0.30, 0.0, 0.30], id: \.self) { offset in
                BambooNode(width: w * 1.18, dense: dense)
                    .offset(y: h * offset)
            }

            Capsule()
                .fill(Color.black.opacity(0.18))
                .frame(width: w * 0.40, height: h * 0.82)
                .offset(x: w * 0.34)
        }
        .shadow(color: .black.opacity(0.16), radius: 0.7, x: 0, y: 0.55)
    }
}

private struct BambooNode: View {
    let width: CGFloat
    let dense: Bool

    var body: some View {
        Capsule()
            .fill(Color(red: 0.91, green: 0.86, blue: 0.63))
            .frame(width: width, height: dense ? 0.86 : 1.05)
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.20), lineWidth: dense ? 0.25 : 0.35)
            )
    }
}

private struct OneSouFace: View {
    let dense: Bool

    var body: some View {
        let size: CGFloat = dense ? 18.5 : 28
        ZStack {
            PeacockTail(dense: dense)
                .offset(y: -size * 0.12)

            Path { path in
                path.move(to: CGPoint(x: size * 0.42, y: size * 0.30))
                path.addQuadCurve(to: CGPoint(x: size * 0.66, y: size * 0.42), control: CGPoint(x: size * 0.60, y: size * 0.24))
                path.addQuadCurve(to: CGPoint(x: size * 0.56, y: size * 0.74), control: CGPoint(x: size * 0.72, y: size * 0.64))
                path.addQuadCurve(to: CGPoint(x: size * 0.30, y: size * 0.64), control: CGPoint(x: size * 0.36, y: size * 0.76))
                path.addQuadCurve(to: CGPoint(x: size * 0.42, y: size * 0.30), control: CGPoint(x: size * 0.25, y: size * 0.42))
            }
            .fill(Color(red: 0.00, green: 0.36, blue: 0.13))
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: size * 0.42, y: size * 0.30))
                    path.addQuadCurve(to: CGPoint(x: size * 0.66, y: size * 0.42), control: CGPoint(x: size * 0.60, y: size * 0.24))
                    path.addQuadCurve(to: CGPoint(x: size * 0.56, y: size * 0.74), control: CGPoint(x: size * 0.72, y: size * 0.64))
                    path.addQuadCurve(to: CGPoint(x: size * 0.30, y: size * 0.64), control: CGPoint(x: size * 0.36, y: size * 0.76))
                    path.addQuadCurve(to: CGPoint(x: size * 0.42, y: size * 0.30), control: CGPoint(x: size * 0.25, y: size * 0.42))
                }
                .stroke(Color.black.opacity(0.62), lineWidth: dense ? 0.7 : 1.0)
            )

            Circle()
                .fill(Color(red: 0.72, green: 0.04, blue: 0.04))
                .frame(width: size * 0.15, height: size * 0.15)
                .position(x: size * 0.49, y: size * 0.45)

            Circle()
                .fill(Color.black.opacity(0.84))
                .frame(width: size * 0.055, height: size * 0.055)
                .position(x: size * 0.58, y: size * 0.40)

            Capsule()
                .fill(Color(red: 0.72, green: 0.04, blue: 0.04))
                .frame(width: size * 0.17, height: size * 0.05)
                .rotationEffect(.degrees(-18))
                .position(x: size * 0.69, y: size * 0.38)
        }
        .frame(width: size, height: size)
    }
}

private struct PeacockTail: View {
    let dense: Bool

    var body: some View {
        let size: CGFloat = dense ? 18.5 : 28
        ZStack {
            ForEach(0..<7, id: \.self) { index in
                let angle = Double(index) * 18 - 54
                Capsule()
                    .fill(index == 3 ? Color(red: 0.70, green: 0.04, blue: 0.04) : Color(red: 0.00, green: 0.38, blue: 0.13))
                    .frame(width: dense ? 2.8 : 4.2, height: dense ? 10.0 : 15.0)
                    .overlay(
                        Capsule()
                            .stroke(Color(red: 0.90, green: 0.84, blue: 0.58).opacity(0.55), lineWidth: dense ? 0.35 : 0.5)
                    )
                    .offset(y: -size * 0.18)
                    .rotationEffect(.degrees(angle))
            }
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
