import SwiftUI

struct TableEventBannerView: View {
    let message: String
    let tone: TableEventTone

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 24)
                .background(iconColor.opacity(0.16))
                .clipShape(Circle())

            Text(message)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.black.opacity(0.62))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(iconColor.opacity(0.44), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.30), radius: 12, x: 0, y: 5)
        .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.98)))
    }

    private var iconName: String {
        switch tone {
        case .neutral: return "circle.grid.2x2.fill"
        case .discard: return "arrow.up.right.circle.fill"
        case .draw: return "sparkles"
        case .call: return "speaker.wave.2.fill"
        case .thinking: return "brain.head.profile"
        case .win: return "crown.fill"
        }
    }

    private var iconColor: Color {
        switch tone {
        case .neutral: return .white.opacity(0.76)
        case .discard: return Color(red: 0.84, green: 0.95, blue: 1.0)
        case .draw: return Color(red: 0.54, green: 1.0, blue: 0.50)
        case .call: return Color(red: 1.0, green: 0.72, blue: 0.24)
        case .thinking: return Color(red: 0.98, green: 0.86, blue: 0.24)
        case .win: return Color(red: 1.0, green: 0.28, blue: 0.28)
        }
    }
}
