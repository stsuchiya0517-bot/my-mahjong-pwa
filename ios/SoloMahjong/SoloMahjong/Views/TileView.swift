import SwiftUI

struct TileView: View {
    let tile: MahjongTile
    var isSelected: Bool = false
    var isDiscard: Bool = false
    var isCompact: Bool = false

    var body: some View {
        Text(tile.shortLabel)
            .font(.system(size: fontSize, weight: .black, design: .rounded))
            .foregroundStyle(tile.displayColor)
            .minimumScaleFactor(0.65)
            .lineLimit(1)
            .frame(width: width, height: height)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(isSelected ? 0.34 : 0.22), radius: isSelected ? 10 : 4, x: 0, y: isSelected ? 8 : 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(isSelected ? Color.yellow : Color.black.opacity(0.08), lineWidth: isSelected ? 4 : 1)
            )
            .offset(y: isSelected ? -14 : 0)
            .scaleEffect(isSelected ? 1.08 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isSelected)
            .accessibilityLabel(tile.label)
    }

    private var width: CGFloat {
        if isCompact { return 28 }
        if isDiscard { return 28 }
        return 48
    }

    private var height: CGFloat {
        if isCompact { return 38 }
        if isDiscard { return 38 }
        return 66
    }

    private var fontSize: CGFloat {
        if isCompact { return 13 }
        if isDiscard { return 13 }
        return 19
    }

    private var cornerRadius: CGFloat {
        isDiscard || isCompact ? 7 : 12
    }
}

#Preview {
    HStack {
        TileView(tile: MahjongTile(suit: .man, rank: 1, copy: 0))
        TileView(tile: MahjongTile(suit: .pin, rank: 5, copy: 0), isSelected: true)
        TileView(tile: MahjongTile(suit: .honor, rank: 7, copy: 0), isDiscard: true)
    }
    .padding()
    .background(.green)
}
