// Keep `cds-expandable-tile`'s below-the-fold height up to date.
//
// Carbon measures the below-the-fold content once, when it is first slotted,
// and uses that as the expanded tile's max-height. That breaks in two common
// Shiny cases:
//   * a tile on a hidden panel/tab measures 0 (Carbon then computes "NaNpx"),
//     so it never visibly expands;
//   * content that grows later (outputs rendering, uiOutput) gets clipped.
// A ResizeObserver on the content re-measures whenever its size changes,
// including when a hidden panel becomes visible.

const TILE = "cds-expandable-tile";
const BELOW = "cds-tile-below-the-fold-content";

export function syncBelowHeight(below) {
    const tile = below.parentElement;
    if (!tile?.matches(TILE) || !("_belowTheContentHeight" in tile)) return;

    const height = below.offsetHeight;
    if (height > 0 && height !== tile._belowTheContentHeight) {
        tile._belowTheContentHeight = height;
        tile.requestUpdate?.();
    }
}

const observer = typeof ResizeObserver === "undefined"
    ? null
    : new ResizeObserver(entries => {
        entries.forEach(({ target }) => {
            if (!target.isConnected) {
                // Tile removed (e.g. re-rendered by renderUI)
                observer.unobserve(target);
                delete target._carboniteObserved;
                return;
            }
            syncBelowHeight(target);
        });
    });

export function observeTile(tile) {
    const below = tile.querySelector(`:scope > ${BELOW}`);
    if (!observer || !below || below._carboniteObserved) return;

    observer.observe(below);
    below._carboniteObserved = true;
}

// Custom element lifecycle callbacks are captured when the element is
// defined, so patching connectedCallback afterwards has no effect. Lit calls
// `updated()` as an ordinary method after every render, including the first
// one after the tile is connected, so hook in there.
export function patchExpandableTile(Tile) {
    if (Tile.prototype._carbonitePatched) return;

    const { updated } = Tile.prototype;

    Tile.prototype.updated = function (...args) {
        updated?.apply(this, args);
        observeTile(this);
    };
    Tile.prototype._carbonitePatched = true;
}

function install(Tile) {
    patchExpandableTile(Tile);
    // Tiles that already rendered before the patch
    document.querySelectorAll(TILE).forEach(observeTile);
}

// Patch synchronously when possible (Carbon's module, imported first in
// carbonite.js, has already defined the element) so tiles' first render is
// already patched.
if (customElements.get(TILE)) {
    install(customElements.get(TILE));
} else {
    customElements.whenDefined(TILE).then(() => install(customElements.get(TILE)));
}
