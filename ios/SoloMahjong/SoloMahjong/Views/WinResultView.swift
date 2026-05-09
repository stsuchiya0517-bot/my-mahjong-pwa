import SwiftUI

struct WinResultView: View {
    let result: WinResult
    let onNext: () -> Void
    @State private var selectedTerm: GlossaryTerm?

    var body: some View {
        ZStack {
            FeltBackground()

            ScrollView {
                VStack(spacing: 16) {
                Text(result.title)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.yellow)

                Text("\(result.winnerName) / \(result.method)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))

                VStack(alignment: .leading, spacing: 10) {
                    resultRow("役", result.yaku.joined(separator: "・"))
                    resultRow("翻", result.hanText)
                    resultRow("符", result.fuText)
                    resultRow("点数", result.scoreText)
                }
                .padding(18)
                .frame(maxWidth: 520)
                .background(.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 9) {
                    Label("得点の内訳", systemImage: "list.bullet.rectangle.fill")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    ForEach(result.scoreBreakdown, id: \.self) { line in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 6, height: 6)
                                .padding(.top, 7)
                            Text(line)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.86))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: 520, alignment: .leading)
                .background(.black.opacity(0.34))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.yellow.opacity(0.28), lineWidth: 1)
                )

                glossaryChips
                    .frame(maxWidth: 520, alignment: .leading)

                Text(result.explanation)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.70))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)

                Button(action: onNext) {
                    Text("次局へ")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .frame(width: 260, height: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                }
                .padding()
            }
        }
        .sheet(item: $selectedTerm) { term in
            NavigationStack {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(term.reading)
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text(term.word)
                            .font(.system(size: 30, weight: .black, design: .rounded))
                    }

                    Text(term.meaning)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
                .padding()
                .navigationTitle("用語")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium])
        }
    }

    private func resultRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
                .frame(width: 42, alignment: .leading)
            Text(value)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
        }
    }

    private var glossaryChips: some View {
        let terms = GlossaryTerm.terms(for: result)
        return VStack(alignment: .leading, spacing: 9) {
            Text("用語をタップして確認")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.66))

            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(terms) { term in
                    Button {
                        selectedTerm = term
                    } label: {
                        VStack(spacing: 0) {
                            Text(term.reading)
                                .font(.system(size: 7, weight: .black, design: .rounded))
                                .foregroundStyle(.white.opacity(0.62))
                            Text(term.word)
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct GlossaryTerm: Identifiable, Hashable {
    var id: String { word }
    let word: String
    let reading: String
    let meaning: String

    static func terms(for result: WinResult) -> [GlossaryTerm] {
        var words = result.yaku + ["翻", "符", "ドラ"]
        if result.scoreBreakdown.joined().contains("供託") { words.append("供託") }
        return words.compactMap { dictionary[$0] ?? dictionary[$0.replacingOccurrences(of: #"ドラ\d+"#, with: "ドラ", options: .regularExpression)] }
            .reduce(into: []) { result, term in
                if !result.contains(term) { result.append(term) }
            }
    }

    private static let dictionary: [String: GlossaryTerm] = [
        "七対子": GlossaryTerm(word: "七対子", reading: "チートイツ", meaning: "同じ牌2枚の組を7組そろえる役です。順子や刻子ではなく、対子だけで作ります。"),
        "門前清自摸和": GlossaryTerm(word: "門前清自摸和", reading: "メンゼンツモ", meaning: "鳴かずに自分で引いた牌で和了する役です。初心者はまず「鳴かずにツモれば1翻」と覚えると楽です。"),
        "リーチ": GlossaryTerm(word: "リーチ", reading: "リーチ", meaning: "鳴いていない状態であと1枚で和了できる時に宣言できる役です。1000点を供託に出します。"),
        "和了形": GlossaryTerm(word: "和了形", reading: "アガリけい", meaning: "4面子1雀頭など、和了できる牌の形です。このアプリでは練習用に簡易役として扱う場合があります。"),
        "翻": GlossaryTerm(word: "翻", reading: "ハン", meaning: "役やドラの価値を数える単位です。翻が増えるほど点数が大きくなります。"),
        "符": GlossaryTerm(word: "符", reading: "フ", meaning: "待ち・面子・雀頭などの細かい形で増える点数要素です。このアプリでは初心者向けに概算表示しています。"),
        "ドラ": GlossaryTerm(word: "ドラ", reading: "ドラ", meaning: "持っていると翻が増えるボーナス牌です。ドラ表示牌そのものではなく、その次の牌がドラになります。"),
        "供託": GlossaryTerm(word: "供託", reading: "キョウタク", meaning: "リーチ宣言などで卓上に置かれた1000点棒です。和了した人が受け取ります。"),
        "国士無双": GlossaryTerm(word: "国士無双", reading: "コクシムソウ", meaning: "1・9牌と字牌をすべて集め、どれか1種類を対子にする役満です。"),
        "四暗刻": GlossaryTerm(word: "四暗刻", reading: "スーアンコウ", meaning: "鳴かずに暗刻を4つ作る役満です。"),
        "大三元": GlossaryTerm(word: "大三元", reading: "ダイサンゲン", meaning: "白・發・中をすべて刻子にする役満です。"),
        "大四喜": GlossaryTerm(word: "大四喜", reading: "ダイスーシー", meaning: "東・南・西・北をすべて刻子にする役満です。"),
        "小四喜": GlossaryTerm(word: "小四喜", reading: "ショウスーシー", meaning: "東・南・西・北のうち3つを刻子、残り1つを雀頭にする役満です。"),
        "字一色": GlossaryTerm(word: "字一色", reading: "ツーイーソー", meaning: "字牌だけで手を作る役満です。"),
        "清老頭": GlossaryTerm(word: "清老頭", reading: "チンロウトウ", meaning: "1・9牌だけで手を作る役満です。"),
        "緑一色": GlossaryTerm(word: "緑一色", reading: "リューイーソー", meaning: "緑色の牌だけで作る役満です。"),
        "九蓮宝燈": GlossaryTerm(word: "九蓮宝燈", reading: "チューレンポウトウ", meaning: "同じ数牌で1112345678999を基本形にする役満です。")
    ]
}

private struct FlowLayout: Layout {
    var spacing: CGFloat
    var rowSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(proposal: ProposedViewSize(width: bounds.width, height: proposal.height), subviews: subviews)
        for item in arrangement.items {
            subviews[item.index].place(at: CGPoint(x: bounds.minX + item.frame.minX, y: bounds.minY + item.frame.minY), proposal: ProposedViewSize(item.frame.size))
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (items: [(index: Int, frame: CGRect)], size: CGSize) {
        let maxWidth = proposal.width ?? 320
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var items: [(Int, CGRect)] = []

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + rowSpacing
                rowHeight = 0
            }
            items.append((index, CGRect(origin: CGPoint(x: x, y: y), size: size)))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (items, CGSize(width: maxWidth, height: y + rowHeight))
    }
}
