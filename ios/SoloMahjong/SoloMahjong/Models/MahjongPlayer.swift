import Foundation

enum MahjongMeldType: String, Hashable {
    case chi = "チー"
    case pon = "ポン"
    case kan = "カン"
}

struct MahjongMeld: Identifiable, Hashable {
    let id = UUID()
    var type: MahjongMeldType
    var tiles: [MahjongTile]
    var calledTile: MahjongTile?
    var fromPlayerIndex: Int?
}

struct MahjongPlayer: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var score: Int = 25000
    var hand: [MahjongTile] = []
    var discards: [MahjongTile] = []
    var melds: [MahjongMeld] = []
    var isDealer: Bool = false
    var isThinking: Bool = false
    var isReach: Bool = false
    var reachDiscardID: MahjongTile.ID?

    var handCountText: String {
        "手牌 \(hand.count)枚"
    }
}
