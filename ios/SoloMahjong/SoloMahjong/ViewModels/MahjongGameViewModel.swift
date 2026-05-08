import Foundation
import SwiftUI

@MainActor
final class MahjongGameViewModel: ObservableObject {
    @Published var players: [MahjongPlayer] = []
    @Published var wall: [MahjongTile] = []
    @Published var selectedTileID: MahjongTile.ID?
    @Published var currentPlayerIndex: Int = 0
    @Published var message: String = "新しい対局を開始します。"
    @Published var lastDiscard: MahjongTile?
    @Published var roundTitle: String = "東1局"
    @Published var turnNumber: Int = 1
    @Published var isBusy: Bool = false
    @Published var actionLog: [String] = []

    var user: MahjongPlayer { players[0] }
    var selectedTile: MahjongTile? {
        guard let selectedTileID else { return nil }
        return players.first?.hand.first(where: { $0.id == selectedTileID })
    }

    var canDiscard: Bool {
        selectedTile != nil && currentPlayerIndex == 0 && !isBusy
    }

    init() {
        startNewGame()
    }

    func startNewGame() {
        players = [
            MahjongPlayer(name: "あなた", isDealer: true),
            MahjongPlayer(name: "CPU右"),
            MahjongPlayer(name: "CPU対面"),
            MahjongPlayer(name: "CPU左")
        ]
        wall = Self.makeWall().shuffled()
        selectedTileID = nil
        currentPlayerIndex = 0
        message = "配牌しました。牌を選んで捨てましょう。"
        lastDiscard = nil
        roundTitle = "東1局"
        turnNumber = 1
        actionLog.removeAll()
        dealInitialHands()
        log("東1局開始。あなたが親です。")
    }

    func select(tile: MahjongTile) {
        guard currentPlayerIndex == 0, !isBusy else { return }
        withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) {
            selectedTileID = tile.id
        }
        message = "\(tile.label)を選択中。下の「捨てる」で打牌します。"
    }

    func discardSelectedTile() {
        guard let selectedTileID,
              currentPlayerIndex == 0,
              !isBusy,
              let index = players[0].hand.firstIndex(where: { $0.id == selectedTileID }) else {
            return
        }
        let tile = players[0].hand.remove(at: index)
        players[0].discards.append(tile)
        lastDiscard = tile
        self.selectedTileID = nil
        message = "あなたは\(tile.label)を捨てました。"
        log("あなた：\(tile.label)を打牌")
        advanceToCPU()
    }

    func cancelSelection() {
        selectedTileID = nil
        message = "牌を選んでください。"
    }

    func drawForUserIfNeeded() {
        guard currentPlayerIndex == 0, !isBusy else { return }
        let handCount = players[0].hand.count
        if handCount % 3 == 1, let drawn = drawTile() {
            players[0].hand.append(drawn)
            players[0].hand = players[0].hand.sortedForHand()
            message = "\(drawn.label)をツモりました。捨てる牌を選んでください。"
            log("あなた：\(drawn.label)をツモ")
        }
    }

    private func dealInitialHands() {
        for playerIndex in players.indices {
            for _ in 0..<13 {
                if let tile = drawTile() {
                    players[playerIndex].hand.append(tile)
                }
            }
            players[playerIndex].hand = players[playerIndex].hand.sortedForHand()
        }
        if let tile = drawTile() {
            players[0].hand.append(tile)
            players[0].hand = players[0].hand.sortedForHand()
        }
    }

    private func advanceToCPU() {
        Task {
            isBusy = true
            for cpuIndex in 1...3 {
                currentPlayerIndex = cpuIndex
                players[cpuIndex].isThinking = true
                message = "\(players[cpuIndex].name)が考え中…"
                try? await Task.sleep(nanoseconds: 520_000_000)
                cpuTakeTurn(cpuIndex)
                players[cpuIndex].isThinking = false
                try? await Task.sleep(nanoseconds: 260_000_000)
            }
            currentPlayerIndex = 0
            turnNumber += 1
            isBusy = false
            drawForUserIfNeeded()
        }
    }

    private func cpuTakeTurn(_ index: Int) {
        if let drawn = drawTile() {
            players[index].hand.append(drawn)
        }
        players[index].hand = players[index].hand.sortedForHand()
        guard !players[index].hand.isEmpty else { return }

        let discardIndex = chooseDiscardIndex(for: players[index].hand)
        let tile = players[index].hand.remove(at: discardIndex)
        players[index].discards.append(tile)
        lastDiscard = tile
        message = "\(players[index].name)は\(tile.label)を捨てました。"
        log("\(players[index].name)：\(tile.label)を打牌")
    }

    private func chooseDiscardIndex(for hand: [MahjongTile]) -> Int {
        let ranked = hand.enumerated().map { pair -> (offset: Int, score: Int) in
            let tile = pair.element
            var score = 0
            if tile.suit == .honor { score += 8 }
            if tile.rank == 1 || tile.rank == 9 { score += 5 }
            let sameCount = hand.filter { $0.suit == tile.suit && $0.rank == tile.rank }.count
            if sameCount >= 2 { score -= 9 }
            if hand.contains(where: { $0.suit == tile.suit && $0.rank == tile.rank - 1 }) { score -= 3 }
            if hand.contains(where: { $0.suit == tile.suit && $0.rank == tile.rank + 1 }) { score -= 3 }
            return (pair.offset, score)
        }
        return ranked.max(by: { $0.score < $1.score })?.offset ?? hand.indices.randomElement() ?? 0
    }

    private func drawTile() -> MahjongTile? {
        guard !wall.isEmpty else {
            message = "流局です。新しい局を開始してください。"
            return nil
        }
        return wall.removeLast()
    }

    private func log(_ text: String) {
        actionLog.insert(text, at: 0)
        if actionLog.count > 40 { actionLog.removeLast() }
    }

    static func makeWall() -> [MahjongTile] {
        var tiles: [MahjongTile] = []
        for suit in [TileSuit.man, .pin, .sou] {
            for rank in 1...9 {
                for copy in 0..<4 {
                    tiles.append(MahjongTile(suit: suit, rank: rank, copy: copy))
                }
            }
        }
        for rank in 1...7 {
            for copy in 0..<4 {
                tiles.append(MahjongTile(suit: .honor, rank: rank, copy: copy))
            }
        }
        return tiles
    }
}
