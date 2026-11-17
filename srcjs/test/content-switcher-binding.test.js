import { describe, it, expect, vi } from "vitest";
import "../bindings/carbon-content-switcher.js";
import { mount, fire } from "./helpers.js";

const binding = getBinding("carbon.contentSwitcher");

// Mirrors carbon_content_switcher() with panels; "map" is disabled.
function makeSwitcher({ panels = true } = {}) {
    const values = ["chart", "table", "map"];
    const item = (v, i) =>
        `<cds-content-switcher-item value="${v}"${panels ? ` target="view-panel-${i + 1}"` : ""}` +
        `${v === "chart" ? " selected" : ""}${v === "map" ? " disabled" : ""}>${v}</cds-content-switcher-item>`;
    const panel = (v, i) =>
        `<div id="view-panel-${i + 1}" class="carbonite-switcher-panel"${v === "chart" ? "" : " hidden"}>${v} panel</div>`;

    document.body.innerHTML =
        `<cds-content-switcher id="view" value="chart">${values.map(item).join("")}</cds-content-switcher>` +
        (panels ? values.map(panel).join("") : "");

    return document.getElementById("view");
}

const itemFor = (el, v) => el.querySelector(`[value="${v}"]`);
const panelFor = i => document.getElementById(`view-panel-${i}`);
const flush = () => new Promise(resolve => setTimeout(resolve));

describe("carbon.contentSwitcher", () => {
    it("finds switchers with an id", () => {
        document.body.innerHTML = `<cds-content-switcher id="a"></cds-content-switcher><cds-content-switcher></cds-content-switcher>`;
        expect(binding.find(document.body).toArray().map(el => el.id)).toEqual(["a"]);
    });

    it("reads the selected option's value, preferring Carbon's `selected` property", () => {
        const el = makeSwitcher();
        expect(binding.getValue(el)).toBe("chart");

        itemFor(el, "chart").selected = false;
        itemFor(el, "table").selected = true;
        expect(binding.getValue(el)).toBe("table");
    });

    it("falls back to the switcher's value, then null", () => {
        const el = mount(`<cds-content-switcher id="s" value="b"><cds-content-switcher-item value="a"></cds-content-switcher-item></cds-content-switcher>`);
        expect(binding.getValue(el)).toBe("b");

        el.value = "";
        expect(binding.getValue(el)).toBeNull();
    });

    it("notifies Shiny on cds-content-switcher-selected only", () => {
        const el = makeSwitcher();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        fire(el, "click");
        fire(el, "cds-content-switcher-beingselected");
        expect(callback).not.toHaveBeenCalled();

        fire(el, "cds-content-switcher-selected");
        expect(callback).toHaveBeenCalledWith(false);

        binding.unsubscribe(el);
        fire(el, "cds-content-switcher-selected");
        expect(callback).toHaveBeenCalledTimes(1);
    });

    it("tells older Shiny which panels were shown and hidden", async () => {
        const el = makeSwitcher();
        binding.subscribe(el, vi.fn());
        const seen = [];
        $(document).on("shown hidden", e => seen.push(`${e.type}:${e.target.id}`));

        // As Carbon does on a user's choice
        panelFor(1).hidden = true;
        panelFor(2).hidden = false;
        fire(el, "cds-content-switcher-selected");
        await flush();
        $(document).off("shown hidden");

        expect(seen).toEqual(["hidden:view-panel-1", "shown:view-panel-2", "hidden:view-panel-3"]);
    });

    it("selects from update_carbon_content_switcher(), switching panels and notifying Shiny", async () => {
        const el = makeSwitcher();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        binding.receiveMessage(el, { value: "table" });

        expect(binding.getValue(el)).toBe("table");
        expect(el.value).toBe("table");
        expect(itemFor(el, "chart").selected).toBe(false);
        expect(itemFor(el, "chart").hasAttribute("selected")).toBe(false);
        expect(itemFor(el, "table").hasAttribute("selected")).toBe(true);
        expect(itemFor(el, "map").hideDivider).toBe(true);
        expect(itemFor(el, "chart").hideDivider).toBe(false);
        expect([1, 2, 3].map(i => panelFor(i).hidden)).toEqual([true, false, true]);
        expect(callback).toHaveBeenCalledTimes(1);
    });

    it.each([
        ["an unknown value", "nope"],
        ["a disabled option", "map"],
        ["the option already selected", "chart"]
    ])("ignores %s", (_, value) => {
        const el = makeSwitcher();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        binding.receiveMessage(el, { value });

        expect(binding.getValue(el)).toBe("chart");
        expect(panelFor(1).hidden).toBe(false);
        expect(callback).not.toHaveBeenCalled();
    });

    it("accepts the value as a one-element array, and works without panels", () => {
        const el = makeSwitcher({ panels: false });

        binding.receiveMessage(el, { value: ["table"] });

        expect(binding.getValue(el)).toBe("table");
    });
});
