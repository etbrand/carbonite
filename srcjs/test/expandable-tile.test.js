import { describe, it, expect, vi, beforeAll } from "vitest";

// happy-dom has no layout, so record what gets observed and drive the
// ResizeObserver callback by hand.
const observed = new Set();
let resizeCallback;

// Stand-in for Carbon's (Lit) element: the patch relies on `updated()` being
// called after each render, `_belowTheContentHeight`, and `requestUpdate()`.
class FakeExpandableTile extends HTMLElement {
    constructor() {
        super();
        this._belowTheContentHeight = 0;
        this.requestedUpdates = 0;
        this.ownUpdatedCalls = 0;
    }
    updated() { this.ownUpdatedCalls += 1; }
    requestUpdate() { this.requestedUpdates += 1; }
}

let mod;

beforeAll(async () => {
    vi.stubGlobal("ResizeObserver", class {
        constructor(callback) { resizeCallback = callback; }
        observe(el) { observed.add(el); }
        unobserve(el) { observed.delete(el); }
    });
    mod = await import("../expandable-tile.js");
    customElements.define("cds-expandable-tile", FakeExpandableTile);
    await customElements.whenDefined("cds-expandable-tile");
});

// Mount a tile and run a render cycle, as Lit would after connecting it.
function mountTile() {
    document.body.innerHTML = `
        <cds-expandable-tile>
            <cds-tile-above-the-fold-content slot="above-the-fold-content">S</cds-tile-above-the-fold-content>
            <cds-tile-below-the-fold-content>B</cds-tile-below-the-fold-content>
        </cds-expandable-tile>`;
    const tile = document.querySelector("cds-expandable-tile");
    tile.updated(new Map());
    return { tile, below: tile.querySelector("cds-tile-below-the-fold-content") };
}

const setHeight = (el, h) => Object.defineProperty(el, "offsetHeight", { value: h, configurable: true });

describe("expandable tile height sync", () => {
    it("observes the content after a render and still runs Carbon's updated()", () => {
        const { tile, below } = mountTile();

        expect(FakeExpandableTile.prototype._carbonitePatched).toBe(true);
        expect(tile.ownUpdatedCalls).toBe(1);
        expect(observed.has(below)).toBe(true);
    });

    it("observes the content only once across renders", () => {
        const { tile, below } = mountTile();
        // Forget the first observe() call; a second render mustn't repeat it.
        observed.delete(below);

        tile.updated(new Map());

        expect(observed.has(below)).toBe(false);
    });

    it("updates the tile's stored height when the content resizes", () => {
        const { tile, below } = mountTile();
        setHeight(below, 120);

        resizeCallback([{ target: below }]);

        expect(tile._belowTheContentHeight).toBe(120);
        expect(tile.requestedUpdates).toBe(1);
    });

    it("ignores zero heights (hidden) and unchanged heights", () => {
        const { tile, below } = mountTile();
        tile._belowTheContentHeight = 80;

        setHeight(below, 0);
        resizeCallback([{ target: below }]);
        setHeight(below, 80);
        resizeCallback([{ target: below }]);

        expect(tile._belowTheContentHeight).toBe(80);
        expect(tile.requestedUpdates).toBe(0);
    });

    it("stops observing content whose tile was removed", () => {
        const { tile, below } = mountTile();

        tile.remove();
        resizeCallback([{ target: below }]);

        expect(observed.has(below)).toBe(false);
    });

    it("does nothing for content outside an expandable tile", () => {
        document.body.innerHTML = `<div><cds-tile-below-the-fold-content></cds-tile-below-the-fold-content></div>`;
        const below = document.querySelector("cds-tile-below-the-fold-content");
        setHeight(below, 50);

        expect(() => mod.syncBelowHeight(below)).not.toThrow();
    });

    it("patches only once", () => {
        const before = FakeExpandableTile.prototype.updated;

        mod.patchExpandableTile(FakeExpandableTile);

        expect(FakeExpandableTile.prototype.updated).toBe(before);
    });
});
