import SwiftUI

enum TileSuit: String, CaseIterable, Codable {
    case man
    case pin
    case sou
    case honor

    var sortOrder: Int {
        switch self {
        case .man: return 0
        case .pin: return 1
        case .sou: return 2
        case .honor: return 3
        }
    }
}

struct MahjongTile: Identifiable, Hashable, Codable {
    let id: UUID
    let suit: TileSuit
    let rank: Int
    let copy: Int

    init(id: UUID = UUID(), suit: TileSuit, rank: Int, copy: Int) {
        self.id = id
        self.suit = suit
        self.rank = rank
        self.copy = copy
    }

    var label: String {
        switch suit {
        case .man:
            return "\(rank)萬"
        case .pin:
            return "\(rank)筒"
        case .sou:
            return "\(rank)索"
        case .honor:
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
    }

    var shortLabel: String {
        switch suit {
        case .man: return "\(rank)萬"
        case .pin: return "\(rank)筒"
        case .sou: return "\(rank)索"
        case .honor: return label
        }
    }

    var displayColor: Color {
        switch suit {
        case .man:
            return .red
        case .pin:
            return .blue
        case .sou:
            return .green
        case .honor:
            return rank >= 5 ? .red : .primary
        }
    }

    var sortKey: String {
        "\(suit.sortOrder)-\(rank)-\(copy)"
    }
}

extension Array where Element == MahjongTile {
    func sortedForHand() -> [MahjongTile] {
        sorted { lhs, rhs in
            if lhs.suit.sortOrder != rhs.suit.sortOrder {
                return lhs.suit.sortOrder < rhs.suit.sortOrder
            }
            if lhs.rank != rhs.rank {
                return lhs.rank < rhs.rank
            }
            return lhs.copy < rhs.copy
        }
    }
}
