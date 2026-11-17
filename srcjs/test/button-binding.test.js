import { describe, it, expect, vi } from "vitest";
import "../bindings/carbon-button.js";
import { mount } from "./helpers.js";

const binding = getBinding("carbon.button");

describe("carbon.button", () => {
    it("finds buttons with an id", () => {
        mount(`<div><cds-button id="go">Go</cds-button><cds-button>No id</cds-button></div>`);

        const found = binding.find(document.body);
        expect(found.length).toBe(1);
        expect(found[0].id).toBe("go");
    });

    it("reports its value as an action, so 0 clicks doesn't trigger observeEvent()", () => {
        const el = mount(`<cds-button id="go">Go</cds-button>`);

        expect(binding.getType(el)).toBe("shiny.action");
    });

    it("counts clicks like actionButton", () => {
        const el = mount(`<cds-button id="go">Go</cds-button>`);
        const callback = vi.fn();
        expect(binding.getValue(el)).toBe(0);

        binding.subscribe(el, callback);
        el.click();
        el.click();

        expect(binding.getValue(el)).toBe(2);
        expect(callback).toHaveBeenCalledWith(true);

        binding.unsubscribe(el);
        el.click();
        expect(binding.getValue(el)).toBe(2);
    });

    it("adds a slotted SVG for a known icon", () => {
        const el = mount(`<cds-button id="go" data-icon="add">Add</cds-button>`);

        binding.initialize(el);

        const svg = el.querySelector("svg");
        expect(svg).not.toBeNull();
        expect(svg.getAttribute("slot")).toBe("icon");
    });

    it("warns and skips an unknown icon", () => {
        const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
        const el = mount(`<cds-button id="go" data-icon="nope">Go</cds-button>`);

        binding.initialize(el);

        expect(el.querySelector("svg")).toBeNull();
        expect(warn).toHaveBeenCalledWith(expect.stringContaining("nope"));
    });

    it("relabels without removing the icon", () => {
        const el = mount(`<cds-button id="go" data-icon="add">Add</cds-button>`);
        binding.initialize(el);

        binding.receiveMessage(el, { label: "Added" });

        expect(el.textContent).toBe("Added");
        expect(el.querySelector("svg[slot=icon]")).not.toBeNull();
    });

    it("updates kind and size properties", () => {
        const el = mount(`<cds-button id="go">Go</cds-button>`);

        binding.receiveMessage(el, { kind: "danger", size: "lg" });

        expect(el.kind).toBe("danger");
        expect(el.size).toBe("lg");
        expect(el.textContent).toBe("Go");
    });
});
