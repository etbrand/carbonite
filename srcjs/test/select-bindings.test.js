import { describe, it, expect, vi } from "vitest";
import "../bindings/carbon-select.js";
import "../bindings/carbon-dropdown.js";
import "../bindings/carbon-combo-box.js";
import "../bindings/carbon-multi-select.js";
import { mount, fire, childValues } from "./helpers.js";

// Single-value inputs share the same binding shape.
describe.each([
    ["carbon.select", "cds-select", "cds-select-selected"],
    ["carbon.dropdown", "cds-dropdown", "cds-dropdown-selected"],
    ["carbon.comboBox", "cds-combo-box", "cds-combo-box-selected"]
])("%s", (name, tag, event) => {
    const binding = getBinding(name);
    const itemTag = `${tag}-item`;
    const make = () => mount(
        `<${tag} id="x"><${itemTag} value="a">A</${itemTag}></${tag}>`
    );

    it(`finds ${tag} elements with an id`, () => {
        mount(`<div><${tag} id="one"></${tag}><${tag}></${tag}></div>`);

        const found = binding.find(document.body);
        expect(found.length).toBe(1);
        expect(found[0].id).toBe("one");
    });

    it("reads the element's value, or null", () => {
        const el = make();
        expect(binding.getValue(el)).toBeNull();

        el.value = "a";
        expect(binding.getValue(el)).toBe("a");
    });

    it(`notifies Shiny on ${event}`, () => {
        const el = make();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        fire(el, "change");
        expect(callback).not.toHaveBeenCalled();

        fire(el, event);
        expect(callback).toHaveBeenCalledWith(false);

        binding.unsubscribe(el);
        fire(el, event);
        expect(callback).toHaveBeenCalledTimes(1);
    });

    it("updates choices and value, then notifies Shiny", () => {
        const el = make();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        binding.receiveMessage(el, {
            choices: { B: "b", C: "c" },
            value: "c",
            helperText: "Help"
        });

        expect(childValues(el, itemTag)).toEqual(["b", "c"]);
        expect(binding.getValue(el)).toBe("c");
        expect(el.helperText).toBe("Help");
        expect(callback).toHaveBeenCalledTimes(1);
    });
});

describe("carbon.multiSelect", () => {
    const binding = getBinding("carbon.multiSelect");
    const make = (attrs = "") => mount(`<cds-multi-select id="m" ${attrs}>
        <cds-multi-select-item value="a" selected></cds-multi-select-item>
        <cds-multi-select-item value="b"></cds-multi-select-item>
        <cds-multi-select-item value="c" selected></cds-multi-select-item>
    </cds-multi-select>`);

    it("initialises its value from selected items", () => {
        const el = make();
        el.querySelectorAll("cds-multi-select-item").forEach(item => {
            item.value = item.getAttribute("value");
        });

        binding.initialize(el);

        expect(el.value).toBe("a,c");
    });

    it("leaves the value alone when nothing is selected", () => {
        const el = mount(`<cds-multi-select id="m"><cds-multi-select-item value="a"></cds-multi-select-item></cds-multi-select>`);

        binding.initialize(el);

        expect(el.value).toBeUndefined();
    });

    it("splits the comma-separated value into an array, preserving order", () => {
        const el = make();

        expect(binding.getValue(el)).toEqual([]);

        el.value = "c,a";
        expect(binding.getValue(el)).toEqual(["c", "a"]);
    });

    it("notifies Shiny on cds-multi-select-selected", () => {
        const el = make();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        fire(el, "cds-multi-select-selected");
        expect(callback).toHaveBeenCalledWith(false);

        binding.unsubscribe(el);
        fire(el, "cds-multi-select-selected");
        expect(callback).toHaveBeenCalledTimes(1);
    });

    it("updates choices and value from a message", () => {
        const el = make();

        binding.receiveMessage(el, { choices: { X: "x", Y: "y" }, value: "x,y" });

        expect(childValues(el, "cds-multi-select-item")).toEqual(["x", "y"]);
        expect(binding.getValue(el)).toEqual(["x", "y"]);
    });
});
