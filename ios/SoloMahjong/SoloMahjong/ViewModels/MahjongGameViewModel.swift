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
    let scoreBreakdown: [String]
    let explanation: String
}

struct RoundNotice: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let body: String
    let detail: String
}

enum MatchMode: String, CaseIterable, Identifiable {
    case eastOnly = "東風戦"
    case eastSouth = "半荘戦"

    var id: String { rawValue }
    var finalWind: RoundWind { self == .eastOnly ? .east : .south }
}

struct MatchStanding: Identifiable, Equatable {
    let id = UUID()
    let rank: Int
    let playerName: String
    let score: Int
}

struct MatchResult: Identifiable, Equatable {
    let id = UUID()
    let modeName: String
    let standings: [MatchStanding]
}

enum TableEventTone {
    case neutral
    case discard
    case draw
    case call
    case thinking
    case win
}

struct DiscardRecommendation: Identifiable, Hashable {
    var id: MahjongTile.ID { tile.id }
    let tile: MahjongTile
    let score: Int
    let reason: String
    let detail: String
}

enum UserCallAction: String, Identifiable, CaseIterable {
    case ron = "ロン"
    case chi = "チー"
    case pon = "ポン"
    case kan = "カン"

    var id: String { rawValue }
}

struct PendingUserCall: Identifiable, Equatable {
    let id = UUID()
    let tile: MahjongTile
    let fromPlayerIndex: Int
    let actions: [UserCallAction]
}

@MainActor
final class MahjongGameViewModel: ObservableObject {
    @Published var players: [MahjongPlayer] = []
    @Published var wall: [MahjongTile] = []
    @Published var doraIndicators: [MahjongTile] = []
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
    @Published var roundNotice: RoundNotice?
    @Published var matchResult: MatchResult?
    @Published var matchMode: MatchMode = .eastSouth
    @Published var lastTappedTileID: MahjongTile.ID?
    @Published var lastTapDate: Date = .distantPast
    @Published var pendingUserCall: PendingUserCall?
    @Published var isDeclaringReach: Bool = false
    @Published var forbiddenDiscardKeys: Set<Int> = []
    @Published var isAfterUserCall: Bool = false
    @Published var forcedDiscardTileID: MahjongTile.ID?
    @Published var isRinshanDraw: Bool = false

    private var assistCacheSignature: String = ""
    private var assistCacheRecommendations: [DiscardRecommendation] = []
    private var yakuAimCacheSignature: String = ""
    private var yakuAimCacheText: String = "狙い役を分析中"
    private var shantenMemo: [String: Int] = [:]

    var roundTitle: String { roundState.title }
    var doraTiles: [MahjongTile] { doraIndicators.map(\.doraSuccessor) }

    var user: MahjongPlayer { players[0] }

    var selectedTile: MahjongTile? {
        guard let selectedTileID else { return nil }
        return players.first?.hand.first(where: { $0.id == selectedTileID })
    }

    var canDiscard: Bool {
        guard let selectedTile else { return false }
        return currentPlayerIndex == 0 && !isBusy && winningResult == nil && canSelectForDiscard(selectedTile)
    }

    var canReach: Bool {
        guard players.indices.contains(0), currentPlayerIndex == 0, !isBusy, pendingUserCall == nil else { return false }
        return canDeclareReach(from: players[0].hand)
    }

    var canClosedKan: Bool {
        guard players.indices.contains(0), currentPlayerIndex == 0, !isBusy, pendingUserCall == nil else { return false }
        return !players[0].isReach && firstClosedKanTiles() != nil
    }

    var reachWaitText: String? {
        guard players.indices.contains(0), players[0].isReach else { return nil }
        let waits = waitTiles(for: players[0].hand)
        guard !waits.isEmpty else { return nil }
        return waits.map(\.label).joined(separator: "・")
    }

    func reachWaitText(afterDiscarding tile: MahjongTile) -> String? {
        let waits = waitTilesAfterDiscarding(tile)
        guard !waits.isEmpty else { return nil }
        return waits.map(\.label).joined(separator: "・")
    }

    func canSelectForDiscard(_ tile: MahjongTile) -> Bool {
        guard currentPlayerIndex == 0, !isBusy, pendingUserCall == nil, winningResult == nil else { return false }
        if players.indices.contains(0), players[0].isReach, canTsumoWin {
            return false
        }
        if let forcedDiscardTileID {
            return tile.id == forcedDiscardTileID
        }
        if isDeclaringReach {
            return isReachDiscardCandidate(tile)
        }
        return !forbiddenDiscardKeys.contains(tileKey(tile))
    }

    var canTsumoWin: Bool {
        guard players.indices.contains(0), currentPlayerIndex == 0, !isBusy else { return false }
        return evaluateWin(for: players[0].hand, playerIndex: 0, method: "ツモ") != nil
    }

    var shantenText: String {
        guard players.indices.contains(0) else { return "--向聴" }
        let shanten = currentShanten(for: players[0].hand)
        if shanten < 0 { return "和了形" }
        if shanten == 0 { return "聴牌" }
        return "\(shanten)向聴"
    }

    var eventTone: TableEventTone {
        if winningResult != nil { return .win }
        if message.contains("ポン") || message.contains("リーチ") { return .call }
        if message.contains("考え中") { return .thinking }
        if message.contains("ツモ") { return .draw }
        if message.contains("捨て") || message.contains("打牌") { return .discard }
        return .neutral
    }

