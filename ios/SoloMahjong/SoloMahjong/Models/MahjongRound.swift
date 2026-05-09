import Foundation

enum RoundWind: String, Codable, CaseIterable {
    case east = "東"
    case south = "南"
}

struct MahjongRoundState: Codable, Hashable {
    var wind: RoundWind = .east
    var handNumber: Int = 1
    var honba: Int = 0
    var riichiSticks: Int = 0
    var dealerIndex: Int = 0

    var title: String {
        "\(wind.rawValue)\(handNumber)局"
    }

    var detailTitle: String {
        "\(title) \(honba)本場"
    }

    mutating func advanceDealer() {
        dealerIndex = (dealerIndex + 1) % 4
        handNumber += 1
        honba = 0
        if handNumber > 4 {
            if wind == .east {
                wind = .south
                handNumber = 1
            } else {
                wind = .east
                handNumber = 1
                dealerIndex = 0
            }
        }
    }
}
