import Foundation
import SwiftUI

struct WinResult: Identifiable, Equatable {
    let id = UUID()
    let winnerName: String
    let title: String
    let method: String
    let yaku: [String]
    let hanText: String
    let fuText: String
    let scoreText: String
    let explanation: String
}

@MainActor
final class MahjongGameViewModel: ObservableObject {
    @Published var players: [MahjongPlayer] = []
    @Published var wall: [MahjongTile] = []
    @Published var selectedTileID: MahjongTile.ID?
    @Published var currentPlayerIndex: Int = 0
    @Published var message: String = "新しい対局を開始します。"
    @Published var lastDiscard: MahjongTile?
    @Published var lastDiscardPlayerIndex: Int?
    @Published var roundState = MahjongRoundState()
    @Published var turnNumber: Int = 1
    @Published var isBusy: Bool = false
    @Published var actionLog: [String] = []
    @Published var winningResult: WinResult?
    @Published var lastTappedTileID: MahjongTile.ID?
    @Published var lastTapDate: Date = .distantPast

    var roundTitle: String { roundState.title }

    var user: MahjongPlayer { players[0] }

    var selectedTile: MahjongTile? {
        guard let selectedTileID else { return nil }
        return players.first?.hand.first(where: { $0.id == selectedTileID })
    }

    var canDiscard: Bool {
        selectedTile != nil && currentPlayerIndex == 0 && !isBusy && winningResult == nil
    }

    var canTsumoWin: Bool {
        guard players.indices.contains(0), currentPlayerIndex == 0, !isBusy else { return false }
        return evaluateWin(for: players[0].hand, playerIndex: 0, method: "ツモ") != nil
    }

    var shantenText: String {
        guard players.indices.contains(0) else { return "--向聴" }
        let count = tileCounts(players[0].hand)
        let pairs = count.values.filter { $0 >= 2 }.count
        let meldLike = count.values.filter { $0 >= 3 }.count
        let estimate = max(0, 6 - pairs - meldLike * 2)
        return "\(estimate)向聴"
    }

    init() {
        startNewGame()
    }

    func startMatch() {
        roundState = MahjongRoundState()
        startRound(resetScores: true)
    }

    func startNewGame() {
        startMatch()
    }

    func advanceToNextRound() {
        roundState.advanceDealer()
        startRound(resetScores: false)
    }

    private func startRound(resetScores: Bool) {
        let oldScores = players.map(\.score)
        players = [
            MahjongPlayer(name: "あなた"),
            MahjongPlayer(name: "CPU右"),
            MahjongPlayer(name: "CPU対面"),
            MahjongPlayer(name: "CPU左")
        ]
        for index in players.indices {
            players[index].isDealer = index == roundState.dealerIndex
            if !resetScores, oldScores.indices.contains(index) {
                players[index].score = oldScores[index]
            }
        }
        wall = Self.makeWall().shuffled()
        selectedTileID = nil
        currentPlayerIndex = 0
        message = "配牌しました。牌を選んで捨てましょう。"
        lastDiscard = nil
        lastDiscardPlayerIndex = nil
        winningResult = nil
        turnNumber = 1
        lastTappedTileID = nil
        lastTapDate = .distantPast
        actionLog.removeAll()
        dealInitialHands()
        log("\(roundState.detailTitle)開始。\(players[roundState.dealerIndex].name)が親です。")
    }

    func select(tile: MahjongTile) {
        guard currentPlayerIndex == 0, !isBusy, winningResult == nil else { return }
        withAnimation(.spring(response: 0.22, dampingFraction: 0.74)) {
            selectedTileID = tile.id
        }
        message = "\(tile.label)を選択中。右の『捨てる』で打牌します。"
    }

