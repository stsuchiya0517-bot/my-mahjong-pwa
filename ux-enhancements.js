(() => {
  "use strict";

  const UX = {
    selectedTileIndex: null,
    selectedTileText: "",
    lastMessage: "",
    lastDiscardText: "",
    toastTimer: null,
    observer: null,
    scheduled: false,
    enhancing: false,
    allowNativeTileClick: false,
  };

  const $ = (id) => document.getElementById(id);
  const qs = (selector, root = document) => root.querySelector(selector);
  const qsa = (selector, root = document) => Array.from(root.querySelectorAll(selector));

  function tileText(tileEl) {
    if (!tileEl) return "";
    const button = qs("button", tileEl);
    return (button ? button.textContent : tileEl.textContent || "").trim();
  }

  function setClass(el, className, enabled) {
    if (!el) return;
    if (enabled && !el.classList.contains(className)) el.classList.add(className);
    if (!enabled && el.classList.contains(className)) el.classList.remove(className);
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
    UX.toastTimer = window.setTimeout(() => toast.classList.remove("is-visible"), 1450);
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

  function selectedTile() {
    if (UX.selectedTileIndex === null) return null;
    return qsa(".hand .tile").find((tile) => Number(tile.dataset.uxIndex) === UX.selectedTileIndex) || null;
  }

  function clearSelection() {
    UX.selectedTileIndex = null;
    UX.selectedTileText = "";
    qsa(".hand .tile.ux-selected").forEach((tile) => tile.classList.remove("ux-selected"));
    const guide = $("handGuide");
    if (guide && guide.textContent.includes("選択中")) guide.textContent = "牌をタップして選択 → 下のボタンで打牌";
  }

  function commitSelectedTile() {
    const tile = selectedTile();
    const button = tile ? qs("button", tile) : null;
    if (!tile || !button) {
      clearSelection();
      updateFloatingActionBar();
      return;
    }
    const text = tileText(tile);
    showToast(`${text}を捨てます`);
    UX.allowNativeTileClick = true;
    button.click();
    UX.allowNativeTileClick = false;
    clearSelection();
    scheduleEnhance();
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

  function buildButton(text, className, onClick) {
    const button = document.createElement("button");
    button.type = "button";
    button.className = className;
    button.textContent = text;
    button.addEventListener("click", onClick);
    return button;
  }

  function updateFloatingActionBar() {
    const source = $("actionPanel");
    const bar = ensureFloatingActionBar();
    if (!source) return;

    const hasSelection = UX.selectedTileIndex !== null && Boolean(selectedTile());
    const actionButtons = qsa("button", source).filter((button) => !button.disabled);
    const signature = hasSelection
      ? `selected:${UX.selectedTileIndex}:${UX.selectedTileText}`
      : `actions:${actionButtons.map((button) => button.textContent.trim()).join("|")}`;

    if (bar.dataset.signature !== signature) {
      bar.innerHTML = "";
      bar.className = "ux-floating-action-bar";

      if (hasSelection) {
        bar.classList.add("has-selection");
        const label = document.createElement("div");
        label.className = "ux-selection-label";
        label.innerHTML = `<span>選択中</span><strong>${UX.selectedTileText}</strong>`;
        bar.appendChild(label);
        bar.appendChild(buildButton("この牌を捨てる", "action-btn good ux-discard-confirm", commitSelectedTile));
        bar.appendChild(buildButton("取消", "action-btn secondary ux-cancel-selection", () => {
          clearSelection();
          showToast("選択を解除しました");
          updateFloatingActionBar();
        }));
      } else {
        actionButtons.slice(0, 4).forEach((button) => bar.appendChild(cloneActionButton(button)));
      }
      bar.dataset.signature = signature;
    }

    const visible = hasSelection || actionButtons.length > 0;
    setClass(bar, "is-visible", visible);
    setClass(document.body, "ux-action-bar-active", visible);
  }

  function parseCurrentPlayerName() {
    const scoreActive = qs(".score-card.active .name") || qs(".score-card.ux-active-player .name");
    if (scoreActive) return scoreActive.textContent.trim();
    const playerState = $("playerState")?.textContent?.trim() || "";
    if (playerState.includes("あなた")) return "あなた";
    return "";
  }

  function enhanceTurnVisibility() {
    const activeCard = qs(".score-card.active");
    const currentName = parseCurrentPlayerName();

    qsa(".score-card").forEach((el) => {
      setClass(el, "ux-active-player", el === activeCard);
      setClass(el, "ux-thinking", el === activeCard && Boolean(currentName && currentName !== "あなた"));
    });

    qsa(".opponent").forEach((el) => {
      const isActiveOpponent = Boolean(currentName && currentName !== "あなた" && el.textContent.includes(currentName));
      setClass(el, "ux-active-player", isActiveOpponent);
      setClass(el, "ux-thinking", isActiveOpponent);
    });

    setClass(qs(".player-area"), "ux-player-turn", !currentName || currentName === "あなた");

    const center = qs(".center-panel");
    if (center && !qs(".ux-turn-ribbon", center)) {
      const ribbon = document.createElement("div");
      ribbon.className = "ux-turn-ribbon";
      ribbon.id = "uxTurnRibbon";
      center.appendChild(ribbon);
    }
    const ribbon = $("uxTurnRibbon");
    const ribbonText = currentName && currentName !== "あなた" ? `${currentName}の手番` : "あなたの手番";
    if (ribbon && ribbon.textContent !== ribbonText) ribbon.textContent = ribbonText;
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

  function indexHandTiles() {
    qsa(".hand .tile").forEach((tile, index) => {
      tile.dataset.uxIndex = String(index);
    });
    if (UX.selectedTileIndex !== null && !selectedTile()) clearSelection();
  }

  function enhanceDrawnTile() {
    qsa(".hand .tile").forEach((tile) => tile.classList.remove("ux-drawn"));
    const drawn = qs(".hand .tile.drawn");
    if (drawn) drawn.classList.add("ux-drawn");
    else {
      const handTiles = qsa(".hand .tile");
      if (handTiles.length % 3 === 2 && handTiles.length > 0) handTiles[handTiles.length - 1].classList.add("ux-drawn");
    }
  }

  function markSelectedTile() {
    qsa(".hand .tile").forEach((tile) => {
      const isSelected = UX.selectedTileIndex !== null && Number(tile.dataset.uxIndex) === UX.selectedTileIndex;
      setClass(tile, "ux-selected", isSelected);
    });
  }

  function wireTileSelection() {
    const hand = $("hand");
    if (!hand || hand.dataset.uxSelectionWired === "1") return;
    hand.dataset.uxSelectionWired = "1";

    hand.addEventListener("click", (event) => {
      if (UX.allowNativeTileClick) return true;
      const tile = event.target.closest(".tile");
      if (!tile || !hand.contains(tile)) return;
      const text = tileText(tile);
      const index = Number(tile.dataset.uxIndex);
      if (!text || Number.isNaN(index)) return;

      event.preventDefault();
      event.stopPropagation();
      if (event.stopImmediatePropagation) event.stopImmediatePropagation();

      tile.classList.remove("ux-tapped");
      void tile.offsetWidth;
      tile.classList.add("ux-tapped");

      UX.selectedTileIndex = index;
      UX.selectedTileText = text;
      markSelectedTile();
      updateFloatingActionBar();
      showToast(`${text}を選択しました`);
      const guide = $("handGuide");
      if (guide) guide.textContent = `${text}を選択中：下の「この牌を捨てる」で打牌`;
      return false;
    }, true);
  }

  function enhanceButtons() {
    qsa("button").forEach((button) => {
      if (button.dataset.uxButtonWired === "1") return;
      button.dataset.uxButtonWired = "1";
      button.addEventListener("click", () => {
        button.style.transform = "scale(0.97)";
        window.setTimeout(() => { button.style.transform = ""; }, 100);
      });
    });
  }

  function collapseLearningPanelOnPhone() {
    const details = qs(".learn-panel details");
    if (details && window.matchMedia("(max-width: 760px)").matches) details.removeAttribute("open");
  }

  function enhanceScreen() {
    if (UX.enhancing) return;
    UX.enhancing = true;
    indexHandTiles();
    wireTileSelection();
    enhanceDrawnTile();
    markSelectedTile();
    enhanceRecentDiscard();
    enhanceTurnVisibility();
    enhanceMessageMotion();
    updateFloatingActionBar();
    enhanceButtons();
    UX.enhancing = false;
  }

  function scheduleEnhance() {
    if (UX.scheduled || UX.enhancing) return;
    UX.scheduled = true;
    window.requestAnimationFrame(() => {
      UX.scheduled = false;
      enhanceScreen();
    });
  }

  function init() {
    collapseLearningPanelOnPhone();
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

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();
