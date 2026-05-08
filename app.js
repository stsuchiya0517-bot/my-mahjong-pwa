(() => {
  "use strict";

  const WIND_LABELS = ["東", "南", "西", "北"];
  const PLAYER_NAMES = ["あなた", "CPU右", "CPU対面", "CPU左"];
  const SUIT_ORDER = { m: 0, p: 1, s: 2, z: 3 };
  const HONOR_LABELS = { 1: "東", 2: "南", 3: "西", 4: "北", 5: "白", 6: "發", 7: "中" };
  const SUIT_LABELS = { m: "萬", p: "筒", s: "索" };
  const ALL_KEYS = [];

  ["m", "p", "s"].forEach((suit) => {
    for (let rank = 1; rank <= 9; rank += 1) ALL_KEYS.push(`${suit}${rank}`);
  });
  for (let rank = 1; rank <= 7; rank += 1) ALL_KEYS.push(`z${rank}`);

  const $ = (id) => document.getElementById(id);
  const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

  const state = {
    players: [],
    wall: [],
    doraIndicator: null,
    doraKey: null,
    dealer: 0,
    roundIndex: 0,
    honba: 0,
    riichiSticks: 0,
    current: 0,
    phase: "boot",
    lastDrawTileId: null,
    lastDiscard: null,
    pendingCalls: [],
    riichiMode: false,
    message: "対局を開始します。",
    log: [],
    locked: false,
    rulesVersion: "complete-training"
  };

  function makeTile(suit, rank, copy) {
    const key = `${suit}${rank}`;
    return { id: `${key}-${copy}`, key, suit, rank, label: labelForKey(key) };
  }

  function tileFromKey(key) {
    return { id: `${key}-x-${Math.random().toString(36).slice(2)}`, key, suit: key[0], rank: Number(key.slice(1)), label: labelForKey(key) };
  }

  function labelForKey(key) {
    const suit = key[0];
    const rank = Number(key.slice(1));
    if (suit === "z") return HONOR_LABELS[rank];
    return `${rank}${SUIT_LABELS[suit]}`;
  }

  function buildWall() {
    const tiles = [];
    ["m", "p", "s"].forEach((suit) => {
      for (let rank = 1; rank <= 9; rank += 1) {
        for (let copy = 0; copy < 4; copy += 1) tiles.push(makeTile(suit, rank, copy));
      }
    });
    for (let rank = 1; rank <= 7; rank += 1) {
      for (let copy = 0; copy < 4; copy += 1) tiles.push(makeTile("z", rank, copy));
    }
    for (let i = tiles.length - 1; i > 0; i -= 1) {
      const j = Math.floor(Math.random() * (i + 1));
      [tiles[i], tiles[j]] = [tiles[j], tiles[i]];
    }
    return tiles;
  }

  function compareTiles(a, b) {
    if (SUIT_ORDER[a.suit] !== SUIT_ORDER[b.suit]) return SUIT_ORDER[a.suit] - SUIT_ORDER[b.suit];
    if (a.rank !== b.rank) return a.rank - b.rank;
    return a.id.localeCompare(b.id);
  }

  function sortHand(player) {
    player.hand.sort(compareTiles);
  }

  function keyCounts(tiles) {
    const counts = Object.fromEntries(ALL_KEYS.map((key) => [key, 0]));
    tiles.forEach((tile) => { counts[tile.key] += 1; });
    return counts;
  }

  function cloneCounts(counts) {
    return Object.fromEntries(ALL_KEYS.map((key) => [key, counts[key] || 0]));
  }

  function noTilesLeft(counts) {
    return ALL_KEYS.every((key) => (counts[key] || 0) === 0);
  }

  function firstRemainingKey(counts) {
    return ALL_KEYS.find((key) => (counts[key] || 0) > 0) || null;
  }

  function canSequenceFrom(key, counts) {
    const suit = key[0];
    const rank = Number(key.slice(1));
    if (suit === "z" || rank > 7) return false;
    return counts[key] > 0 && counts[`${suit}${rank + 1}`] > 0 && counts[`${suit}${rank + 2}`] > 0;
  }

  function findMelds(counts, needed, path = []) {
    if (needed === 0) return noTilesLeft(counts) ? path : null;
    const key = firstRemainingKey(counts);
    if (!key) return needed === 0 ? path : null;

    if (counts[key] >= 3) {
      const next = cloneCounts(counts);
      next[key] -= 3;
      const triplet = findMelds(next, needed - 1, [...path, { type: "pon", keys: [key, key, key], open: false }]);
      if (triplet) return triplet;
    }

    if (canSequenceFrom(key, counts)) {
      const suit = key[0];
      const rank = Number(key.slice(1));
      const next = cloneCounts(counts);
      next[key] -= 1;
      next[`${suit}${rank + 1}`] -= 1;
      next[`${suit}${rank + 2}`] -= 1;
      const sequence = findMelds(next, needed - 1, [...path, { type: "chi", keys: [key, `${suit}${rank + 1}`, `${suit}${rank + 2}`], open: false }]);
      if (sequence) return sequence;
    }
    return null;
  }

  function findStandardDecomposition(concealedTiles, openMeldCount = 0) {
    const neededMelds = 4 - openMeldCount;
    if (concealedTiles.length !== 2 + neededMelds * 3) return null;
    const counts = keyCounts(concealedTiles);
    for (const pairKey of ALL_KEYS) {
      if (counts[pairKey] >= 2) {
        const next = cloneCounts(counts);
        next[pairKey] -= 2;
        const melds = findMelds(next, neededMelds, []);
        if (melds) return { pair: pairKey, concealedMelds: melds };
      }
    }
    return null;
  }

  function isSevenPairs(tiles) {
    if (tiles.length !== 14) return false;
    const counts = keyCounts(tiles);
    return ALL_KEYS.filter((key) => counts[key] === 2).length === 7;
  }



  function isThirteenOrphans(tiles) {
    if (tiles.length !== 14) return false;
    const required = ["m1","m9","p1","p9","s1","s9","z1","z2","z3","z4","z5","z6","z7"];
    const counts = keyCounts(tiles);
    return required.every((key) => counts[key] >= 1) && required.some((key) => counts[key] >= 2);
  }

  function waitingKeysFor(player, baseTiles = player.hand) {
    if ((baseTiles.length + player.melds.length * 3) % 3 !== 1) return [];
    return ALL_KEYS.filter((key) => canWinWithMelds([...baseTiles, tileFromKey(key)], player.melds) || isThirteenOrphans([...baseTiles, tileFromKey(key)]));
  }

  function isFuriten(player, targetKey = null) {
    const waits = waitingKeysFor(player);
    const discardKeys = new Set(player.discards.map((tile) => tile.key));
    const permanent = waits.some((key) => discardKeys.has(key));
    const temporary = player.skippedRonKeys && targetKey && player.skippedRonKeys.includes(targetKey);
    return permanent || temporary;
  }

  function canClosedKan(player) {
    if (player.riichi && player.lastDrawId == null) return [];
    const counts = keyCounts(player.hand);
    return ALL_KEYS.filter((key) => counts[key] === 4);
  }

  function canAddedKan(player) {
    if (player.riichi) return [];
    return player.melds
      .filter((meld) => meld.type === "pon")
      .map((meld) => meld.tiles[0].key)
      .filter((key) => player.hand.some((tile) => tile.key === key));
  }

  function addDoraIndicator() {
    if (state.wall.length <= 0) return null;
    const indicator = state.wall.pop();
    if (!state.doraIndicators) state.doraIndicators = [];
    state.doraIndicators.push(indicator);
    state.doraIndicator = state.doraIndicators[0];
    state.doraKey = nextDoraKey(state.doraIndicator.key);
    return indicator;
  }

  function doraKeys() {
    const indicators = state.doraIndicators && state.doraIndicators.length ? state.doraIndicators : (state.doraIndicator ? [state.doraIndicator] : []);
    return indicators.map((tile) => nextDoraKey(tile.key));
  }

  function canWinWithMelds(concealedTiles, melds = []) {
    if (melds.length === 0 && isSevenPairs(concealedTiles)) return true;
    return Boolean(findStandardDecomposition(concealedTiles, melds.length));
  }

  function isTerminalOrHonor(key) {
    const suit = key[0];
    const rank = Number(key.slice(1));
    return suit === "z" || rank === 1 || rank === 9;
  }

  function isSimple(key) {
    return !isTerminalOrHonor(key);
  }

  function nextDoraKey(indicatorKey) {
    const suit = indicatorKey[0];
    const rank = Number(indicatorKey.slice(1));
    if (suit === "z") {
      if (rank >= 1 && rank <= 4) return `z${rank === 4 ? 1 : rank + 1}`;
      return `z${rank === 7 ? 5 : rank + 1}`;
    }
    return `${suit}${rank === 9 ? 1 : rank + 1}`;
  }

  function openMeldKeys(player) {
    return player.melds.flatMap((meld) => meld.tiles.map((tile) => tile.key));
  }

  function allWinningTiles(player, concealedTiles) {
    return [...concealedTiles, ...player.melds.flatMap((meld) => meld.tiles)];
  }

  function windKeyForPlayer(index) {
    const offset = (index - state.dealer + 4) % 4;
    return `z${offset + 1}`;
  }

  function roundWindKey() {
    return "z1";
  }

  function meldsForEvaluation(player, concealedTiles) {
    const standard = findStandardDecomposition(concealedTiles, player.melds.length);
    const open = player.melds.map((meld) => ({ type: meld.type === "chi" ? "chi" : "pon", keys: meld.tiles.map((tile) => tile.key), open: true }));
    if (!standard) return { pair: null, melds: open, standard: null };
    return { pair: standard.pair, melds: [...standard.concealedMelds, ...open], standard };
  }

  function hasOnlyOneSuit(tileKeys) {
    const suits = new Set(tileKeys.filter((key) => key[0] !== "z").map((key) => key[0]));
    return suits.size === 1;
  }

  function countDora(tileKeys) {
    const keys = doraKeys();
    return tileKeys.filter((key) => keys.includes(key)).length;
  }



  function evaluateYakuman(playerIndex, type, concealedTiles) {
    const player = state.players[playerIndex];
    const allKeys = allWinningTiles(player, concealedTiles).map((tile) => tile.key);
    const counts = Object.fromEntries(ALL_KEYS.map((key) => [key, 0]));
    allKeys.forEach((key) => { counts[key] += 1; });
    const yakuman = [];
    const closed = player.melds.length === 0;

    if (isThirteenOrphans(concealedTiles) && closed) yakuman.push({ name: "国士無双", times: 1, note: "13種の么九牌 + どれか1対子" });
    const tripletLike = (key) => counts[key] >= 3 || player.melds.some((m) => m.type === "kan" && m.tiles[0].key === key);
    if (["z5","z6","z7"].every(tripletLike)) yakuman.push({ name: "大三元", times: 1, note: "白・發・中すべて刻子/槓子" });
    const winds = ["z1","z2","z3","z4"];
    const windTriplets = winds.filter(tripletLike).length;
    if (windTriplets === 4) yakuman.push({ name: "大四喜", times: 2, note: "四風牌すべて刻子/槓子" });
    if (windTriplets === 3 && winds.some((key) => counts[key] === 2)) yakuman.push({ name: "小四喜", times: 1, note: "三風刻子 + 残り一風が雀頭" });
    if (allKeys.every((key) => key[0] === "z")) yakuman.push({ name: "字一色", times: 1, note: "字牌のみ" });
    if (allKeys.every((key) => key[0] !== "z" && (key.endsWith("1") || key.endsWith("9")))) yakuman.push({ name: "清老頭", times: 1, note: "1・9牌のみ" });
    const green = new Set(["s2","s3","s4","s6","s8","z6"]);
    if (allKeys.every((key) => green.has(key))) yakuman.push({ name: "緑一色", times: 1, note: "緑色牌のみ" });
    if (player.melds.filter((m) => m.type === "kan").length === 4) yakuman.push({ name: "四槓子", times: 1, note: "槓子4つ" });

    const standard = meldsForEvaluation(player, concealedTiles);
    if (closed && standard.standard) {
      const concealedTriplets = standard.melds.filter((meld) => meld.type === "pon" && !meld.open).length;
      if (concealedTriplets === 4) yakuman.push({ name: "四暗刻", times: 1, note: "暗刻4つ" });
    }

    if (closed && allKeys.length === 14 && hasOnlyOneSuit(allKeys) && !allKeys.some((key) => key[0] === "z")) {
      const suit = allKeys[0][0];
      const nineGates = [`${suit}1`,`${suit}1`,`${suit}1`,`${suit}2`,`${suit}3`,`${suit}4`,`${suit}5`,`${suit}6`,`${suit}7`,`${suit}8`,`${suit}9`,`${suit}9`,`${suit}9`];
      const baseCounts = {}; nineGates.forEach(k => baseCounts[k] = (baseCounts[k]||0)+1);
      if (Object.entries(baseCounts).every(([key, n]) => counts[key] >= n)) yakuman.push({ name: "九蓮宝燈", times: 1, note: "一色の1112345678999型" });
    }
    return yakuman;
  }

  function calculateFu(playerIndex, type, player, standardView, sevenPairs, closed) {
    if (sevenPairs) return { fu: 25, detail: ["七対子は固定25符"] };
    let fu = 20;
    const detail = ["副底20符"];
    if (type === "ron" && closed) { fu += 10; detail.push("門前ロン10符"); }
    if (type === "tsumo") { fu += 2; detail.push("ツモ2符"); }
    const valuePairs = ["z5","z6","z7", windKeyForPlayer(playerIndex), roundWindKey()];
    if (standardView.pair && valuePairs.includes(standardView.pair)) { fu += 2; detail.push(`役牌/風牌の雀頭2符（${labelForKey(standardView.pair)}）`); }
    standardView.melds.forEach((meld) => {
      if (meld.type === "chi") return;
      const key = meld.keys[0];
      const terminal = isTerminalOrHonor(key);
      const open = !!meld.open;
      const kan = meld.type === "kan" || meld.keys.length === 4;
      let add;
      if (kan) add = terminal ? (open ? 16 : 32) : (open ? 8 : 16);
      else add = terminal ? (open ? 4 : 8) : (open ? 2 : 4);
      fu += add;
      detail.push(`${labelForKey(key)}の${kan ? "槓子" : "刻子"}${add}符`);
    });
    if (fu === 20 && type === "ron") { fu = 30; detail.push("平和ロン相当は30符扱い"); }
    return { fu: Math.ceil(fu / 10) * 10, detail };
  }

  function evaluateWin(playerIndex, type, winTile = null, fromIndex = null) {
    const player = state.players[playerIndex];
    const concealedTiles = type === "ron" && winTile ? [...player.hand, winTile] : [...player.hand];
    const closed = player.melds.length === 0;
    if (type === "ron" && isFuriten(player, winTile?.key)) return { valid: false, reason: "フリテンのためロンできません。自分の捨て牌に待ち牌が含まれています。" };
    const tileKeys = allWinningTiles(player, concealedTiles).map((tile) => tile.key);
    const yakus = [];
    let han = 0;
    let fu = 30;
    const thirteenOrphans = closed && isThirteenOrphans(concealedTiles);
    const sevenPairs = closed && isSevenPairs(concealedTiles);
    const standardView = meldsForEvaluation(player, concealedTiles);
    const canWin = thirteenOrphans || sevenPairs || Boolean(standardView.standard);

    const yakuman = evaluateYakuman(playerIndex, type, concealedTiles);
    if (yakuman.length > 0) {
      const times = yakuman.reduce((sum, y) => sum + y.times, 0);
      const score = calculateYakumanPoints(times, playerIndex === state.dealer, type);
      return { valid: true, type, fromIndex, yakus: yakuman.map(y => ({ name: y.name, han: "役満", note: y.note })), han: `${times}倍役満`, yakuHan: 0, dora: 0, fu: "-", score, yakuman: true, fuDetail: ["役満は翻・符ではなく固定点で計算します。"], concealedTiles };
    }

    if (!canWin) return { valid: false, reason: "和了形ではありません。" };

    if (player.riichi) { yakus.push({ name: "リーチ", han: 1, note: "門前でテンパイ宣言" }); han += 1; }
    if (type === "tsumo" && closed) { yakus.push({ name: "門前清自摸和", han: 1, note: "鳴かずにツモ和了" }); han += 1; }
    if (tileKeys.every(isSimple)) { yakus.push({ name: "断么九", han: 1, note: "2〜8だけで構成" }); han += 1; }
    if (sevenPairs) { yakus.push({ name: "七対子", han: 2, note: "7つの対子" }); han += 2; fu = 25; }

    const counts = Object.fromEntries(ALL_KEYS.map((key) => [key, 0]));
    tileKeys.forEach((key) => { counts[key] += 1; });
    const valueTriplets = ["z5", "z6", "z7", windKeyForPlayer(playerIndex), roundWindKey()];
    valueTriplets.forEach((key) => {
      if (counts[key] >= 3) {
        const name = key === windKeyForPlayer(playerIndex) ? "自風牌" : key === roundWindKey() ? "場風牌" : `役牌 ${labelForKey(key)}`;
        yakus.push({ name, han: 1, note: `${labelForKey(key)}の刻子` });
        han += 1;
      }
    });

    if (!sevenPairs && standardView.standard) {
      const allMelds = standardView.melds;
      const allTriplets = allMelds.every((meld) => meld.type !== "chi");
      const allSequences = allMelds.every((meld) => meld.type === "chi");
      const pairIsValue = ["z5", "z6", "z7", windKeyForPlayer(playerIndex), roundWindKey()].includes(standardView.pair);

      if (allTriplets) { yakus.push({ name: "対々和", han: 2, note: "すべて刻子" }); han += 2; }
      if (closed && allSequences && !pairIsValue) { yakus.push({ name: "平和", han: 1, note: "順子中心の軽い手" }); han += 1; fu = type === "tsumo" ? 20 : 30; }

      const sequenceNames = allMelds
        .filter((meld) => meld.type === "chi" && !meld.open)
        .map((meld) => meld.keys.join("-"));
      const sequenceCounts = sequenceNames.reduce((acc, name) => {
        acc[name] = (acc[name] || 0) + 1;
        return acc;
      }, {});
      if (closed && Object.values(sequenceCounts).some((count) => count >= 2)) {
        yakus.push({ name: "一盃口", han: 1, note: "同じ順子が2組" });
        han += 1;
      }
    }

    if (hasOnlyOneSuit(tileKeys)) {
      const hasHonors = tileKeys.some((key) => key[0] === "z");
      if (hasHonors) {
        const value = closed ? 3 : 2;
        yakus.push({ name: "混一色", han: value, note: "一色 + 字牌" });
        han += value;
      } else {
        const value = closed ? 6 : 5;
        yakus.push({ name: "清一色", han: value, note: "一色のみ" });
        han += value;
      }
    }

    if (han <= 0) {
      return { valid: false, reason: "形は完成していますが、役がありません。リーチ・タンヤオ・役牌などを作りましょう。" };
    }

    const dora = countDora(tileKeys);
    if (dora > 0) yakus.push({ name: `ドラ${dora}`, han: dora, note: `表示中のドラを${dora}枚` });
    const totalHan = han + dora;

    const fuResult = calculateFu(playerIndex, type, player, standardView, sevenPairs, closed);
    fu = fuResult.fu;
    const score = calculatePoints(totalHan, fu, playerIndex === state.dealer, type);
    return { valid: true, type, fromIndex, yakus, han: totalHan, yakuHan: han, dora, fu, score, sevenPairs, thirteenOrphans, fuDetail: fuResult.detail, concealedTiles };
  }

  function calculatePoints(han, fu, isDealer, type) {
    let base;
    let limitName = "";
    if (han >= 13) { base = 8000; limitName = "役満相当"; }
    else if (han >= 11) { base = 6000; limitName = "三倍満"; }
    else if (han >= 8) { base = 4000; limitName = "倍満"; }
    else if (han >= 6) { base = 3000; limitName = "跳満"; }
    else if (han >= 5 || (han === 4 && fu >= 40) || (han === 3 && fu >= 70)) { base = 2000; limitName = "満貫"; }
    else { base = fu * Math.pow(2, han + 2); }

    const ceil100 = (value) => Math.ceil(value / 100) * 100;
    if (type === "ron") {
      const points = ceil100(base * (isDealer ? 6 : 4)) + state.honba * 300;
      return { points, limitName, detail: `ロン ${points.toLocaleString()}点` };
    }
    if (isDealer) {
      const each = ceil100(base * 2) + state.honba * 100;
      return { dealerEach: each, childEach: each, total: each * 3, limitName, detail: `親ツモ ${each.toLocaleString()}点オール` };
    }
    const dealerPays = ceil100(base * 2) + state.honba * 100;
    const childPays = ceil100(base) + state.honba * 100;
    return { dealerPays, childPays, total: dealerPays + childPays * 2, limitName, detail: `子ツモ 親${dealerPays.toLocaleString()} / 子${childPays.toLocaleString()}点` };
  }



  function calculateYakumanPoints(times, isDealer, type) {
    const base = 8000 * times;
    const ceil100 = (value) => Math.ceil(value / 100) * 100;
    const name = times >= 2 ? `${times}倍役満` : "役満";
    if (type === "ron") {
      const points = ceil100(base * (isDealer ? 6 : 4)) + state.honba * 300;
      return { points, limitName: name, detail: `ロン ${points.toLocaleString()}点` };
    }
    if (isDealer) {
      const each = ceil100(base * 2) + state.honba * 100;
      return { dealerEach: each, childEach: each, total: each * 3, limitName: name, detail: `親ツモ ${each.toLocaleString()}点オール` };
    }
    const dealerPays = ceil100(base * 2) + state.honba * 100;
    const childPays = ceil100(base) + state.honba * 100;
    return { dealerPays, childPays, total: dealerPays + childPays * 2, limitName: name, detail: `子ツモ 親${dealerPays.toLocaleString()} / 子${childPays.toLocaleString()}点` };
  }

  function createPlayers() {
    return PLAYER_NAMES.map((name, index) => ({
      name,
      index,
      score: 25000,
      hand: [],
      discards: [],
      melds: [],
      riichi: false,
      open: false,
      lastDrawId: null,
      kuikaeForbidden: [],
      skippedRonKeys: []
    }));
  }

  function resetForRound() {
    state.players.forEach((player) => {
      player.hand = [];
      player.discards = [];
      player.melds = [];
      player.riichi = false;
      player.open = false;
      player.lastDrawId = null;
      player.kuikaeForbidden = [];
      player.skippedRonKeys = [];
    });
    state.wall = buildWall();
    state.doraIndicators = [state.wall.pop()];
    state.doraIndicator = state.doraIndicators[0];
    state.doraKey = nextDoraKey(state.doraIndicator.key);
    state.lastDiscard = null;
    state.pendingCalls = [];
    state.riichiMode = false;
    state.phase = "deal";
    state.current = state.dealer;
    state.message = "配牌しました。親から開始します。";

    for (let round = 0; round < 13; round += 1) {
      for (let p = 0; p < 4; p += 1) state.players[p].hand.push(state.wall.pop());
    }
    state.players[state.dealer].hand.push(state.wall.pop());
    state.players.forEach(sortHand);
    addLog(`${roundName()} 開始。ドラ表示は ${state.doraIndicator.label}、ドラは ${labelForKey(state.doraKey)}。`);
  }

  function newGame() {
    state.players = createPlayers();
    state.dealer = 0;
    state.roundIndex = 0;
    state.honba = 0;
    state.riichiSticks = 0;
    state.log = [];
    $("resultModal").classList.add("hidden");
    startRound();
  }

  function startRound() {
    if (state.roundIndex >= 4 || state.players.some((player) => player.score < 0)) {
      showFinalResult();
      return;
    }
    resetForRound();
    render();
    beginTurn(state.current);
  }

  function roundName() {
    return `東${state.roundIndex + 1}局 ${state.honba}本場`;
  }

  function addLog(text) {
    state.log.unshift(text);
    state.log = state.log.slice(0, 80);
  }

  function drawTile(playerIndex) {
    const player = state.players[playerIndex];
    if (state.wall.length <= 0) {
      endInDraw();
      return null;
    }
    const tile = state.wall.pop();
    player.hand.push(tile);
    player.lastDrawId = tile.id;
    state.lastDrawTileId = tile.id;
    sortHand(player);
    return tile;
  }

  async function beginTurn(playerIndex) {
    if (state.locked) return;
    state.current = playerIndex;
    const player = state.players[playerIndex];
    player.skippedRonKeys = [];
    state.pendingCalls = [];
    state.riichiMode = false;

    const effectiveTiles = player.hand.length + player.melds.length * 3;
    if (effectiveTiles % 3 === 1) {
      const drawn = drawTile(playerIndex);
      if (!drawn) return;
      addLog(`${player.name} がツモ。`);
    }

    const win = evaluateWin(playerIndex, "tsumo");
    if (win.valid) {
      if (playerIndex === 0) {
        state.phase = "discard";
        state.message = "ツモ和了できます。練習として続ける場合は牌を捨ててもOKです。";
        render();
        return;
      }
      await sleep(500);
      processWin(playerIndex, "tsumo", null, win);
      return;
    }

    if (playerIndex === 0) {
      state.phase = "discard";
      state.message = player.riichi ? "リーチ後です。ツモ切りします。" : beginnerHintForUser();
      render();
      return;
    }

    state.phase = "cpu";
    state.message = `${player.name} が考えています。`;
    render();
    await sleep(650);
    cpuTurn(playerIndex);
  }

  function beginnerHintForUser() {
    const player = state.players[0];
    if (canDeclareRiichi(player)) return "テンパイしています。リーチを押してから安全そうな牌を切る練習をしましょう。";
    if (isHandTenpai(player)) return "テンパイに近い形です。対子や連続形を残しましょう。";
    return "不要牌を1枚切ります。初心者は字牌・1/9牌・孤立牌から切ると進めやすいです。";
  }

  function userDiscard(tileId) {
    if (state.phase !== "discard" || state.current !== 0) return;
    const player = state.players[0];
    const tileIndex = player.hand.findIndex((tile) => tile.id === tileId);
    if (tileIndex < 0) return;

    if ((player.kuikaeForbidden || []).includes(player.hand[tileIndex].key)) {
      state.message = "喰い替え禁止です。鳴いた直後に同じ筋・構成牌をすぐ切ることはできません。";
      render();
      return;
    }

    if (state.riichiMode && !isTenpaiAfterDiscard(player, tileIndex)) {
      state.message = "その牌を切るとテンパイが崩れるため、リーチ宣言では切れません。";
      render();
      return;
    }
    if (player.riichi && !state.riichiMode && player.lastDrawId && tileId !== player.lastDrawId) {
      state.message = "リーチ後はツモ切りのみです。ツモ牌を切ってください。";
      render();
      return;
    }

    if (state.riichiMode && !player.riichi) {
      player.riichi = true;
      player.score -= 1000;
      state.riichiSticks += 1;
      addLog("あなたがリーチを宣言。供託に1,000点。延長線上の選択はツモ切りになります。");
    }

    discardTile(0, tileIndex);
  }

  function discardTile(playerIndex, tileIndex) {
    const player = state.players[playerIndex];
    const [tile] = player.hand.splice(tileIndex, 1);
    player.discards.push(tile);
    player.lastDrawId = null;
    player.kuikaeForbidden = [];
    state.lastDiscard = { tile, playerIndex };
    state.riichiMode = false;
    sortHand(player);
    addLog(`${player.name} 打 ${tile.label}`);
    afterDiscard(playerIndex, tile);
  }

  async function afterDiscard(discarderIndex, tile) {
    state.phase = "reaction";
    render();

    const ronCandidates = [];
    for (let i = 1; i <= 3; i += 1) {
      const playerIndex = (discarderIndex + i) % 4;
      if (playerIndex === discarderIndex) continue;
      const win = evaluateWin(playerIndex, "ron", tile, discarderIndex);
      if (win.valid) ronCandidates.push({ playerIndex, win });
    }

    const userRon = ronCandidates.find((candidate) => candidate.playerIndex === 0);
    const cpuRon = ronCandidates.find((candidate) => candidate.playerIndex !== 0);
    if (userRon) {
      state.pendingCalls = [{ type: "ron", label: "ロン", tile, from: discarderIndex, win: userRon.win }];
    } else if (cpuRon) {
      await sleep(500);
      processWin(cpuRon.playerIndex, "ron", discarderIndex, cpuRon.win);
      return;
    }

    if (discarderIndex !== 0) {
      state.pendingCalls.push(...availableUserCalls(discarderIndex, tile));
    }

    if (state.pendingCalls.length > 0) {
      state.phase = "call";
      state.message = `${state.players[discarderIndex].name} の ${tile.label} に対して、鳴き/ロンを選べます。迷ったらスキップでOKです。`;
      render();
      return;
    }

    const calledByCpu = tryCpuCall(discarderIndex, tile);
    if (calledByCpu) return;
    beginTurn((discarderIndex + 1) % 4);
  }

  function availableUserCalls(discarderIndex, tile) {
    const player = state.players[0];
    if (player.riichi) return [];
    const calls = [];
    const same = player.hand.filter((handTile) => handTile.key === tile.key);
    if (same.length >= 3) calls.push({ type: "kan", label: "カン", tile, from: discarderIndex, needed: [same[0].id, same[1].id, same[2].id] });
    if (same.length >= 2) calls.push({ type: "pon", label: "ポン", tile, from: discarderIndex, needed: [same[0].id, same[1].id] });

    const previousPlayer = 3;
    if (discarderIndex === previousPlayer && tile.suit !== "z") {
      const r = tile.rank;
      const patterns = [[r - 2, r - 1], [r - 1, r + 1], [r + 1, r + 2]];
      patterns.forEach((ranks) => {
        if (ranks.every((rank) => rank >= 1 && rank <= 9)) {
          const first = player.hand.find((handTile) => handTile.suit === tile.suit && handTile.rank === ranks[0]);
          const second = player.hand.find((handTile) => handTile.suit === tile.suit && handTile.rank === ranks[1] && handTile.id !== first?.id);
          if (first && second) {
            calls.push({ type: "chi", label: `チー ${ranks[0]}-${r}-${ranks[1]}`, tile, from: discarderIndex, needed: [first.id, second.id] });
          }
        }
      });
    }
    return calls;
  }



  function rinshanDraw(playerIndex) {
    const player = state.players[playerIndex];
    const tile = drawTile(playerIndex);
    if (!tile) return;
    const indicator = addDoraIndicator();
    addLog(`${player.name} が嶺上牌をツモ。${indicator ? `新ドラ表示 ${indicator.label}` : ""}`);
  }

  function userClosedKan(key) {
    const player = state.players[0];
    if (state.phase !== "discard" || !canClosedKan(player).includes(key)) return;
    const tiles = [];
    for (let i = player.hand.length - 1; i >= 0; i -= 1) {
      if (player.hand[i].key === key) tiles.push(player.hand.splice(i, 1)[0]);
    }
    player.melds.push({ type: "kan", tiles: tiles.sort(compareTiles), from: 0, open: false });
    sortHand(player);
    addLog(`あなたが${labelForKey(key)}を暗槓。`);
    rinshanDraw(0);
    state.message = "カンしました。嶺上牌を引き、新ドラが増えました。続けて1枚切ってください。";
    render();
  }

  function userAddedKan(key) {
    const player = state.players[0];
    if (state.phase !== "discard" || !canAddedKan(player).includes(key)) return;
    const tileIndex = player.hand.findIndex((tile) => tile.key === key);
    const meld = player.melds.find((m) => m.type === "pon" && m.tiles[0].key === key);
    if (tileIndex < 0 || !meld) return;
    meld.type = "kan";
    meld.tiles.push(player.hand.splice(tileIndex, 1)[0]);
    meld.open = true;
    addLog(`あなたが${labelForKey(key)}を加槓。`);
    rinshanDraw(0);
    state.message = "加槓しました。嶺上牌を引き、新ドラが増えました。続けて1枚切ってください。";
    render();
  }

  function userOpenKan(index) {
    const call = state.pendingCalls[index];
    if (!call || call.type !== "kan") return;
    const player = state.players[0];
    const taken = state.players[call.from].discards.pop();
    const tiles = [taken];
    call.needed.forEach((id) => {
      const idx = player.hand.findIndex((tile) => tile.id === id);
      if (idx >= 0) tiles.push(player.hand.splice(idx, 1)[0]);
    });
    player.melds.push({ type: "kan", tiles: tiles.sort(compareTiles), from: call.from, open: true });
    player.open = true;
    sortHand(player);
    state.current = 0;
    state.phase = "discard";
    state.pendingCalls = [];
    addLog(`あなたが ${taken.label} を大明槓。`);
    rinshanDraw(0);
    state.message = "大明槓しました。嶺上牌を引いたので1枚捨てます。";
    render();
  }

  function userCall(index) {
    const call = state.pendingCalls[index];
    if (!call) return;
    if (call.type === "ron") {
      processWin(0, "ron", call.from, call.win);
      return;
    }
    if (call.type === "kan") {
      userOpenKan(index);
      return;
    }
    const player = state.players[0];
    const taken = state.players[call.from].discards.pop();
    const tiles = [taken];
    call.needed.forEach((id) => {
      const idx = player.hand.findIndex((tile) => tile.id === id);
      if (idx >= 0) tiles.push(player.hand.splice(idx, 1)[0]);
    });
    player.melds.push({ type: call.type, tiles: tiles.sort(compareTiles), from: call.from, open: true });
    player.kuikaeForbidden = call.type === "chi" ? [...new Set(tiles.map((t) => t.key))] : [taken.key];
    player.open = true;
    sortHand(player);
    state.current = 0;
    state.phase = "discard";
    state.pendingCalls = [];
    state.message = `${call.label}しました。鳴いた後は手牌から1枚捨てます。`;
    addLog(`あなたが ${taken.label} を${call.label}。`);
    render();
  }

  function skipUserCall() {
    const discard = state.lastDiscard;
    if (state.pendingCalls.some((call) => call.type === "ron") && state.lastDiscard) {
      const p = state.players[0];
      p.skippedRonKeys = [...new Set([...(p.skippedRonKeys || []), state.lastDiscard.tile.key])];
      addLog(`あなたはロンを見送り。一時フリテンとして ${state.lastDiscard.tile.label} ではロンできません。`);
    }
    state.pendingCalls = [];
    state.phase = "reaction";
    if (discard && tryCpuCall(discard.playerIndex, discard.tile)) return;
    beginTurn((discard.playerIndex + 1) % 4);
  }

  function tryCpuCall(discarderIndex, tile) {
    if (!tile) return false;
    for (let i = 1; i <= 3; i += 1) {
      const playerIndex = (discarderIndex + i) % 4;
      if (playerIndex === 0 || playerIndex === discarderIndex) continue;
      const player = state.players[playerIndex];
      if (player.riichi) continue;
      const same = player.hand.filter((handTile) => handTile.key === tile.key);
      const isValue = ["z5", "z6", "z7", windKeyForPlayer(playerIndex), roundWindKey()].includes(tile.key);
      if (same.length >= 3 && (isValue || Math.random() < 0.08)) {
        cpuMakeCall(playerIndex, discarderIndex, tile, "kan", [same[0].id, same[1].id, same[2].id]);
        return true;
      }
      if (same.length >= 2 && (isValue || Math.random() < 0.18)) {
        cpuMakeCall(playerIndex, discarderIndex, tile, "pon", [same[0].id, same[1].id]);
        return true;
      }
    }

    const nextPlayer = (discarderIndex + 1) % 4;
    if (nextPlayer !== 0) {
      const player = state.players[nextPlayer];
      if (!player.riichi && tile.suit !== "z") {
        const calls = cpuChiCandidates(player, tile);
        if (calls.length > 0 && Math.random() < 0.22) {
          cpuMakeCall(nextPlayer, discarderIndex, tile, "chi", calls[0]);
          return true;
        }
      }
    }
    return false;
  }

  function cpuChiCandidates(player, tile) {
    const r = tile.rank;
    const patterns = [[r - 2, r - 1], [r - 1, r + 1], [r + 1, r + 2]];
    const candidates = [];
    patterns.forEach((ranks) => {
      if (!ranks.every((rank) => rank >= 1 && rank <= 9)) return;
      const first = player.hand.find((handTile) => handTile.suit === tile.suit && handTile.rank === ranks[0]);
      const second = player.hand.find((handTile) => handTile.suit === tile.suit && handTile.rank === ranks[1] && handTile.id !== first?.id);
      if (first && second) candidates.push([first.id, second.id]);
    });
    return candidates;
  }

  async function cpuMakeCall(playerIndex, fromIndex, tile, type, neededIds) {
    const player = state.players[playerIndex];
    const taken = state.players[fromIndex].discards.pop();
    const tiles = [taken];
    neededIds.forEach((id) => {
      const idx = player.hand.findIndex((handTile) => handTile.id === id);
      if (idx >= 0) tiles.push(player.hand.splice(idx, 1)[0]);
    });
    player.melds.push({ type, tiles: tiles.sort(compareTiles), from: fromIndex, open: true });
    player.kuikaeForbidden = type === "chi" ? [...new Set(tiles.map((t) => t.key))] : [taken.key];
    player.open = true;
    sortHand(player);
    state.current = playerIndex;
    state.phase = "cpu";
    state.message = `${player.name} が ${type === "pon" ? "ポン" : "チー"}。`;
    addLog(`${player.name} が ${taken.label} を${type === "pon" ? "ポン" : "チー"}。`);
    if (type === "kan") rinshanDraw(playerIndex);
    render();
    await sleep(650);
    cpuDiscard(playerIndex);
  }



  function cpuKan(playerIndex, key, added) {
    const player = state.players[playerIndex];
    if (added) {
      const idx = player.hand.findIndex((tile) => tile.key === key);
      const meld = player.melds.find((m) => m.type === "pon" && m.tiles[0].key === key);
      if (idx >= 0 && meld) {
        meld.type = "kan";
        meld.tiles.push(player.hand.splice(idx, 1)[0]);
        meld.open = true;
        addLog(`${player.name} が${labelForKey(key)}を加槓。`);
        rinshanDraw(playerIndex);
      }
    } else {
      const tiles = [];
      for (let i = player.hand.length - 1; i >= 0; i -= 1) {
        if (player.hand[i].key === key) tiles.push(player.hand.splice(i, 1)[0]);
      }
      if (tiles.length === 4) {
        player.melds.push({ type: "kan", tiles: tiles.sort(compareTiles), from: playerIndex, open: false });
        addLog(`${player.name} が暗槓。`);
        rinshanDraw(playerIndex);
      }
    }
    sortHand(player);
  }

  function cpuTurn(playerIndex) {
    const player = state.players[playerIndex];
    if (!player.riichi) {
      const added = canAddedKan(player)[0];
      const closed = canClosedKan(player)[0];
      if ((added || closed) && Math.random() < 0.18) {
        cpuKan(playerIndex, added || closed, Boolean(added));
      }
    }
    if (!player.riichi && canDeclareRiichi(player) && Math.random() < 0.35) {
      player.riichi = true;
      player.score -= 1000;
      state.riichiSticks += 1;
      addLog(`${player.name} がリーチ。`);
    }
    cpuDiscard(playerIndex);
  }

  function cpuDiscard(playerIndex) {
    const player = state.players[playerIndex];
    let idx;
    if (player.riichi && player.lastDrawId) {
      idx = player.hand.findIndex((tile) => tile.id === player.lastDrawId);
    }
    if (idx == null || idx < 0) idx = chooseDiscardIndex(player);
    discardTile(playerIndex, idx);
  }

  function chooseDiscardIndex(player) {
    let bestIndex = 0;
    let bestScore = -Infinity;
    const forbidden = new Set(player.kuikaeForbidden || []);
    player.hand.forEach((tile, index) => {
      if (forbidden.has(tile.key) && player.hand.length > 1) return;
      const after = player.hand.filter((_, i) => i !== index);
      const waits = waitingKeysFor(player, after).length;
      const shape = totalShapeValue(after);
      const safety = defensiveValue(tile, player.index);
      const danger = dangerValue(tile);
      const score = waits * 12 + shape + safety - danger + Math.random() * 0.5;
      if (score > bestScore) { bestScore = score; bestIndex = index; }
    });
    return bestIndex;
  }

  function totalShapeValue(hand) {
    return hand.reduce((sum, tile) => sum + tileKeepScore(hand, tile), 0);
  }

  function dangerValue(tile) {
    // 高度CPU読みの簡易版：リーチ者の現物は安全、終盤の生牌字牌・ドラ周辺は危険とみなす
    let danger = 0;
    state.players.forEach((op) => {
      if (op.index === 0) return;
      if (op.riichi && op.discards.some((d) => d.key === tile.key)) danger -= 5;
      if (op.riichi && !op.discards.some((d) => d.key === tile.key)) danger += 2.5;
    });
    if (doraKeys().includes(tile.key)) danger += 3;
    if (tile.suit === "z" && state.players.flatMap(p => p.discards).filter(d => d.key === tile.key).length === 0) danger += 1.5;
    return danger;
  }

  function defensiveValue(tile, selfIndex) {
    let value = 0;
    state.players.forEach((op) => {
      if (op.index === selfIndex) return;
      if (op.discards.some((d) => d.key === tile.key)) value += op.riichi ? 6 : 1;
    });
    return value;
  }

  function tileKeepScore(hand, tile) {
    const same = hand.filter((other) => other.key === tile.key).length - 1;
    let score = same * 6;
    if (tile.suit === "z") {
      const isValue = ["z5", "z6", "z7"].includes(tile.key);
      score += isValue ? 1.5 : 0;
      return score - 2.5;
    }
    const neighbor1 = hand.some((other) => other.suit === tile.suit && Math.abs(other.rank - tile.rank) === 1);
    const neighbor2 = hand.some((other) => other.suit === tile.suit && Math.abs(other.rank - tile.rank) === 2);
    if (neighbor1) score += 3.2;
    if (neighbor2) score += 1.6;
    if (tile.rank === 1 || tile.rank === 9) score -= 2.2;
    if (tile.rank === 2 || tile.rank === 8) score -= 0.8;
    return score;
  }

  function isTenpaiAfterDiscard(player, discardIndex) {
    if (player.melds.length > 0) return false;
    const base = player.hand.filter((_, index) => index !== discardIndex);
    return ALL_KEYS.some((key) => canWinWithMelds([...base, tileFromKey(key)], player.melds));
  }

  function canDeclareRiichi(player) {
    if (player.melds.length > 0 || player.riichi || player.score < 1000) return false;
    if (player.hand.length !== 14) return false;
    return player.hand.some((_, index) => isTenpaiAfterDiscard(player, index));
  }

  function isHandTenpai(player) {
    if ((player.hand.length + player.melds.length * 3) % 3 !== 1) return false;
    return ALL_KEYS.some((key) => canWinWithMelds([...player.hand, tileFromKey(key)], player.melds));
  }

  function processWin(winnerIndex, type, fromIndex, win) {
    const winner = state.players[winnerIndex];
    const bonus = state.riichiSticks * 1000;
    if (type === "ron") {
      const loser = state.players[fromIndex];
      loser.score -= win.score.points;
      winner.score += win.score.points + bonus;
    } else if (winnerIndex === state.dealer) {
      state.players.forEach((player, index) => {
        if (index !== winnerIndex) player.score -= win.score.dealerEach;
      });
      winner.score += win.score.dealerEach * 3 + bonus;
    } else {
      state.players.forEach((player, index) => {
        if (index === winnerIndex) return;
        const pay = index === state.dealer ? win.score.dealerPays : win.score.childPays;
        player.score -= pay;
        winner.score += pay;
      });
      winner.score += bonus;
    }
    state.riichiSticks = 0;

    const title = `${winner.name} の${type === "ron" ? "ロン" : "ツモ"}和了`;
    addLog(`${title}：${win.han}翻${win.fu}符 ${win.score.detail}`);
    render();
    showResult(title, win, winnerIndex, fromIndex);
  }

  function showResult(title, win, winnerIndex, fromIndex) {
    const body = $("resultBody");
    const fromText = win.type === "ron" ? `<p>放銃：${state.players[fromIndex].name}</p>` : "<p>ツモ和了です。</p>";
    const yakuList = win.yakus.map((yaku) => `<li><strong>${yaku.name}</strong>：${yaku.han}翻 <span class="badge">${yaku.note}</span></li>`).join("");
    body.innerHTML = `
      ${fromText}
      <p><strong>${win.han}翻 ${win.fu}符</strong> / ${win.score.limitName ? `${win.score.limitName} / ` : ""}${win.score.detail}</p>
      <ul class="result-list">${yakuList}</ul>
      <p><strong>符計算</strong>：${(win.fuDetail || []).join(" / ")}</p>
      <p>初心者メモ：和了には「形」と「役」の両方が必要です。フリテン中はロン不可、鳴いた直後は喰い替え禁止になります。</p>
    `;
    $("resultTitle").textContent = title;
    $("resultModal").classList.remove("hidden");

    if (winnerIndex === state.dealer) {
      state.honba += 1;
    } else {
      state.roundIndex += 1;
      state.dealer = (state.dealer + 1) % 4;
      state.honba = 0;
    }
  }

  function endInDraw() {
    addLog(`${roundName()} は流局。`);
    state.roundIndex += 1;
    state.dealer = (state.dealer + 1) % 4;
    state.honba = 0;
    render();
    $("resultTitle").textContent = "流局";
    $("resultBody").innerHTML = `<p>山がなくなりました。今回はテンパイ料は省略し、次の局へ進みます。</p>`;
    $("resultModal").classList.remove("hidden");
  }

  function showFinalResult() {
    const ranking = [...state.players].sort((a, b) => b.score - a.score);
    const body = ranking.map((player, index) => `<li>${index + 1}位：${player.name} ${player.score.toLocaleString()}点</li>`).join("");
    $("resultTitle").textContent = "東風戦 終了";
    $("resultBody").innerHTML = `<ol class="result-list">${body}</ol><p>もう一度練習する場合は「最初から」を押してください。</p>`;
    $("resultModal").classList.remove("hidden");
  }

  function nextRound() {
    $("resultModal").classList.add("hidden");
    startRound();
  }

  function setRiichiMode() {
    if (!canDeclareRiichi(state.players[0])) return;
    state.riichiMode = true;
    state.message = "リーチ宣言中です。テンパイを維持できる牌だけ選べます。";
    render();
  }

  function cancelRiichiMode() {
    state.riichiMode = false;
    state.message = beginnerHintForUser();
    render();
  }

  function render() {
    renderScoreboard();
    renderStatus();
    renderOpponents();
    renderPlayerArea();
    renderActions();
    renderLog();
  }

  function renderScoreboard() {
    $("scoreboard").innerHTML = state.players.map((player, index) => {
      const seat = labelForKey(windKeyForPlayer(index));
      const badges = [seat, player.riichi ? "リーチ" : "", player.melds.length ? `鳴き${player.melds.length}` : ""].filter(Boolean).join(" / ");
      return `<div class="score-card ${state.current === index ? "active" : ""}">
        <div class="name">${player.name}</div>
        <div class="score">${player.score.toLocaleString()}</div>
        <div class="meta">${badges}</div>
      </div>`;
    }).join("");
  }

  function renderStatus() {
    $("roundTitle").textContent = `${roundName()} / 供託${state.riichiSticks}本`;
    $("wallCount").textContent = `${state.wall.length}枚`;
    const user = state.players[0];
    const status = user.riichi ? "リーチ中" : user.melds.length ? "鳴き手" : "門前";
    $("playerState").textContent = status;
    $("message").textContent = state.message;
    $("doraIndicator").textContent = state.doraIndicators ? state.doraIndicators.map((t) => t.label).join(" / ") : (state.doraIndicator ? state.doraIndicator.label : "?");
    $("lastDiscard").textContent = state.lastDiscard ? `直前の捨て牌：${state.players[state.lastDiscard.playerIndex].name} → ${state.lastDiscard.tile.label}` : "直前の捨て牌：なし";
  }

  function renderOpponents() {
    renderOpponent("cpu1", 1);
    renderOpponent("cpu2", 2);
    renderOpponent("cpu3", 3);
  }

  function renderOpponent(elementId, playerIndex) {
    const player = state.players[playerIndex];
    const hiddenCount = player.hand.length;
    const backTiles = Array.from({ length: Math.min(hiddenCount, 14) }, () => `<span class="back-tile"></span>`).join("");
    const melds = player.melds.map(renderMeld).join("");
    const discardTiles = player.discards.slice(-10).map((tile) => renderTile(tile, { small: true })).join("");
    $(elementId).innerHTML = `
      <div class="opponent-title"><span>${player.name}</span><span>${labelForKey(windKeyForPlayer(playerIndex))}</span></div>
      <div class="opponent-stats">手牌${hiddenCount}枚 / 捨て牌${player.discards.length}枚 ${player.riichi ? " / リーチ" : ""}</div>
      <div class="back-tiles">${backTiles}</div>
      <div class="melds">${melds}</div>
      <div class="discards">${discardTiles}</div>
    `;
  }

  function renderPlayerArea() {
    const player = state.players[0];
    $("handGuide").textContent = state.phase === "discard" && state.current === 0 ? "牌をタップして打牌" : "他家の番です";
    const tenpaiText = canWinWithMelds(player.hand, player.melds) ? "和了形" : canDeclareRiichi(player) || isHandTenpai(player) ? "テンパイ" : "進行中";
    $("handStats").textContent = `${tenpaiText} / 手牌${player.hand.length}枚 / 鳴き${player.melds.length}`;
    $("userMelds").innerHTML = player.melds.map(renderMeld).join("");
    $("hand").innerHTML = player.hand.map((tile, index) => {
      const disabled = isUserTileDisabled(player, tile, index);
      const drawn = tile.id === player.lastDrawId;
      return renderTile(tile, { button: true, disabled, drawn, onClick: `window.mahjongApp.userDiscard('${tile.id}')` });
    }).join("");
    $("userDiscards").innerHTML = player.discards.map((tile) => renderTile(tile, { small: true })).join("");
  }

  function isUserTileDisabled(player, tile, index) {
    if (state.phase !== "discard" || state.current !== 0) return true;
    if ((player.kuikaeForbidden || []).includes(tile.key)) return true;
    if (state.riichiMode) return !isTenpaiAfterDiscard(player, index);
    if (player.riichi && player.lastDrawId) return tile.id !== player.lastDrawId;
    return false;
  }

  function tileClass(tile) {
    if (tile.suit === "m") return "man";
    if (tile.suit === "p") return "pin";
    if (tile.suit === "s") return "sou";
    if ([5, 6, 7].includes(tile.rank)) return "honor-red";
    return "honor";
  }

  function renderTile(tile, options = {}) {
    const classes = ["tile", tileClass(tile)];
    if (options.disabled) classes.push("disabled");
    if (options.drawn) classes.push("drawn");
    const content = options.button && !options.disabled
      ? `<button aria-label="${tile.label}を切る" onclick="${options.onClick}">${tile.label}</button>`
      : tile.label;
    return `<span class="${classes.join(" ")}">${content}</span>`;
  }

  function renderMeld(meld) {
    const label = meld.type === "kan" ? "槓" : meld.type === "pon" ? "ポン" : "チー";
    return `<span class="meld" title="${label}"><b>${label}</b>${meld.tiles.map((tile) => renderTile(tile)).join("")}</span>`;
  }

  function renderActions() {
    const panel = $("actionPanel");
    const player = state.players[0];
    const buttons = [];

    if (state.phase === "discard" && state.current === 0) {
      const tsumo = evaluateWin(0, "tsumo");
      if (tsumo.valid) buttons.push(`<button class="action-btn good" onclick="window.mahjongApp.tsumo()">ツモ</button>`);
      canClosedKan(player).forEach((key) => buttons.push(`<button class="action-btn" onclick="window.mahjongApp.closedKan('${key}')">暗槓 ${labelForKey(key)}</button>`));
      canAddedKan(player).forEach((key) => buttons.push(`<button class="action-btn" onclick="window.mahjongApp.addedKan('${key}')">加槓 ${labelForKey(key)}</button>`));
      if (!state.riichiMode && canDeclareRiichi(player)) buttons.push(`<button class="action-btn" onclick="window.mahjongApp.riichi()">リーチ</button>`);
      if (state.riichiMode) buttons.push(`<button class="action-btn secondary" onclick="window.mahjongApp.cancelRiichi()">リーチ取消</button>`);
    }

    if (state.phase === "call") {
      state.pendingCalls.forEach((call, index) => {
        const extra = call.type === "ron" ? "good" : "";
        buttons.push(`<button class="action-btn ${extra}" onclick="window.mahjongApp.call(${index})">${call.label}</button>`);
      });
      buttons.push(`<button class="action-btn secondary" onclick="window.mahjongApp.skip()">スキップ</button>`);
    }

    panel.innerHTML = buttons.join("");
  }

  function renderLog() {
    $("gameLog").innerHTML = state.log.map((item) => `<li>${item}</li>`).join("");
  }

  window.mahjongApp = {
    userDiscard,
    tsumo: () => {
      const win = evaluateWin(0, "tsumo");
      if (win.valid) processWin(0, "tsumo", null, win);
    },
    riichi: setRiichiMode,
    cancelRiichi: cancelRiichiMode,
    closedKan: userClosedKan,
    addedKan: userAddedKan,
    call: userCall,
    skip: skipUserCall,
    nextRound,
    newGame
  };

  $("newGameBtn").addEventListener("click", newGame);
  $("nextRoundBtn").addEventListener("click", nextRound);

  if ("serviceWorker" in navigator) {
    window.addEventListener("load", () => {
      navigator.serviceWorker.register("service-worker.js").catch(() => {});
    });
  }

  newGame();
})();
