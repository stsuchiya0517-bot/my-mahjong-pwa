import Foundation

struct MahjongPlayer: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var score: Int = 25000
    var hand: [MahjongTile] = []
    var discards: [MahjongTile] = []
    var isDealer: Bool = false
    var isThinking: Bool = false
    var isReach: Bool = false

    var handCountText: String {
        "手牌 \(hand.count)枚"
    }
}
