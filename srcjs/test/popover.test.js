import { describe, it, expect, vi, beforeAll } from "vitest";
import "../bindings/carbon-popover.js";
import { mount } from "./helpers.js";

let applyOptions, setOpen, triggerOf, TOGGLED_EVENT;

beforeAll(async () => {
    ({ applyOptions, setOpen, triggerOf, TOGGLED_EVENT } = await import("../popover.js"));
});

const binding = getBinding("carbon.popover");

// Mirrors carbon_popover()
function make({ id = "pop", attrs = "" } = {}) {
    return mount(`<cds-popover${id ? ` id="${id}"` : ""} class="carbonite-popover"${attrs}>
        <cds-button id="trigger">Help</cds-button>
        <cds-popover-content slot="content"><div class="carbonite-popover__body"><p id="inside">Content</p></div></cds-popover-content>
    </cds-popover>`);
}

const click = el => el.dispatchEvent(new MouseEvent("click", { bubbles: true, composed: true }));

describe("popover", () => {
    it("finds the trigger, not the content", () => {
        const el = make();
        expect(triggerOf(el).id).toBe("trigger");
    });

    it("toggles when the trigger is clicked, not the content", () => {
        const el = make();

        click(document.getElementById("trigger"));
        expect(el.open).toBe(true);
        expect(el.hasAttribute("open")).toBe(true);

        click(document.getElementById("inside"));
        expect(el.open).toBe(true);

        click(document.getElementById("trigger"));
        expect(el.open).toBe(false);
    });

    it("leaves other cds-popovers alone", () => {
        document.body.innerHTML = `<cds-popover><button id="b">x</button></cds-popover>`;
        click(document.getElementById("b"));
        expect(document.querySelector("cds-popover").open).toBeUndefined();
    });

    it("turns off the caret and shadow only when asked", () => {
        const plain = make();
        applyOptions(plain);
        expect(plain.caret).toBeUndefined();

        const el = make({ attrs: ` data-caret="false" data-drop-shadow="false"` });
        applyOptions(el);
        expect(el.caret).toBe(false);
        expect(el.dropShadow).toBe(false);
    });

    it("fires a toggled event only on a change", () => {
        const el = make();
        const toggled = vi.fn();
        el.addEventListener(TOGGLED_EVENT, toggled);

        expect(setOpen(el, true)).toBe(true);
        expect(setOpen(el, true)).toBe(false);
        expect(toggled).toHaveBeenCalledTimes(1);
    });
});

describe("carbon.popover", () => {
    it("finds carbon_popover()s with an id", () => {
        document.body.innerHTML = `<cds-popover id="a" class="carbonite-popover"></cds-popover><cds-popover id="b"></cds-popover><cds-popover class="carbonite-popover"></cds-popover>`;
        expect(binding.find(document.body).toArray().map(el => el.id)).toEqual(["a"]);
    });

    it("reports open/closed, on toggling and on Carbon closing it", () => {
        const el = make();
        const callback = vi.fn();
        binding.subscribe(el, callback);
        expect(binding.getValue(el)).toBe(false);

        click(document.getElementById("trigger"));
        expect(binding.getValue(el)).toBe(true);
        expect(callback).toHaveBeenCalledTimes(1);

        // As Carbon does on an outside click
        el.open = false;
        el.dispatchEvent(new CustomEvent("cds-popover-closed", { bubbles: true, composed: true }));
        expect(binding.getValue(el)).toBe(false);
        expect(callback).toHaveBeenCalledTimes(2);

        binding.unsubscribe(el);
        click(document.getElementById("trigger"));
        expect(callback).toHaveBeenCalledTimes(2);
    });

    it("ignores events from a popover nested in the content", () => {
        const el = make();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        document.getElementById("inside").dispatchEvent(new CustomEvent("cds-popover-closed", { bubbles: true }));

        expect(callback).not.toHaveBeenCalled();
    });

    it("opens and closes from update_carbon_popover()", () => {
        const el = make();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        binding.receiveMessage(el, { open: true });
        expect(binding.getValue(el)).toBe(true);
        binding.receiveMessage(el, { open: true });
        binding.receiveMessage(el, { open: false });

        expect(binding.getValue(el)).toBe(false);
        expect(callback).toHaveBeenCalledTimes(2);
    });
});
