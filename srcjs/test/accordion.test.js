import { describe, it, expect, beforeAll } from "vitest";

let notifyShiny;

beforeAll(async () => {
    ({ notifyShiny } = await import("../accordion.js"));
});

// Record the jQuery events Shiny would see on the item.
function mountItem({ open = false, updateComplete } = {}) {
    document.body.innerHTML = `<cds-accordion><cds-accordion-item></cds-accordion-item></cds-accordion>`;
    const item = document.querySelector("cds-accordion-item");
    item.open = open;
    if (updateComplete) item.updateComplete = updateComplete;

    const seen = [];
    $(item).on("shown hidden", e => seen.push(e.type));
    return { item, seen };
}

const toggled = item => item.dispatchEvent(
    new CustomEvent("cds-accordion-item-toggled", { bubbles: true, composed: true, detail: { open: item.open } })
);

describe("accordion -> Shiny visibility", () => {
    it("triggers 'shown' when an item opens", () => {
        const { item, seen } = mountItem({ open: true });

        toggled(item);

        expect(seen).toEqual(["shown"]);
    });

    it("triggers 'hidden' when an item closes", () => {
        const { item, seen } = mountItem({ open: false });

        toggled(item);

        expect(seen).toEqual(["hidden"]);
    });

    it("waits for Carbon to re-render before telling Shiny", async () => {
        let finishRender;
        const updateComplete = new Promise(resolve => { finishRender = resolve; });
        const { item, seen } = mountItem({ open: true, updateComplete });

        toggled(item);
        expect(seen).toEqual([]);

        finishRender(true);
        await updateComplete;
        expect(seen).toEqual(["shown"]);
    });

    it("ignores the event from other elements", () => {
        const { item, seen } = mountItem({ open: true });
        const other = document.createElement("div");
        item.after(other);

        other.dispatchEvent(new CustomEvent("cds-accordion-item-toggled", { bubbles: true }));

        expect(seen).toEqual([]);
    });

    it("notifyShiny reports the current state", () => {
        const { item, seen } = mountItem({ open: false });

        notifyShiny(item);

        expect(seen).toEqual(["hidden"]);
    });
});

describe("item-level disabled survives the accordion's first render", () => {
    // Mimics Carbon: the accordion copies its own `disabled` onto every item.
    class FakeAccordion extends HTMLElement {
        updated(changed) {
            if (changed.has("disabled")) {
                this.querySelectorAll("cds-accordion-item").forEach(item => {
                    if (this.disabled) item.setAttribute("disabled", "");
                    else item.removeAttribute("disabled");
                });
            }
        }
    }
    let patchAccordion;

    beforeAll(async () => {
        ({ patchAccordion } = await import("../accordion.js"));
        patchAccordion(FakeAccordion);
        customElements.define("fake-accordion", FakeAccordion);
    });

    const mount = () => {
        document.body.innerHTML = `
            <fake-accordion>
                <cds-accordion-item></cds-accordion-item>
                <cds-accordion-item disabled></cds-accordion-item>
            </fake-accordion>`;
        const acc = document.querySelector("fake-accordion");
        return { acc, items: [...acc.querySelectorAll("cds-accordion-item")] };
    };

    it("keeps disabled on items that set it", () => {
        const { acc, items } = mount();
        acc.disabled = false;

        acc.updated(new Map([["disabled", undefined]]));

        expect(items.map(i => i.hasAttribute("disabled"))).toEqual([false, true]);
    });

    it("still lets a disabled accordion disable every item", () => {
        const { acc, items } = mount();
        acc.disabled = true;

        acc.updated(new Map([["disabled", false]]));

        expect(items.map(i => i.hasAttribute("disabled"))).toEqual([true, true]);
    });

    it("patches only once", () => {
        const before = FakeAccordion.prototype.updated;
        patchAccordion(FakeAccordion);
        expect(FakeAccordion.prototype.updated).toBe(before);
    });
});