    func handleHandTap(_ tile: MahjongTile) {
        guard currentPlayerIndex == 0, !isBusy, winningResult == nil else { return }
        let now = Date()
        if lastTappedTileID == tile.id, now.timeIntervalSince(lastTapDate) < 0.34 {
            selectedTileID = tile.id
            discardSelectedTile()
            lastTappedTileID = nil
            lastTapDate = .distantPast
        } else {
            lastTappedTileID = tile.id
            lastTapDate = now
            select(tile: tile)
        }
    }

    func discardSelectedTile() {
        guard let selectedTileID,
              currentPlayerIndex == 0,
              !isBusy,
              winningResult == nil,
              let index = players[0].hand.firstIndex(where: { $0.id == selectedTileID }) else {
            return
        }

        withAnimation(.easeInOut(duration: 0.22)) {
            let tile = players[0].hand.remove(at: index)
            players[0].discards.append(tile)
            lastDiscard = tile
            lastDiscardPlayerIndex = 0
            self.selectedTileID = nil
            lastTappedTileID = nil
            message = "あなたは\(tile.label)を捨てました。"
            log("あなた：\(tile.label)を打牌")
        }

        if tryCpuPonCall(on: lastDiscard, discardedBy: 0) {
            return
        }

        advanceToCPU()
    }

    func cancelSelection() {
        selectedTileID = nil
        lastTappedTileID = nil
        message = "牌を選んでください。"
    }

