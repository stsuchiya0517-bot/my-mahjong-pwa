(() => {
  "use strict";

  const UX = {
    selectedTileText: null,
    selectedAt: 0,
    lastMessage: "",
    lastDiscardText: "",
    toastTimer: null,
    observer: null,
  };

  const $ = (id) => document.getElementById(id);
  const qs = (selector, root = document) => root.querySelector(selector);
  const qsa = (selector, root = document) => Array.from(root.querySelectorAll(selector));

  function tileText(tileEl) {
    if (!tileEl) return "";
    const button = qs("button", tileEl);
    return (button ? button.textContent : tileEl.textContent || "").trim();
  }

  function ensureToast() {
    let toast = $("uxToast");
    if (!toast) {
      toast = document.createElement("div");
      toast.id = "uxToast";
      toast.className = "ux-toast";
      document.body.appendChild(toast);
    }
    return toast;
  }

  function showToast(text) {
    if (!text) return;
    const toast = ensureToast();
    toast.textContent = text;
    toast.classList.remove("is-visible");
    window.clearTimeout(UX.toastTimer);
    requestAnimationFrame(() => toast.classList.add("is-visible"));
    UX.toastTimer = window.setTimeout(() => toast.classList.remove("is-visible"), 1900);
  }

  function ensureFloatingActionBar() {
    let bar = $("uxFloatingActionBar");
    if (!bar) {
      bar = document.createElement("div");
      bar.id = "uxFloatingActionBar";
      bar.className = "ux-floating-action-bar";
      bar.setAttribute("aria-live", "polite");
      document.body.appendChild(bar);
    }
    return bar;
  }

  function cloneActionButton(button) {
    const clone = button.cloneNode(true);
    clone.removeAttribute("id");
    clone.addEventListener("click", (event) => {
      event.preventDefault();
      button.click();
    });
    return clone;
  }

  function updateFloatingActionBar() {
    const source = $("actionPanel");
    const bar = ensureFloatingActionBar();
    if (!source) return;
    const buttons = qsa("button", source).filter((button) => !button.disabled);
    bar.innerHTML = "";

    if (buttons.length === 0) {
      bar.classList.remove("is-visible");
      document.body.classList.remove("ux-action-bar-active");
      return;
    }

    buttons.slice(0, 4).forEach((button) => bar.appendChild(cloneActionButton(button)));
    bar.classList.add("is-visible");
    document.body.classList.add("ux-action-bar-active");
  }

  function parseCurrentPlayerName() {
    const scoreActive = qs(".score-card.active .name") || qs(".score-card.ux-active-player .name");
    if (scoreActive) return scoreActive.textContent.trim();
    const playerState = $("playerState")?.textContent?.trim() || "";
    if (playerState.includes("あなた")) return "あなた";
    return "";
  }

  function enhanceTurnVisibility() {
    qsa(".score-card, .opponent").forEach((el) => {
      el.classList.remove("ux-active-player", "ux-thinking");
    });
    qs(".player-area")?.classList.remove("ux-player-turn");

    const activeCard = qs(".score-card.active");
    const currentName = parseCurrentPlayerName();
    if (activeCard) activeCard.classList.add("ux-active-player");

    if (currentName && currentName !== "あなた") {
      const opponent = qsa(".opponent").find((el) => el.textContent.includes(currentName));
      if (opponent) {
        opponent.classList.add("ux-active-player", "ux-thinking");
      }
      if (activeCard) activeCard.classList.add("ux-thinking");
    } else {
      qs(".player-area")?.classList.add("ux-player-turn");
    }

    const center = qs(".center-panel");
    if (center && !qs(".ux-turn-ribbon", center)) {
      const ribbon = document.createElement("div");
      ribbon.className = "ux-turn-ribbon";
      ribbon.id = "uxTurnRibbon";
      center.appendChild(ribbon);
    }
    const ribbon = $("uxTurnRibbon");
    if (ribbon) ribbon.textContent = currentName && currentName !== "あなた" ? `${currentName}の手番` : "あなたの手番";
  }

  function enhanceMessageMotion() {
    const message = $("message");
    if (!message) return;
    const text = message.textContent.trim();
    if (text && text !== UX.lastMessage) {
      UX.lastMessage = text;
      message.classList.remove("ux-message-pop");
      void message.offsetWidth;
      message.classList.add("ux-message-pop");
      if (/捨て|打牌|リーチ|ポン|チー|カン|ロン|ツモ|和了/.test(text)) showToast(text.replace(/\s+/g, " "));
    }
  }

  function enhanceRecentDiscard() {
    const lastDiscard = $("lastDiscard");
    const text = lastDiscard?.textContent?.trim() || "";
    qsa(".ux-recent-discard").forEach((el) => el.classList.remove("ux-recent-discard"));

    if (!text) return;
    if (text !== UX.lastDiscardText) {
      UX.lastDiscardText = text;
      if (/捨て|打牌|discard/i.test(text)) showToast(text.replace(/\s+/g, " "));
    }

    const allDiscards = qsa(".discards .tile");
    const latestTile = allDiscards[allDiscards.length - 1];
    if (latestTile) latestTile.classList.add("ux-recent-discard");
    qsa(".last-discard .tile").forEach((tile) => tile.classList.add("ux-recent-discard"));
  }

  function enhanceDrawnTile() {
    qsa(".hand .tile").forEach((tile) => tile.classList.remove("ux-drawn"));
    const drawn = qs(".hand .tile.drawn");
    if (drawn) drawn.classList.add("ux-drawn");
    else {
      const handTiles = qsa(".hand .tile");
      if (handTiles.length % 3 === 2 && handTiles.length > 0) {
        handTiles[handTiles.length - 1].classList.add("ux-drawn");
      }
    }
  }

  function markSelectedTile() {
    qsa(".hand .tile").forEach((tile) => {
      const isSelected = UX.selectedTileText && tileText(tile) === UX.selectedTileText;
      tile.classList.toggle("ux-selected", Boolean(isSelected));
    });
  }

  function wireTileSelection() {
    const hand = $("hand");
    if (!hand || hand.dataset.uxSelectionWired === "1") return;
    hand.dataset.uxSelectionWired = "1";

    hand.addEventListener("click", (event) => {
      const tile = event.target.closest(".tile");
      if (!tile || !hand.contains(tile)) return;
      const button = event.target.closest("button");
      const text = tileText(tile);
      if (!text) return;

      const now = Date.now();
      const isSame = UX.selectedTileText === text;
      const secondTap = isSame && now - UX.selectedAt < 2600;

      tile.classList.remove("ux-tapped");
      void tile.offsetWidth;
      tile.classList.add("ux-tapped");

      if (!secondTap) {
        event.preventDefault();
        event.stopPropagation();
        if (event.stopImmediatePropagation) event.stopImmediatePropagation();
        UX.selectedTileText = text;
        UX.selectedAt = now;
        markSelectedTile();
        showToast(`${text}を選択。もう一度タップで捨てます`);
        const guide = $("handGuide");
        if (guide) guide.textContent = `${text}を選択中：もう一度タップで打牌`;
        return false;
      }

      UX.selectedTileText = null;
      UX.selectedAt = 0;
      showToast(`${text}を捨てます`);
      if (button) button.blur();
      return true;
    }, true);
  }

  function enhanceButtons() {
    qsa("button").forEach((button) => {
      if (button.dataset.uxButtonWired === "1") return;
      button.dataset.uxButtonWired = "1";
      button.addEventListener("click", () => {
        button.style.transform = "scale(0.96)";
        window.setTimeout(() => { button.style.transform = ""; }, 120);
      });
    });
  }

  function enhanceScreen() {
    wireTileSelection();
    enhanceDrawnTile();
    markSelectedTile();
    enhanceRecentDiscard();
    enhanceTurnVisibility();
    enhanceMessageMotion();
    updateFloatingActionBar();
    enhanceButtons();
  }

  function scheduleEnhance() {
    window.requestAnimationFrame(enhanceScreen);
  }

  function init() {
    ensureToast();
    ensureFloatingActionBar();
    enhanceScreen();
    UX.observer = new MutationObserver(scheduleEnhance);
    UX.observer.observe(document.body, {
      subtree: true,
      childList: true,
      characterData: true,
      attributes: true,
      attributeFilter: ["class", "disabled"],
    });

    document.addEventListener("visibilitychange", () => {
      if (!document.hidden) scheduleEnhance();
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
