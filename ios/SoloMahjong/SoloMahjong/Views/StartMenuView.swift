import SwiftUI

struct StartMenuView: View {
    let onStart: () -> Void
    let onHowToPlay: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.19, blue: 0.12),
                    Color(red: 0.01, green: 0.06, blue: 0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 12) {
                    Text("ひとり麻雀")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("iPhoneで遊びやすい\n麻雀練習アプリ")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    Button(action: onStart) {
                        Text("練習を始める")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Button(action: onHowToPlay) {
                        Text("遊び方を見る")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 8) {
                    menuPoint("牌をタップして捨てる")
                    menuPoint("CPUの動きを見ながら流れを覚える")
                    menuPoint("初心者向けの練習用")
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    private func menuPoint(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.yellow)
            Text(text)
                .foregroundStyle(.white)
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
    }
}

#Preview {
    StartMenuView(onStart: {}, onHowToPlay: {})
}