    func drawForUserIfNeeded() {
        guard currentPlayerIndex == 0, !isBusy, winningResult == nil else { return }
        let handCount = players[0].hand.count
        if handCount % 3 == 1, let drawn = drawTile() {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                players[0].hand.append(drawn)
                players[0].hand = players[0].hand.sortedForHand()
            }
            message = "\(drawn.label)をツモりました。捨てる牌を選んでください。"
            log("あなた：\(drawn.label)をツモ")
        }
    }

    func winByTsumo() {
        guard currentPlayerIndex == 0, !isBusy else { return }
        guard let result = evaluateWin(for: players[0].hand, playerIndex: 0, method: "ツモ") else {
            message = "まだ和了形ではありません。捨てる牌を選んでください。"
            return
        }
        winningResult = result
        applyWinScore(playerIndex: 0, method: "ツモ")
        message = "\(result.title)"
        log("あなた：\(result.title) / \(result.yaku.joined(separator: ", "))")
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

    private func tryCpuPonCall(on discardedTile: MahjongTile?, discardedBy fromPlayerIndex: Int) -> Bool {
        guard let discardedTile, winningResult == nil else { return false }

        for cpuIndex in 1..<players.count {
            let matchingIndexes = players[cpuIndex].hand.indices.filter {
                players[cpuIndex].hand[$0].suit == discardedTile.suit &&
                players[cpuIndex].hand[$0].rank == discardedTile.rank
            }

            guard matchingIndexes.count >= 2 else { continue }

            // 練習用：毎回鳴くと単調なので、刻子価値が高い牌だけを優先して一部自動ポン。
            let isValuable = discardedTile.suit == .honor || discardedTile.rank == 1 || discardedTile.rank == 9 || Bool.random()
            guard isValuable else { continue }

            let first = matchingIndexes[0]
            let second = matchingIndexes[1]
            let removed = [players[cpuIndex].hand[first], players[cpuIndex].hand[second]]

            players[cpuIndex].hand.remove(at: max(first, second))
            players[cpuIndex].hand.remove(at: min(first, second))
            players[cpuIndex].melds.append(
                MahjongMeld(
                    type: .pon,
                    tiles: [removed[0], removed[1], discardedTile].sortedForHand(),
                    calledTile: discardedTile,
                    fromPlayerIndex: fromPlayerIndex
                )
            )

            players[fromPlayerIndex].discards.removeAll { $0.id == discardedTile.id }
            lastDiscard = discardedTile
            lastDiscardPlayerIndex = cpuIndex
            currentPlayerIndex = cpuIndex
            message = "\(players[cpuIndex].name)が\(discardedTile.label)をポンしました。"
            log("\(players[cpuIndex].name)：\(discardedTile.label)をポン")

            Task {
                isBusy = true
                players[cpuIndex].isThinking = true
                try? await Task.sleep(nanoseconds: 500_000_000)
                cpuDiscardAfterCall(cpuIndex)
                players[cpuIndex].isThinking = false
                isBusy = false
                currentPlayerIndex = 0
                turnNumber += 1
                drawForUserIfNeeded()
            }
            return true
        }

        return false
    }

    private func cpuDiscardAfterCall(_ index: Int) {
        guard players.indices.contains(index), !players[index].hand.isEmpty else { return }
        let discardIndex = chooseDiscardIndex(for: players[index].hand)
        withAnimation(.easeInOut(duration: 0.22)) {
            let tile = players[index].hand.remove(at: discardIndex)
            players[index].discards.append(tile)
            lastDiscard = tile
            lastDiscardPlayerIndex = index
            message = "\(players[index].name)は\(tile.label)を捨てました。"
            log("\(players[index].name)：\(tile.label)を打牌")
        }
    }

    private func advanceToCPU() {
        Task {
            isBusy = true
            for cpuIndex in 1...3 {
                guard winningResult == nil else { break }
                currentPlayerIndex = cpuIndex
                players[cpuIndex].isThinking = true
                message = "\(players[cpuIndex].name)が考え中…"
                try? await Task.sleep(nanoseconds: 420_000_000)
                cpuTakeTurn(cpuIndex)
                players[cpuIndex].isThinking = false
                try? await Task.sleep(nanoseconds: 220_000_000)
            }
            guard winningResult == nil else {
                isBusy = false
                return
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

        if let result = evaluateWin(for: players[index].hand, playerIndex: index, method: "ツモ") {
            winningResult = result
            applyWinScore(playerIndex: index, method: "ツモ")
            message = "\(players[index].name)がツモ和了しました。"
            log("\(players[index].name)：\(result.title)")
            return
        }

        guard !players[index].hand.isEmpty else { return }
        let discardIndex = chooseDiscardIndex(for: players[index].hand)

        withAnimation(.easeInOut(duration: 0.22)) {
            let tile = players[index].hand.remove(at: discardIndex)
            players[index].discards.append(tile)
            maybeDeclareReach(playerIndex: index, tile: tile)
            lastDiscard = tile
            lastDiscardPlayerIndex = index
            message = "\(players[index].name)は\(tile.label)を捨てました。"
            log("\(players[index].name)：\(tile.label)を打牌")
        }
    }

    private func chooseDiscardIndex(for hand: [MahjongTile]) -> Int {
        let ranked = hand.enumerated().map { pair -> (offset: Int, score: Int) in
            let tile = pair.element
            var score = 0
            if tile.suit == .honor { score += 8 }
            if tile.rank == 1 || tile.rank == 9 { score += 5 }
            let sameCount = hand.filter { $0.suit == tile.suit && $0.rank == tile.rank }.count
            if sameCount >= 2 { score -= 9 }
            if tile.suit != .honor {
                if hand.contains(where: { $0.suit == tile.suit && $0.rank == tile.rank - 1 }) { score -= 3 }
                if hand.contains(where: { $0.suit == tile.suit && $0.rank == tile.rank + 1 }) { score -= 3 }
            }
            return (pair.offset, score)
        }
        return ranked.max(by: { $0.score < $1.score })?.offset ?? hand.indices.randomElement() ?? 0
    }

    private func drawTile() -> MahjongTile? {
        guard !wall.isEmpty else {
            message = "流局です。次局へ進みます。"
            roundState.honba += 1
            Task {
                try? await Task.sleep(nanoseconds: 700_000_000)
                advanceToNextRound()
            }
            return nil
        }
        return wall.removeLast()
    }

    private func maybeDeclareReach(playerIndex: Int, tile: MahjongTile) {
        guard players.indices.contains(playerIndex), !players[playerIndex].isReach else { return }
        guard players[playerIndex].melds.isEmpty, turnNumber > 4, Bool.random() else { return }
        players[playerIndex].isReach = true
        players[playerIndex].reachDiscardID = tile.id
        players[playerIndex].score -= 1000
        roundState.riichiSticks += 1
        log("\(players[playerIndex].name)：リーチ")
    }

    private func applyWinScore(playerIndex: Int, method: String) {
        guard players.indices.contains(playerIndex) else { return }
        let gain = method == "ツモ" ? 2000 + roundState.riichiSticks * 1000 : 1000
        players[playerIndex].score += gain
        roundState.riichiSticks = 0
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

extension MahjongGameViewModel {
    func evaluateWin(for hand: [MahjongTile], playerIndex: Int, method: String) -> WinResult? {
        guard hand.count % 3 == 2 else { return nil }
        var yakuman: [String] = []
        let counts = tileCounts(hand)

        if isKokushi(counts) { yakuman.append("国士無双") }
        if isSuuAnkou(counts) { yakuman.append("四暗刻") }
        if isDaisangen(counts) { yakuman.append("大三元") }
        if isDaisuushi(counts) { yakuman.append("大四喜") }
        else if isShousuushi(counts) { yakuman.append("小四喜") }
        if isTsuuiisou(hand) { yakuman.append("字一色") }
        if isChinroutou(hand) { yakuman.append("清老頭") }
        if isRyuuiisou(hand) { yakuman.append("緑一色") }
        if isChuuren(hand) { yakuman.append("九蓮宝燈") }
        if playerIndex == 0, players[0].isDealer, turnNumber == 1, players[0].discards.isEmpty, method == "ツモ" {
            yakuman.append("天和")
        }

        let sevenPairs = isSevenPairs(counts)
        let standard = isStandardWinning(counts)
        let isWinning = !yakuman.isEmpty || sevenPairs || standard
        guard isWinning else { return nil }

        let dealer = players.indices.contains(playerIndex) && players[playerIndex].isDealer
        let winnerName = players.indices.contains(playerIndex) ? players[playerIndex].name : "和了者"

        if !yakuman.isEmpty {
            let multiplier = yakuman.count
            let base = dealer ? 48000 : 32000
            return WinResult(
                winnerName: winnerName,
                title: multiplier >= 2 ? "ダブル以上役満！" : "役満和了！",
                method: method,
                yaku: yakuman,
                hanText: "役満 × \(multiplier)",
                fuText: "役満は符計算なし",
                scoreText: "\(base * multiplier)点",
                explanation: "通常の翻・符ではなく、成立した役満で点数を計算しています。"
            )
        }

        var normalYaku: [String] = []
        if sevenPairs { normalYaku.append("七対子") }
        if method == "ツモ" { normalYaku.append("門前清自摸和") }
        if normalYaku.isEmpty { normalYaku.append("和了形") }
        let han = max(1, normalYaku.count)
        let fu = sevenPairs ? 25 : 30
        let score = dealer ? 1500 * han : 1000 * han

        return WinResult(
            winnerName: winnerName,
            title: "和了！",
            method: method,
            yaku: normalYaku,
            hanText: "\(han)翻",
            fuText: "\(fu)符（練習用概算）",
            scoreText: "約\(score)点",
            explanation: "通常役は練習用の簡易計算です。役満は個別判定を優先しています。"
        )
    }

    func tileKey(_ tile: MahjongTile) -> Int {
        tile.suit.sortOrder * 10 + tile.rank
    }

    func tileCounts(_ tiles: [MahjongTile]) -> [Int: Int] {
        var counts: [Int: Int] = [:]
        for tile in tiles { counts[tileKey(tile), default: 0] += 1 }
        return counts
    }

    func isKokushi(_ counts: [Int: Int]) -> Bool {
        let required = [1, 9, 11, 19, 21, 29, 31, 32, 33, 34, 35, 36, 37]
        guard required.allSatisfy({ (counts[$0] ?? 0) >= 1 }) else { return false }
        return required.contains { (counts[$0] ?? 0) >= 2 }
    }

    func isSevenPairs(_ counts: [Int: Int]) -> Bool {
        counts.values.filter { $0 == 2 }.count == 7
    }

    func isStandardWinning(_ counts: [Int: Int]) -> Bool {
        for (key, count) in counts where count >= 2 {
            var copy = counts
            copy[key, default: 0] -= 2
            if copy[key] == 0 { copy.removeValue(forKey: key) }
            if canFormMelds(copy) { return true }
        }
        return false
    }

    func canFormMelds(_ counts: [Int: Int]) -> Bool {
        guard let first = counts.keys.sorted().first(where: { (counts[$0] ?? 0) > 0 }) else { return true }
        var counts = counts

        if (counts[first] ?? 0) >= 3 {
            counts[first, default: 0] -= 3
            if counts[first] == 0 { counts.removeValue(forKey: first) }
            if canFormMelds(counts) { return true }
            counts[first, default: 0] += 3
        }

        let suit = first / 10
        let rank = first % 10
        if suit < 3, rank <= 7, (counts[first + 1] ?? 0) > 0, (counts[first + 2] ?? 0) > 0 {
            counts[first, default: 0] -= 1
            counts[first + 1, default: 0] -= 1
            counts[first + 2, default: 0] -= 1
            [first, first + 1, first + 2].forEach { if counts[$0] == 0 { counts.removeValue(forKey: $0) } }
            if canFormMelds(counts) { return true }
        }

        return false
    }

    func isSuuAnkou(_ counts: [Int: Int]) -> Bool {
        let triplets = counts.values.filter { $0 >= 3 }.count
        let pairs = counts.values.filter { $0 >= 2 }.count
        return triplets >= 4 && pairs >= 1
    }

    func isDaisangen(_ counts: [Int: Int]) -> Bool {
        (counts[35] ?? 0) >= 3 && (counts[36] ?? 0) >= 3 && (counts[37] ?? 0) >= 3
    }

    func isDaisuushi(_ counts: [Int: Int]) -> Bool {
        [31, 32, 33, 34].allSatisfy { (counts[$0] ?? 0) >= 3 }
    }

    func isShousuushi(_ counts: [Int: Int]) -> Bool {
        let winds = [31, 32, 33, 34]
        let triplets = winds.filter { (counts[$0] ?? 0) >= 3 }.count
        let pairs = winds.filter { (counts[$0] ?? 0) >= 2 }.count
        return triplets == 3 && pairs >= 4
    }

    func isTsuuiisou(_ hand: [MahjongTile]) -> Bool {
        hand.allSatisfy { $0.suit == .honor }
    }

    func isChinroutou(_ hand: [MahjongTile]) -> Bool {
        hand.allSatisfy { $0.suit != .honor && ($0.rank == 1 || $0.rank == 9) }
    }

    func isRyuuiisou(_ hand: [MahjongTile]) -> Bool {
        hand.allSatisfy { tile in
            if tile.suit == .sou { return [2, 3, 4, 6, 8].contains(tile.rank) }
            if tile.suit == .honor { return tile.rank == 6 }
            return false
        }
    }

    func isChuuren(_ hand: [MahjongTile]) -> Bool {
        let suits = Set(hand.map { $0.suit })
        guard suits.count == 1, let suit = suits.first, suit != .honor else { return false }
        var ranks: [Int: Int] = [:]
        for tile in hand { ranks[tile.rank, default: 0] += 1 }
        guard (ranks[1] ?? 0) >= 3, (ranks[9] ?? 0) >= 3 else { return false }
        return (2...8).allSatisfy { (ranks[$0] ?? 0) >= 1 }
    }
}
