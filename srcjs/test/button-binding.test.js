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

    // Icons are rendered in R as <svg slot="icon"> children (carbon_icon()).
    const ADD = `<svg slot="icon" viewBox="0 0 32 32"><path d="M17 15z"/></svg>`;
    const EDIT = `<svg viewBox="0 0 32 32" class="edit"><path d="M2 26z"/></svg>`;

    it("relabels without removing the icon", () => {
        const el = mount(`<cds-button id="go">${ADD}Add</cds-button>`);

        binding.receiveMessage(el, { label: "Added" });

        expect(el.textContent).toBe("Added");
        expect(el.querySelector("svg[slot=icon]")).not.toBeNull();
    });

    it("replaces the icon from SVG markup sent by update_carbon_button()", () => {
        const el = mount(`<cds-button id="go">${ADD}Edit</cds-button>`);

        binding.receiveMessage(el, { icon: EDIT });

        const icons = el.querySelectorAll("svg");
        expect(icons).toHaveLength(1);
        expect(icons[0].classList.contains("edit")).toBe(true);
        expect(icons[0].getAttribute("slot")).toBe("icon");
        expect(icons[0].namespaceURI).toBe("http://www.w3.org/2000/svg");
        expect(el.textContent).toBe("Edit");
    });

    it("adds an icon to a button that had none", () => {
        const el = mount(`<cds-button id="go">Go</cds-button>`);

        binding.receiveMessage(el, { icon: EDIT, label: "Edit" });

        expect(el.querySelector("svg[slot=icon]")).not.toBeNull();
        expect(el.textContent).toBe("Edit");
    });

    it("removes the icon when sent an empty string", () => {
        const el = mount(`<cds-button id="go">${ADD}Add</cds-button>`);

        binding.receiveMessage(el, { icon: "" });

        expect(el.querySelector("svg")).toBeNull();
        expect(el.textContent).toBe("Add");
    });

    it("doesn't set icon as a property", () => {
        const el = mount(`<cds-button id="go">Go</cds-button>`);

        binding.receiveMessage(el, { icon: EDIT });

        expect(el.icon).toBeUndefined();
    });

    it("updates kind and size properties", () => {
        const el = mount(`<cds-button id="go">Go</cds-button>`);

        binding.receiveMessage(el, { kind: "danger", size: "lg" });

        expect(el.kind).toBe("danger");
        expect(el.size).toBe("lg");
        expect(el.textContent).toBe("Go");
    });
});
