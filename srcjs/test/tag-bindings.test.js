import { describe, it, expect, vi } from "vitest";
import "../bindings/carbon-tag.js";
import { mount, fire } from "./helpers.js";

// Carbon's "beingselected" events are cancelable; `fire()`'s aren't.
const fireCancelable = (el, type) => {
    const event = new CustomEvent(type, { bubbles: true, composed: true, cancelable: true });
    el.dispatchEvent(event);
    return event;
};

describe("carbon.selectableTag", () => {
    const binding = getBinding("carbon.selectableTag");
    const make = (attrs = "") => mount(`<cds-selectable-tag id="t" text="R"${attrs}></cds-selectable-tag>`);

    it("finds selectable tags with an id", () => {
        document.body.innerHTML = `<cds-selectable-tag id="a"></cds-selectable-tag><cds-selectable-tag></cds-selectable-tag><cds-tag id="b"></cds-tag>`;
        expect(binding.find(document.body).toArray().map(el => el.id)).toEqual(["a"]);
    });

    it("reads `selected` as TRUE/FALSE, falling back to the attribute", () => {
        expect(binding.getValue(make())).toBe(false);
        expect(binding.getValue(make(" selected"))).toBe(true);

        const el = make(" selected");
        el.selected = false;
        expect(binding.getValue(el)).toBe(false);
    });

    it("notifies Shiny on cds-selectable-tag-selected only", () => {
        const el = make();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        fire(el, "click");
        fire(el, "cds-selectable-tag-beingselected");
        expect(callback).not.toHaveBeenCalled();

        fire(el, "cds-selectable-tag-selected");
        expect(callback).toHaveBeenCalledWith(false);

        binding.unsubscribe(el);
        fire(el, "cds-selectable-tag-selected");
        expect(callback).toHaveBeenCalledTimes(1);
    });

    it("selects from update_carbon_tag() and notifies Shiny only on a change", () => {
        const el = make();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        binding.receiveMessage(el, { selected: true, text: "R lang" });
        expect(binding.getValue(el)).toBe(true);
        expect(el.hasAttribute("selected")).toBe(true);
        expect(el.text).toBe("R lang");
        expect(callback).toHaveBeenCalledTimes(1);

        binding.receiveMessage(el, { selected: true, disabled: true });
        expect(callback).toHaveBeenCalledTimes(1);
        expect(el.disabled).toBe(true);

        binding.receiveMessage(el, { selected: false });
        expect(el.hasAttribute("selected")).toBe(false);
        expect(callback).toHaveBeenCalledTimes(2);
    });
});

describe("carbon.dismissibleTag", () => {
    const binding = getBinding("carbon.dismissibleTag");
    const make = () => mount(`<cds-dismissible-tag id="f" text="Status: open"></cds-dismissible-tag>`);

    it("finds dismissible tags with an id", () => {
        document.body.innerHTML = `<cds-dismissible-tag id="a"></cds-dismissible-tag><cds-dismissible-tag></cds-dismissible-tag>`;
        expect(binding.find(document.body).toArray().map(el => el.id)).toEqual(["a"]);
    });

    it("is NULL while open and TRUE once dismissed", () => {
        const el = make();
        expect(binding.getValue(el)).toBeNull();

        el.open = true;
        expect(binding.getValue(el)).toBeNull();

        el.open = false;
        expect(binding.getValue(el)).toBe(true);
    });

    it("notifies Shiny on cds-dismissible-tag-closed", () => {
        const el = make();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        fire(el, "cds-dismissible-tag-beingclosed");
        expect(callback).not.toHaveBeenCalled();

        fire(el, "cds-dismissible-tag-closed");
        expect(callback).toHaveBeenCalledWith(false);

        binding.unsubscribe(el);
        fire(el, "cds-dismissible-tag-closed");
        expect(callback).toHaveBeenCalledTimes(1);
    });

    it("updates text, type, and disabled", () => {
        const el = make();

        binding.receiveMessage(el, { text: "Status: closed", type: "red", disabled: true });

        expect(el.text).toBe("Status: closed");
        expect(el.type).toBe("red");
        expect(el.disabled).toBe(true);
    });
});

describe("carbon.operationalTag", () => {
    const binding = getBinding("carbon.operationalTag");
    const make = () => mount(`<cds-operational-tag id="more" text="+3"></cds-operational-tag>`);

    it("finds operational tags with an id", () => {
        document.body.innerHTML = `<cds-operational-tag id="a"></cds-operational-tag><cds-operational-tag></cds-operational-tag>`;
        expect(binding.find(document.body).toArray().map(el => el.id)).toEqual(["a"]);
    });

    it("is an action input", () => {
        const el = make();
        expect(binding.getType(el)).toBe("shiny.action");
        expect(binding.getValue(el)).toBe(0);
    });

    it("counts clicks and cancels Carbon's selected toggle", () => {
        const el = make();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        const first = fireCancelable(el, "cds-operational-tag-beingselected");
        fireCancelable(el, "cds-operational-tag-beingselected");

        expect(first.defaultPrevented).toBe(true);
        expect(binding.getValue(el)).toBe(2);
        expect(callback).toHaveBeenCalledTimes(2);
        expect(callback).toHaveBeenCalledWith(false);

        binding.unsubscribe(el);
        const after = fireCancelable(el, "cds-operational-tag-beingselected");
        expect(after.defaultPrevented).toBe(false);
        expect(binding.getValue(el)).toBe(2);
    });

    it("updates text and type without touching the count", () => {
        const el = make();
        el.dataset.clickCount = "4";

        binding.receiveMessage(el, { text: "+5", type: "blue" });

        expect(el.text).toBe("+5");
        expect(el.type).toBe("blue");
        expect(binding.getValue(el)).toBe(4);
    });
});