    var assistRecommendations: [DiscardRecommendation] {
        guard players.indices.contains(0),
              !players[0].hand.isEmpty,
              currentPlayerIndex == 0,
              !isBusy,
              pendingUserCall == nil,
              winningResult == nil else { return [] }
        let signature = assistSignature()
        if signature == assistCacheSignature {
            return assistCacheRecommendations
        }

        let recommendations = players[0].hand
            .map { tile in
                let analysis = discardAnalysis(for: tile, in: players[0].hand)
                return DiscardRecommendation(tile: tile, score: analysis.score, reason: analysis.reason, detail: analysis.detail)
            }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.tile.sortKey < rhs.tile.sortKey
            }
            .prefix(3)
            .map { $0 }
        assistCacheSignature = signature
        assistCacheRecommendations = recommendations
        return recommendations
    }

    var assistYakuFocusText: String {
        guard players.indices.contains(0) else { return "狙い役を分析中" }
        let signature = handKindSignature(players[0].hand)
        if signature == yakuAimCacheSignature {
            return yakuAimCacheText
        }
        let aims = yakuAims(for: players[0].hand)
        let text = aims.isEmpty ? "まずは向聴数と有効牌を優先" : aims.joined(separator: "・")
        yakuAimCacheSignature = signature
        yakuAimCacheText = text
        return text
    }

    init() {
        startNewGame()
    }

    func startMatch(mode: MatchMode? = nil) {
        if let mode {
            matchMode = mode
        }
        roundState = MahjongRoundState()
        matchResult = nil
        startRound(resetScores: true)
    }

    func startNewGame() {
        startMatch()
    }

    func advanceToNextRound() {
        if isFinalRound(roundState) {
            matchResult = makeMatchResult()
            return
        }
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
        doraIndicators = wall.isEmpty ? [] : [wall.removeLast()]
        selectedTileID = nil
        currentPlayerIndex = 0
        message = "配牌しました。牌を選んで捨てましょう。"
        lastDiscard = nil
        lastDiscardPlayerIndex = nil
        winningResult = nil
        roundNotice = nil
        pendingUserCall = nil
        isDeclaringReach = false
        forbiddenDiscardKeys.removeAll()
        isAfterUserCall = false
        forcedDiscardTileID = nil
        isRinshanDraw = false
        turnNumber = 1
        lastTappedTileID = nil
        lastTapDate = .distantPast
        actionLog.removeAll()
        dealInitialHands()
        log("\(roundState.detailTitle)開始。\(players[roundState.dealerIndex].name)が親です。")
    }

    func select(tile: MahjongTile) {
        guard canSelectForDiscard(tile) else {
            message = "この牌は今は捨てられません。鳴き直後の食い替え、またはリーチ後の手牌変更は禁止です。"
            return
        }
        withAnimation(.spring(response: 0.22, dampingFraction: 0.74)) {
            selectedTileID = tile.id
        }
        message = "\(tile.label)を選択中。右の『捨てる』で打牌します。"
    }

    func handleHandTap(_ tile: MahjongTile) {
        guard canSelectForDiscard(tile) else {
            message = "この牌は捨てられません。禁止牌は暗く表示しています。"
            return
        }
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
              pendingUserCall == nil,
              winningResult == nil,
              let index = players[0].hand.firstIndex(where: { $0.id == selectedTileID }) else {
            return
        }

        withAnimation(.easeInOut(duration: 0.22)) {
            let tile = players[0].hand.remove(at: index)
            players[0].discards.append(tile)
            if isDeclaringReach {
                players[0].isReach = true
                players[0].reachDiscardID = tile.id
                players[0].score -= 1000
                roundState.riichiSticks += 1
                isDeclaringReach = false
                message = "リーチ。\(tile.label)を宣言牌として捨てました。"
                log("あなた：リーチ")
            } else {
                message = "あなたは\(tile.label)を捨てました。"
            }
            lastDiscard = tile
            lastDiscardPlayerIndex = 0
            self.selectedTileID = nil
            lastTappedTileID = nil
            forbiddenDiscardKeys.removeAll()
            isAfterUserCall = false
            forcedDiscardTileID = nil
            isRinshanDraw = false
            log("あなた：\(tile.label)を打牌")
        }

        if tryCpuPonCall(on: lastDiscard, discardedBy: 0) {
            return
        }

        advanceToCPU()
    }

    func declareReach() {
        guard canReach else { return }
        isDeclaringReach = true
        selectedTileID = nil
        message = "リーチ宣言中です。宣言牌として捨てる牌を選んでください。"
        log("あなた：リーチ準備")
    }

    func declareClosedKan() {
        guard canClosedKan, let kanTiles = firstClosedKanTiles() else { return }
        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
            for tile in kanTiles {
                if let index = players[0].hand.firstIndex(where: { $0.id == tile.id }) {
                    players[0].hand.remove(at: index)
                }
            }
            players[0].melds.append(MahjongMeld(type: .kan, tiles: kanTiles, calledTile: nil, fromPlayerIndex: nil))
            selectedTileID = nil
            lastTappedTileID = nil
            forbiddenDiscardKeys.removeAll()
            isAfterUserCall = true
        }
        message = "\(kanTiles[0].label)を暗カンしました。嶺上牌をツモります。"
        log("あなた：\(kanTiles[0].label)を暗カン")
        if let rinshan = drawTile() {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                players[0].hand.append(rinshan)
                players[0].hand = players[0].hand.sortedForHand()
            }
            isRinshanDraw = true
            message = "\(kanTiles[0].label)を暗カン。\(rinshan.label)を嶺上ツモしました。"
        }
    }

    func performUserCall(_ action: UserCallAction) {
        guard let pendingUserCall, players.indices.contains(pendingUserCall.fromPlayerIndex), pendingUserCall.actions.contains(action) else { return }
        let called = pendingUserCall.tile
        let fromIndex = pendingUserCall.fromPlayerIndex
        let consumed: [MahjongTile]
        let meldType: MahjongMeldType

        switch action {
        case .ron:
            guard let result = evaluateWin(for: players[0].hand + [called], playerIndex: 0, method: "ロン") else { return }
            players[fromIndex].discards.removeAll { $0.id == called.id }
            players[0].hand.append(called)
            players[0].hand = players[0].hand.sortedForHand()
            self.pendingUserCall = nil
            currentPlayerIndex = 0
            isBusy = false
            lastDiscard = called
            lastDiscardPlayerIndex = fromIndex
            winningResult = result
            applyWinScore(playerIndex: 0, method: "ロン")
            message = "ロン和了しました。"
            log("あなた：\(called.label)でロン")
            return
        case .pon:
            guard let tiles = matchingTiles(for: called, count: 2) else { return }
            consumed = tiles
            meldType = .pon
        case .kan:
            guard let tiles = matchingTiles(for: called, count: 3) else { return }
            consumed = tiles
            meldType = .kan
        case .chi:
            guard fromIndex == 3, let tiles = chiTiles(for: called) else { return }
            consumed = tiles
            meldType = .chi
        }

        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
            for tile in consumed {
                if let index = players[0].hand.firstIndex(where: { $0.id == tile.id }) {
                    players[0].hand.remove(at: index)
                }
            }
            players[fromIndex].discards.removeAll { $0.id == called.id }
            let meldTiles = (consumed + [called]).sortedForHand()
            players[0].melds.append(MahjongMeld(type: meldType, tiles: meldTiles, calledTile: called, fromPlayerIndex: fromIndex))
            forbiddenDiscardKeys = forbiddenKeysAfterCall(action: action, called: called, consumed: consumed)
            isAfterUserCall = true
            self.pendingUserCall = nil
            currentPlayerIndex = 0
            selectedTileID = nil
            lastTappedTileID = nil
            isBusy = false
        }

        let ruleNote = forbiddenDiscardKeys.isEmpty ? "" : " 食い替え禁止の牌は暗くしています。"
        message = "\(called.label)を\(meldType.rawValue)しました。次に捨てる牌を選んでください。\(ruleNote)"
        log("あなた：\(called.label)を\(meldType.rawValue)")
        if meldType == .kan, let rinshan = drawTile() {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                players[0].hand.append(rinshan)
                players[0].hand = players[0].hand.sortedForHand()
            }
            isRinshanDraw = true
            message = "\(called.label)をカン。\(rinshan.label)を嶺上ツモしました。捨てる牌を選んでください。"
            log("あなた：\(rinshan.label)を嶺上ツモ")
        }
    }

    func skipUserCall() {
        guard let pendingUserCall else { return }
        let next = pendingUserCall.fromPlayerIndex + 1
        self.pendingUserCall = nil
        forbiddenDiscardKeys.removeAll()
        isAfterUserCall = false
        if next <= 3 {
            continueCPU(from: next)
        } else {
            currentPlayerIndex = 0
            turnNumber += 1
            isBusy = false
            drawForUserIfNeeded()
        }
    }

    func cancelSelection() {
        selectedTileID = nil
        lastTappedTileID = nil
        message = "牌を選んでください。"
    }

    func selectRecommendation(_ recommendation: DiscardRecommendation) {
        select(tile: recommendation.tile)
        message = "\(recommendation.tile.label)を候補にしました。\(recommendation.reason)"
    }

    func drawForUserIfNeeded() {
        guard currentPlayerIndex == 0, !isBusy, winningResult == nil else { return }
        let handCount = players[0].hand.count
        if handCount % 3 == 1, let drawn = drawTile() {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                players[0].hand.append(drawn)
                players[0].hand = players[0].hand.sortedForHand()
            }
            if players[0].isReach {
                if evaluateWin(for: players[0].hand, playerIndex: 0, method: "ツモ") != nil {
                    forcedDiscardTileID = nil
                    selectedTileID = nil
                    message = "リーチ後に待ち牌の\(drawn.label)をツモりました。ツモ和了を選んでください。"
                } else {
                    forcedDiscardTileID = drawn.id
                    selectedTileID = drawn.id
                    message = "リーチ後なので手を変えられません。ツモった\(drawn.label)だけ捨てられます。"
                }
            } else {
                message = "\(drawn.label)をツモりました。捨てる牌を選んでください。"
            }
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
                try? await Task.sleep(nanoseconds: 160_000_000)
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
        continueCPU(from: 1)
    }

    private func continueCPU(from startIndex: Int) {
        Task {
            isBusy = true
            for cpuIndex in startIndex...3 {
                guard winningResult == nil else { break }
                currentPlayerIndex = cpuIndex
                players[cpuIndex].isThinking = true
                message = "\(players[cpuIndex].name)が考え中…"
                try? await Task.sleep(nanoseconds: 140_000_000)
                cpuTakeTurn(cpuIndex)
                players[cpuIndex].isThinking = false
                if pendingUserCall != nil {
                    isBusy = false
                    currentPlayerIndex = 0
                    return
                }
                try? await Task.sleep(nanoseconds: 60_000_000)
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
        offerUserCallIfAvailable(on: lastDiscard, discardedBy: index)
    }

    private func offerUserCallIfAvailable(on discardedTile: MahjongTile?, discardedBy fromPlayerIndex: Int) {
        guard let discardedTile, fromPlayerIndex != 0, players.indices.contains(0), winningResult == nil else { return }
        var actions: [UserCallAction] = []
        if evaluateWin(for: players[0].hand + [discardedTile], playerIndex: 0, method: "ロン") != nil,
           !isRonFuriten(on: discardedTile) {
            actions.append(.ron)
        }
        if !players[0].isReach {
            if matchingTiles(for: discardedTile, count: 2) != nil { actions.append(.pon) }
            if matchingTiles(for: discardedTile, count: 3) != nil { actions.append(.kan) }
            if fromPlayerIndex == 3, chiTiles(for: discardedTile) != nil { actions.append(.chi) }
        }
        guard !actions.isEmpty else { return }
        pendingUserCall = PendingUserCall(tile: discardedTile, fromPlayerIndex: fromPlayerIndex, actions: actions)
        message = "\(players[fromPlayerIndex].name)の\(discardedTile.label)を鳴けます。ポン・チー・カンを選ぶかスキップしてください。"
        log("鳴き選択：\(discardedTile.label)")
    }

    private func matchingTiles(for tile: MahjongTile, count: Int) -> [MahjongTile]? {
        let matches = players[0].hand.filter { $0.matchesKind(tile) }
        guard matches.count >= count else { return nil }
        return Array(matches.prefix(count))
    }

    private func chiTiles(for tile: MahjongTile) -> [MahjongTile]? {
        guard tile.suit != .honor else { return nil }
        let candidates = [
            [tile.rank - 2, tile.rank - 1],
            [tile.rank - 1, tile.rank + 1],
            [tile.rank + 1, tile.rank + 2]
        ].filter { ranks in
            ranks.allSatisfy { (1...9).contains($0) }
        }

        for ranks in candidates {
            var chosen: [MahjongTile] = []
            for rank in ranks {
                if let match = players[0].hand.first(where: { $0.suit == tile.suit && $0.rank == rank && !chosen.map(\.id).contains($0.id) }) {
                    chosen.append(match)
                }
            }
            if chosen.count == 2 { return chosen }
        }
        return nil
    }

    private func firstClosedKanTiles() -> [MahjongTile]? {
        guard players.indices.contains(0) else { return nil }
        let grouped = Dictionary(grouping: players[0].hand, by: { tileKey($0) })
        return grouped.values.first(where: { $0.count >= 4 }).map { Array($0.prefix(4)) }
    }

    private func forbiddenKeysAfterCall(action: UserCallAction, called: MahjongTile, consumed: [MahjongTile]) -> Set<Int> {
        switch action {
        case .ron:
            return []
        case .kan:
            return []
        case .pon:
            // ポン直後に同じ牌を切るのは食い替えとして禁止扱いにします。
            return [tileKey(called)]
        case .chi:
            // チー直後は、鳴いた牌と構成牌をすぐ切れないようにして順子の食い替えを防ぎます。
            return Set((consumed + [called]).map { tileKey($0) })
        }
    }

    private func estimatedShanten(for hand: [MahjongTile]) -> Int {
        let count = tileCounts(hand)
        let pairs = count.values.filter { $0 >= 2 }.count
        let meldLike = count.values.filter { $0 >= 3 }.count + sequenceLikeCount(in: count)
        return max(0, 6 - pairs - meldLike * 2)
    }

    private func sequenceLikeCount(in counts: [Int: Int]) -> Int {
        var total = 0
        for base in [0, 10, 20] {
            for rank in 1...7 {
                if (counts[base + rank] ?? 0) > 0,
                   (counts[base + rank + 1] ?? 0) > 0,
                   (counts[base + rank + 2] ?? 0) > 0 {
                    total += 1
                }
            }
        }
        return min(total, 4)
    }

    private func chooseDiscardIndex(for hand: [MahjongTile]) -> Int {
        let ranked = hand.enumerated().map { pair -> (offset: Int, score: Int) in
            (pair.offset, lightweightDiscardScore(for: pair.element, in: hand))
        }
        return ranked.max(by: { $0.score < $1.score })?.offset ?? hand.indices.randomElement() ?? 0
    }

    private func lightweightDiscardScore(for tile: MahjongTile, in hand: [MahjongTile]) -> Int {
        var score = 0
        let sameCount = hand.filter { $0.matchesKind(tile) }.count
        score += isolationScore(for: tile, in: hand) * 10
        if tile.suit == .honor { score += sameCount == 1 ? 14 : -20 }
        if tile.rank == 1 || tile.rank == 9 { score += 8 }
        if sameCount >= 2 { score -= 22 }
        if countDora(in: [tile]) > 0 { score -= 42 }
        return score
    }

    private func discardAnalysis(for tile: MahjongTile, in hand: [MahjongTile]) -> (score: Int, reason: String, detail: String) {
        let afterDiscard = hand.filter { $0.id != tile.id }
        let shanten = currentShanten(for: afterDiscard)
        let effective = effectiveTileBreakdown(for: afterDiscard)
        let waits = waitTiles(for: afterDiscard)
        let doraPenalty = countDora(in: [tile]) * 42
        var score = max(0, 6 - max(shanten, 0)) * 100 + effective.total * 5 + waits.count * 28 - doraPenalty
        let sameCount = hand.filter { $0.suit == tile.suit && $0.rank == tile.rank }.count
        let isolated = isolationScore(for: tile, in: hand)
        score += isolated * 8
        if sameCount >= 2 { score -= 28 }
        if tile.suit != .honor {
            if hand.contains(where: { $0.suit == tile.suit && $0.rank == tile.rank - 1 }) { score -= 14 }
            if hand.contains(where: { $0.suit == tile.suit && $0.rank == tile.rank + 1 }) { score -= 14 }
            if hand.contains(where: { $0.suit == tile.suit && $0.rank == tile.rank - 2 }) { score -= 7 }
            if hand.contains(where: { $0.suit == tile.suit && $0.rank == tile.rank + 2 }) { score -= 7 }
        }

        let shantenLabel = shanten <= 0 ? "聴牌" : "\(shanten)向聴"
        let topEffective = effective.tiles.prefix(6).map { "\($0.tile.label)\($0.remaining)枚" }.joined(separator: "・")
        let effectiveText = effective.total > 0 ? "有効牌\(effective.total)枚（\(topEffective)）" : "有効牌が少なく、手が進みにくい形です"
        var reasonParts: [String] = ["\(tile.label)を切ると\(shantenLabel)、\(effectiveText)。"]
        if !waits.isEmpty {
            reasonParts.append("待ちは\(waits.map(\.label).joined(separator: "・"))です。")
        }
        if countDora(in: [tile]) > 0 {
            reasonParts.append("ただしドラなので、同程度の候補があれば残したい牌です。")
        } else if isolated >= 2 {
            reasonParts.append("周辺のつながりが薄く、形を壊しにくい打牌です。")
        } else if sameCount >= 2 {
            reasonParts.append("対子を崩すため、受け入れが大きく伸びない限り優先度は下がります。")
        }
        if isFuritenRisk(waits: waits) {
            reasonParts.append("自分の河に待ち牌があり、フリテン注意です。")
        }

        let detailShantenLabel = shanten <= 0 ? "聴牌" : "\(shanten)向聴"
        let detail = "評価: \(detailShantenLabel) / 有効牌\(effective.total)枚 / 孤立\(isolated) / ドラ\(countDora(in: [tile]))"
        return (score, reasonParts.joined(separator: " "), detail)
    }

    private func currentShanten(for hand: [MahjongTile]) -> Int {
        let signature = "shanten:\(hand.count):\(handKindSignature(hand))"
        if let cached = shantenMemo[signature] { return cached }
        let result: Int
        if hand.count % 3 == 2 {
            if isWinningShape(hand) {
                result = -1
            } else {
                result = hand.indices.map { index in
                var copy = hand
                copy.remove(at: index)
                return thirteenTileShanten(copy)
            }.min() ?? 6
            }
        } else {
            result = thirteenTileShanten(hand)
        }
        shantenMemo[signature] = result
        if shantenMemo.count > 800 { shantenMemo.removeAll(keepingCapacity: true) }
        return result
    }

    private func thirteenTileShanten(_ hand: [MahjongTile]) -> Int {
        let counts = tileCounts(hand)
        return min(standardShanten(counts), sevenPairsShanten(counts), kokushiShanten(counts))
    }

    private func standardShanten(_ counts: [Int: Int]) -> Int {
        var best = 8
        var visited = Set<String>()

        func walk(_ counts: [Int: Int], melds: Int, pairs: Int, taatsu: Int) {
            let optimisticTaatsu = min(taatsu, 4 - melds)
            if 8 - melds * 2 - optimisticTaatsu - min(pairs, 1) >= best { return }
            let stateKey = "\(melds)|\(pairs)|\(taatsu)|\(countsSignature(counts))"
            guard !visited.contains(stateKey) else { return }
            visited.insert(stateKey)

            guard let first = counts.keys.sorted().first(where: { (counts[$0] ?? 0) > 0 }) else {
                let usableTaatsu = min(taatsu, 4 - melds)
                best = min(best, 8 - melds * 2 - usableTaatsu - min(pairs, 1))
                return
            }

            var skip = counts
            skip[first, default: 0] -= 1
            if skip[first] == 0 { skip.removeValue(forKey: first) }
            walk(skip, melds: melds, pairs: pairs, taatsu: taatsu)

            if (counts[first] ?? 0) >= 3 {
                var copy = counts
                copy[first, default: 0] -= 3
                if copy[first] == 0 { copy.removeValue(forKey: first) }
                walk(copy, melds: melds + 1, pairs: pairs, taatsu: taatsu)
            }

            if (counts[first] ?? 0) >= 2 {
                var copy = counts
                copy[first, default: 0] -= 2
                if copy[first] == 0 { copy.removeValue(forKey: first) }
                walk(copy, melds: melds, pairs: pairs + 1, taatsu: taatsu + (pairs > 0 ? 1 : 0))
            }

            let suit = first / 10
            let rank = first % 10
            if suit < 3 {
                if rank <= 7, (counts[first + 1] ?? 0) > 0, (counts[first + 2] ?? 0) > 0 {
                    var copy = counts
                    [first, first + 1, first + 2].forEach {
                        copy[$0, default: 0] -= 1
                        if copy[$0] == 0 { copy.removeValue(forKey: $0) }
                    }
                    walk(copy, melds: melds + 1, pairs: pairs, taatsu: taatsu)
                }
                if rank <= 8, (counts[first + 1] ?? 0) > 0 {
                    var copy = counts
                    [first, first + 1].forEach {
                        copy[$0, default: 0] -= 1
                        if copy[$0] == 0 { copy.removeValue(forKey: $0) }
                    }
                    walk(copy, melds: melds, pairs: pairs, taatsu: taatsu + 1)
                }
                if rank <= 7, (counts[first + 2] ?? 0) > 0 {
                    var copy = counts
                    [first, first + 2].forEach {
                        copy[$0, default: 0] -= 1
                        if copy[$0] == 0 { copy.removeValue(forKey: $0) }
                    }
                    walk(copy, melds: melds, pairs: pairs, taatsu: taatsu + 1)
                }
            }
        }

        walk(counts, melds: 0, pairs: 0, taatsu: 0)
        return max(0, best)
    }

    private func sevenPairsShanten(_ counts: [Int: Int]) -> Int {
        let pairs = counts.values.filter { $0 >= 2 }.count
        let unique = counts.values.filter { $0 > 0 }.count
        return max(0, 6 - pairs + max(0, 7 - unique))
    }

    private func kokushiShanten(_ counts: [Int: Int]) -> Int {
        let required = [1, 9, 11, 19, 21, 29, 31, 32, 33, 34, 35, 36, 37]
        let unique = required.filter { (counts[$0] ?? 0) > 0 }.count
        let pair = required.contains { (counts[$0] ?? 0) >= 2 } ? 1 : 0
        return max(0, 13 - unique - pair)
    }

    private func effectiveTileBreakdown(for thirteenTileHand: [MahjongTile]) -> (tiles: [(tile: MahjongTile, remaining: Int)], total: Int) {
        guard thirteenTileHand.count % 3 == 1 else { return ([], 0) }
        let baseShanten = thirteenTileShanten(thirteenTileHand)
        let visible = visibleCounts(using: thirteenTileHand)
        var tiles: [(tile: MahjongTile, remaining: Int)] = []

        for candidate in Self.allTileKinds {
            let remaining = max(0, 4 - (visible[tileKey(candidate)] ?? 0))
            guard remaining > 0 else { continue }
            let withDraw = thirteenTileHand + [candidate]
            let improves: Bool
            if baseShanten == 0 {
                improves = isWinningShape(withDraw)
            } else {
                improves = currentShanten(for: withDraw) < baseShanten
            }
            if improves {
                tiles.append((candidate, remaining))
            }
        }

        tiles.sort {
            if $0.remaining != $1.remaining { return $0.remaining > $1.remaining }
            return $0.tile.sortKey < $1.tile.sortKey
        }
        return (tiles, tiles.reduce(0) { $0 + $1.remaining })
    }

    private func assistSignature() -> String {
        guard players.indices.contains(0) else { return "empty" }
        let discardSig = players.map { player in
            player.discards.map { String(tileKey($0)) }.joined(separator: ",")
        }.joined(separator: "|")
        let meldSig = players.map { player in
            player.melds.flatMap(\.tiles).map { String(tileKey($0)) }.joined(separator: ",")
        }.joined(separator: "|")
        return [
            handKindSignature(players[0].hand),
            doraIndicators.map { String(tileKey($0)) }.joined(separator: ","),
            discardSig,
            meldSig,
            String(wall.count),
            String(currentPlayerIndex),
            String(isBusy)
        ].joined(separator: "#")
    }

    private func handKindSignature(_ hand: [MahjongTile]) -> String {
        countsSignature(tileCounts(hand))
    }

    private func countsSignature(_ counts: [Int: Int]) -> String {
        counts.keys.sorted().map { "\($0):\(counts[$0] ?? 0)" }.joined(separator: ",")
    }

    private func visibleCounts(using hand: [MahjongTile]) -> [Int: Int] {
        var visible = tileCounts(hand)
        for indicator in doraIndicators { visible[tileKey(indicator), default: 0] += 1 }
        for player in players {
            for tile in player.discards { visible[tileKey(tile), default: 0] += 1 }
            for tile in player.melds.flatMap(\.tiles) { visible[tileKey(tile), default: 0] += 1 }
        }
        return visible
    }

    private func isolationScore(for tile: MahjongTile, in hand: [MahjongTile]) -> Int {
        if tile.suit == .honor {
            let sameCount = hand.filter { $0.matchesKind(tile) }.count
            if [35, 36, 37, 31, 32].contains(tileKey(tile)) { return sameCount == 1 ? 1 : -2 }
            return sameCount == 1 ? 3 : -2
        }
        var links = 0
        for distance in [-2, -1, 1, 2] {
            if hand.contains(where: { $0.suit == tile.suit && $0.rank == tile.rank + distance }) {
                links += distance.magnitude == 1 ? 2 : 1
            }
        }
        if hand.filter({ $0.matchesKind(tile) }).count >= 2 { links += 3 }
        if links == 0 { return 3 }
        if links <= 2 { return 1 }
        return -2
    }

    private func isFuritenRisk(waits: [MahjongTile]) -> Bool {
        guard players.indices.contains(0), !waits.isEmpty else { return false }
        return waits.contains { wait in
            players[0].discards.contains { $0.matchesKind(wait) }
        }
    }

    private func yakuAims(for hand: [MahjongTile]) -> [String] {
        let counts = tileCounts(hand)
        var aims: [(String, Int)] = []
        let terminalHonorCount = hand.filter { $0.suit == .honor || $0.rank == 1 || $0.rank == 9 }.count
        if terminalHonorCount <= 2 { aims.append(("断么九", 9 - terminalHonorCount * 2)) }

        let suitGroups = Dictionary(grouping: hand.filter { $0.suit != .honor }, by: \.suit)
        if let mainSuit = suitGroups.max(by: { $0.value.count < $1.value.count }) {
            let honorCount = hand.filter { $0.suit == .honor }.count
            if mainSuit.value.count + honorCount >= 9 {
                aims.append((honorCount > 0 ? "混一色" : "清一色", mainSuit.value.count + honorCount))
            }
        }

        let pairCount = counts.values.filter { $0 >= 2 }.count
        if pairCount >= 4 { aims.append(("七対子", pairCount + 2)) }

        let sequences = possibleSequenceStarts(in: counts)
        if sequences.count >= 3 { aims.append(("平和", sequences.count + 2)) }
        let duplicateSequences = Dictionary(grouping: sequences, by: { $0 }).values.map(\.count).max() ?? 0
        if duplicateSequences >= 2 { aims.append(("一盃口", duplicateSequences + 5)) }

        for start in 1...7 {
            let suitCount = [0, 1, 2].filter { sequences.contains($0 * 10 + start) }.count
            if suitCount >= 2 { aims.append(("三色同順", suitCount + 4)) }
        }

        for suit in [0, 1, 2] {
            let hasIttsuBlocks = [1, 4, 7].filter { sequences.contains(suit * 10 + $0) }.count
            if hasIttsuBlocks >= 2 { aims.append(("一気通貫", hasIttsuBlocks + 4)) }
        }

        let yakuhaiPairs = [31, 32, 35, 36, 37].filter { (counts[$0] ?? 0) >= 2 }.count
        if yakuhaiPairs > 0 { aims.append(("役牌", yakuhaiPairs + 5)) }

        return aims
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return lhs.0 < rhs.0
            }
            .prefix(3)
            .map(\.0)
    }

    private func possibleSequenceStarts(in counts: [Int: Int]) -> [Int] {
        var starts: [Int] = []
        for suit in [0, 1, 2] {
            for rank in 1...7 {
                let key = suit * 10 + rank
                if (counts[key] ?? 0) > 0,
                   (counts[key + 1] ?? 0) > 0,
                   (counts[key + 2] ?? 0) > 0 {
                    starts.append(key)
                }
            }
        }
        return starts
    }

    private func isRonFuriten(on winningTile: MahjongTile) -> Bool {
        guard players.indices.contains(0) else { return false }
        let waits = waitTiles(for: players[0].hand)
        guard waits.contains(where: { $0.matchesKind(winningTile) }) else { return false }
        return isFuritenRisk(waits: waits)
    }

    private func drawTile() -> MahjongTile? {
        guard !wall.isEmpty else {
            guard roundNotice == nil else { return nil }
            message = "流局です。次局へ進みます。"
            roundState.honba += 1
            isBusy = true
            roundNotice = RoundNotice(
                title: "流局",
                body: "山がなくなりました。",
                detail: "誰も和了できなかったため本場が1つ増えます。次局へ進んで、配牌からやり直します。"
            )
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
        let base = estimatedWinPoint(for: players[playerIndex].hand, playerIndex: playerIndex, method: method)
        let honbaBonus = roundState.honba * 300
        let deposit = roundState.riichiSticks * 1000

        if method == "ツモ" {
            var gain = deposit
            for index in players.indices where index != playerIndex {
                let payment = max(500, base / 3) + roundState.honba * 100
                players[index].score -= payment
                gain += payment
            }
            players[playerIndex].score += gain
        } else if let fromIndex = lastDiscardPlayerIndex, players.indices.contains(fromIndex), fromIndex != playerIndex {
            let payment = base + honbaBonus + deposit
            players[fromIndex].score -= payment
            players[playerIndex].score += payment
        } else {
            players[playerIndex].score += base + honbaBonus + deposit
        }

        roundState.honba = players[playerIndex].isDealer ? roundState.honba + 1 : 0
        roundState.riichiSticks = 0
    }

    private func estimatedWinPoint(for hand: [MahjongTile], playerIndex: Int, method: String) -> Int {
        let counts = tileCounts(hand)
        let yakumanCount = [
            isKokushi(counts),
            isSuuAnkou(counts),
            isDaisangen(counts),
            isDaisuushi(counts),
            isShousuushi(counts),
            isTsuuiisou(hand),
            isChinroutou(hand),
            isRyuuiisou(hand),
            isChuuren(hand)
        ].filter { $0 }.count
        let dealer = players.indices.contains(playerIndex) && players[playerIndex].isDealer
        if yakumanCount > 0 {
            return (dealer ? 48000 : 32000) * yakumanCount
        }

        var han = 0
        han += normalYakuList(for: hand, counts: counts, playerIndex: playerIndex, method: method, sevenPairs: isSevenPairs(counts)).count
        han += countDora(in: hand)
        han = max(1, han)
        return (dealer ? 1500 : 1000) * han
    }

    private func isFinalRound(_ state: MahjongRoundState) -> Bool {
        state.wind == matchMode.finalWind && state.handNumber >= 4
    }

    private func makeMatchResult() -> MatchResult {
        let ranked = players
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.name < rhs.name
            }
            .enumerated()
            .map { offset, player in
                MatchStanding(rank: offset + 1, playerName: player.name, score: player.score)
            }
        return MatchResult(modeName: matchMode.rawValue, standings: ranked)
    }

    private func log(_ text: String) {
        actionLog.insert(text, at: 0)
        if actionLog.count > 16 { actionLog.removeLast(actionLog.count - 16) }
    }

    private func countDora(in hand: [MahjongTile]) -> Int {
        let doraKinds = doraTiles
        guard !doraKinds.isEmpty else { return 0 }
        return hand.reduce(0) { total, tile in
            total + doraKinds.filter { tile.matchesKind($0) }.count
        }
    }

    private func normalYakuList(for hand: [MahjongTile], counts: [Int: Int], playerIndex: Int, method: String, sevenPairs: Bool) -> [String] {
        var yaku: [String] = []
        let melds = players.indices.contains(playerIndex) ? players[playerIndex].melds : []
        let isClosed = melds.isEmpty

        if sevenPairs { yaku.append("七対子") }
        if method == "ツモ", isClosed { yaku.append("門前清自摸和") }
        if players.indices.contains(playerIndex), players[playerIndex].isReach { yaku.append("リーチ") }
        if isTanyao(hand, melds: melds) { yaku.append("断么九") }
        if hasYakuhai(counts: counts, melds: melds, playerIndex: playerIndex) { yaku.append("役牌") }
        if isToitoi(counts: counts, melds: melds) { yaku.append("対々和") }
        if method == "ツモ", isRinshanDraw { yaku.append("嶺上開花") }
        if method == "ツモ", wall.isEmpty { yaku.append("海底摸月") }

        if let standard = standardDecomposition(counts) {
            let sequenceMelds = standard.melds.filter { isSequence($0) }
            if isClosed, isPinfu(pair: standard.pair, melds: standard.melds, playerIndex: playerIndex) { yaku.append("平和") }
            if isClosed, hasIipeikou(sequenceMelds) { yaku.append("一盃口") }
            if hasSanshoku(sequenceMelds) { yaku.append("三色同順") }
            if hasIttsu(sequenceMelds) { yaku.append("一気通貫") }
        }
        if isChinitsu(hand, melds: melds) { yaku.append("清一色") }
        else if isHonitsu(hand, melds: melds) { yaku.append("混一色") }
        return yaku
    }

    private func isTanyao(_ hand: [MahjongTile], melds: [MahjongMeld]) -> Bool {
        (hand + melds.flatMap(\.tiles)).allSatisfy { tile in
            tile.suit != .honor && (2...8).contains(tile.rank)
        }
    }

    private func hasYakuhai(counts: [Int: Int], melds: [MahjongMeld], playerIndex: Int) -> Bool {
        var keys = Set<Int>()
        for (key, count) in counts where count >= 3 { keys.insert(key) }
        for meld in melds where meld.type == .pon || meld.type == .kan {
            if let tile = meld.tiles.first { keys.insert(tileKey(tile)) }
        }
        let seatWindKey = 31 + playerIndex
        let roundWindKey = roundState.wind == .east ? 31 : 32
        return keys.contains(35) || keys.contains(36) || keys.contains(37) || keys.contains(seatWindKey) || keys.contains(roundWindKey)
    }

    private func isToitoi(counts: [Int: Int], melds: [MahjongMeld]) -> Bool {
        guard !melds.contains(where: { $0.type == .chi }) else { return false }
        var pairCount = 0
        for count in counts.values {
            if count == 2 { pairCount += 1 }
            else if count == 3 || count == 4 { continue }
            else { return false }
        }
        return pairCount == 1
    }

    private func isChinitsu(_ hand: [MahjongTile], melds: [MahjongMeld]) -> Bool {
        let tiles = hand + melds.flatMap(\.tiles)
        let suits = Set(tiles.map(\.suit))
        return suits.count == 1 && suits.first != .honor
    }

    private func isHonitsu(_ hand: [MahjongTile], melds: [MahjongMeld]) -> Bool {
        let tiles = hand + melds.flatMap(\.tiles)
        let numberedSuits = Set(tiles.filter { $0.suit != .honor }.map(\.suit))
        return numberedSuits.count == 1 && tiles.contains(where: { $0.suit == .honor })
    }

    private func canDeclareReach(from hand: [MahjongTile]) -> Bool {
        guard players.indices.contains(0),
              !players[0].isReach,
              players[0].melds.isEmpty,
              players[0].score >= 1000,
              hand.count % 3 == 2 else {
            return false
        }
        return hand.contains { isReachDiscardCandidate($0) }
    }

    private func isReachDiscardCandidate(_ tile: MahjongTile) -> Bool {
        !waitTilesAfterDiscarding(tile).isEmpty
    }

    private func isTenpai(_ thirteenTileHand: [MahjongTile]) -> Bool {
        guard thirteenTileHand.count % 3 == 1 else { return false }
        return !waitTiles(for: thirteenTileHand).isEmpty
    }

    private func waitTilesAfterDiscarding(_ tile: MahjongTile) -> [MahjongTile] {
        guard players.indices.contains(0),
              !players[0].isReach,
              players[0].melds.isEmpty,
              players[0].hand.count % 3 == 2,
              let index = players[0].hand.firstIndex(where: { $0.id == tile.id }) else {
            return []
        }
        var afterDiscard = players[0].hand
        afterDiscard.remove(at: index)
        return waitTiles(for: afterDiscard)
    }

    private func waitTiles(for thirteenTileHand: [MahjongTile]) -> [MahjongTile] {
        guard thirteenTileHand.count % 3 == 1 else { return [] }
        return Self.allTileKinds.filter { candidate in
            isWinningShape(thirteenTileHand + [candidate])
        }
    }

    private func isWinningShape(_ hand: [MahjongTile]) -> Bool {
        guard hand.count % 3 == 2 else { return false }
        let counts = tileCounts(hand)
        return isKokushi(counts)
            || isSevenPairs(counts)
            || isStandardWinning(counts)
            || isSuuAnkou(counts)
            || isDaisangen(counts)
            || isDaisuushi(counts)
            || isShousuushi(counts)
            || isTsuuiisou(hand)
            || isChinroutou(hand)
            || isRyuuiisou(hand)
            || isChuuren(hand)
    }

    private static let allTileKinds: [MahjongTile] = {
        var tiles: [MahjongTile] = []
        for suit in [TileSuit.man, .pin, .sou] {
            for rank in 1...9 {
                tiles.append(MahjongTile(suit: suit, rank: rank, copy: 0))
            }
        }
        for rank in 1...7 {
            tiles.append(MahjongTile(suit: .honor, rank: rank, copy: 0))
        }
        return tiles
    }()

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
            let score = base * multiplier
            return WinResult(
                winnerName: winnerName,
                title: multiplier >= 2 ? "ダブル以上役満！" : "役満和了！",
                method: method,
                yaku: yakuman,
                hanText: "役満 × \(multiplier)",
                fuText: "役満は符計算なし",
                scoreText: "\(score)点",
                scoreBreakdown: [
                    "成立役：\(yakuman.joined(separator: " + "))",
                    "\(dealer ? "親" : "子")の役満基準点 \(base)点 × \(multiplier)",
                    "合計 \(score)点。役満は翻・符の通常計算を使いません。"
                ],
                explanation: "成立した役満を優先して点数を計算しています。"
            )
        }

        let normalYaku = normalYakuList(for: hand, counts: counts, playerIndex: playerIndex, method: method, sevenPairs: sevenPairs)
        guard !normalYaku.isEmpty else { return nil }
        let doraCount = countDora(in: hand)
        let displayYaku = doraCount > 0 ? normalYaku + ["ドラ\(doraCount)"] : normalYaku
        let han = max(1, normalYaku.count + doraCount)
        let fu = sevenPairs ? 25 : 30
        let baseScore = estimatedWinPoint(for: hand, playerIndex: playerIndex, method: method)
        let honbaBonus = roundState.honba * (method == "ツモ" ? 300 : 300)
        let deposit = roundState.riichiSticks * 1000
        let score = baseScore + honbaBonus + deposit

        return WinResult(
            winnerName: winnerName,
            title: "和了！",
            method: method,
            yaku: displayYaku,
            hanText: "\(han)翻",
            fuText: "\(fu)符（練習用概算）",
            scoreText: "約\(score)点",
            scoreBreakdown: [
                "成立役：\(normalYaku.joined(separator: " + "))",
                doraCount > 0 ? "ドラ：\(doraIndicators.map(\.label).joined(separator: "・"))表示なので、ドラは\(doraTiles.map(\.label).joined(separator: "・"))。手牌に\(doraCount)枚あります。" : "ドラ：\(doraIndicators.map(\.label).joined(separator: "・"))表示。今回は手牌にドラはありません。",
                "\(han)翻 / \(fu)符として練習用に概算",
                "\(dealer ? "親" : "子")の基本点 約\(baseScore)点" + (honbaBonus > 0 ? " + 本場\(honbaBonus)点" : "") + (deposit > 0 ? " + 供託\(deposit)点" : ""),
                "合計 約\(score)点"
            ],
            explanation: "役を名前だけで終わらせず、翻・符・供託まで追えるようにした練習用の簡易計算です。"
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

    private func standardDecomposition(_ counts: [Int: Int]) -> (pair: Int, melds: [[Int]])? {
        for (key, count) in counts where count >= 2 {
            var copy = counts
            copy[key, default: 0] -= 2
            if copy[key] == 0 { copy.removeValue(forKey: key) }
            if let melds = decomposeMelds(copy) {
                return (key, melds)
            }
        }
        return nil
    }

    private func decomposeMelds(_ counts: [Int: Int]) -> [[Int]]? {
        guard let first = counts.keys.sorted().first(where: { (counts[$0] ?? 0) > 0 }) else { return [] }
        var counts = counts

        if (counts[first] ?? 0) >= 3 {
            counts[first, default: 0] -= 3
            if counts[first] == 0 { counts.removeValue(forKey: first) }
            if let rest = decomposeMelds(counts) {
                return [[first, first, first]] + rest
            }
            counts[first, default: 0] += 3
        }

        let suit = first / 10
        let rank = first % 10
        if suit < 3, rank <= 7, (counts[first + 1] ?? 0) > 0, (counts[first + 2] ?? 0) > 0 {
            counts[first, default: 0] -= 1
            counts[first + 1, default: 0] -= 1
            counts[first + 2, default: 0] -= 1
            [first, first + 1, first + 2].forEach { if counts[$0] == 0 { counts.removeValue(forKey: $0) } }
            if let rest = decomposeMelds(counts) {
                return [[first, first + 1, first + 2]] + rest
            }
        }

        return nil
    }

    private func isSequence(_ meld: [Int]) -> Bool {
        meld.count == 3 && Set(meld).count == 3 && meld[0] / 10 < 3 && meld[0] + 1 == meld[1] && meld[1] + 1 == meld[2]
    }

    private func isPinfu(pair: Int, melds: [[Int]], playerIndex: Int) -> Bool {
        guard melds.allSatisfy(isSequence) else { return false }
        let seatWindKey = 31 + playerIndex
        let roundWindKey = roundState.wind == .east ? 31 : 32
        return ![seatWindKey, roundWindKey, 35, 36, 37].contains(pair)
    }

    private func hasIipeikou(_ sequences: [[Int]]) -> Bool {
        let grouped = Dictionary(grouping: sequences.map { $0[0] }, by: { $0 })
        return grouped.values.contains { $0.count >= 2 }
    }

    private func hasSanshoku(_ sequences: [[Int]]) -> Bool {
        for rank in 1...7 {
            let needed = [rank, 10 + rank, 20 + rank]
            if needed.allSatisfy({ key in sequences.contains(where: { $0.first == key }) }) {
                return true
            }
        }
        return false
    }

    private func hasIttsu(_ sequences: [[Int]]) -> Bool {
        for base in [0, 10, 20] {
            let needed = [base + 1, base + 4, base + 7]
            if needed.allSatisfy({ key in sequences.contains(where: { $0.first == key }) }) {
                return true
            }
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
