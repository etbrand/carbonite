import { describe, it, expect } from "vitest";
import {
    toValueArray,
    updateCarbonAttributes,
    rebuildCarbonChoices
} from "../bindings/utils.js";
import { mount, makeGroup, childValues, checkedValues } from "./helpers.js";

describe("toValueArray", () => {
    it("treats a missing value as no selection", () => {
        expect(toValueArray(undefined)).toEqual([]);
        expect(toValueArray(null)).toEqual([]);
    });

    it("wraps a scalar (Shiny unboxes length-1 vectors)", () => {
        expect(toValueArray("a")).toEqual(["a"]);
    });

    it("keeps arrays and stringifies values", () => {
        expect(toValueArray(["a", "b"])).toEqual(["a", "b"]);
        expect(toValueArray([1, 2])).toEqual(["1", "2"]);
        expect(toValueArray([])).toEqual([]);
    });
});

describe("updateCarbonAttributes", () => {
    it("assigns message keys as element properties", () => {
        const el = mount(`<cds-select id="s"></cds-select>`);

        updateCarbonAttributes(el, { value: "b", helperText: "Help", disabled: true });

        expect(el.value).toBe("b");
        expect(el.helperText).toBe("Help");
        expect(el.disabled).toBe(true);
    });

    it("never overwrites id or assigns choices", () => {
        const el = mount(`<cds-select id="s"></cds-select>`);

        updateCarbonAttributes(el, { id: "other", choices: { A: "a" } });

        expect(el.id).toBe("s");
        expect(el.choices).toBeUndefined();
    });
});

describe("rebuildCarbonChoices: checkbox group", () => {
    const rebuild = message => {
        const el = makeGroup("cds-checkbox-group", "cds-checkbox", [{ value: "old" }], "opts");
        rebuildCarbonChoices(el, message);
        return el;
    };

    it("replaces the checkboxes with the new choices", () => {
        const el = rebuild({ choices: { Alpha: "a", Beta: "b" } });
        const boxes = el.querySelectorAll("cds-checkbox");

        expect(childValues(el, "cds-checkbox")).toEqual(["a", "b"]);
        expect(boxes[0].id).toBe("opts__a");
        expect(boxes[0].labelText).toBe("Alpha");
        expect(boxes[1].labelText).toBe("Beta");
    });

    it("checks every selected value", () => {
        const el = rebuild({ choices: { a: "a", b: "b", c: "c" }, value: ["a", "c"] });

        expect(checkedValues(el, "cds-checkbox")).toEqual(["a", "c"]);
    });

    it("accepts a scalar value", () => {
        const el = rebuild({ choices: { a: "a", b: "b" }, value: "b" });

        expect(checkedValues(el, "cds-checkbox")).toEqual(["b"]);
    });

    it("matches values exactly, not as substrings", () => {
        const el = rebuild({ choices: { b: "b", bb: "bb" }, value: "bb" });

        expect(checkedValues(el, "cds-checkbox")).toEqual(["bb"]);
    });

    it("works without a value", () => {
        const el = rebuild({ choices: { a: "a", b: "b" } });

        expect(childValues(el, "cds-checkbox")).toEqual(["a", "b"]);
        expect(checkedValues(el, "cds-checkbox")).toEqual([]);
    });
});

describe("rebuildCarbonChoices: radio group", () => {
    it("creates radios that share the group's name", () => {
        const el = makeGroup("cds-radio-button-group", "cds-radio-button", [], "size");

        rebuildCarbonChoices(el, { choices: { Small: "s", Large: "l" }, value: "l" });

        const radios = Array.from(el.querySelectorAll("cds-radio-button"));
        expect(radios.map(r => r.name)).toEqual(["size", "size"]);
        expect(radios.map(r => r.id)).toEqual(["size__s", "size__l"]);
        expect(checkedValues(el, "cds-radio-button")).toEqual(["l"]);
    });

    it("works without a value", () => {
        const el = makeGroup("cds-radio-button-group", "cds-radio-button", []);

        expect(() => rebuildCarbonChoices(el, { choices: { a: "a" } })).not.toThrow();
        expect(checkedValues(el, "cds-radio-button")).toEqual([]);
    });
});

describe("rebuildCarbonChoices: item-based inputs", () => {
    it.each([
        ["cds-select", "cds-select-item"],
        ["cds-dropdown", "cds-dropdown-item"],
        ["cds-combo-box", "cds-combo-box-item"],
        ["cds-multi-select", "cds-multi-select-item"]
    ])("%s replaces its items", (tag, itemTag) => {
        const el = mount(
            `<${tag} id="x"><${itemTag} value="old">Old</${itemTag}></${tag}>`
        );

        rebuildCarbonChoices(el, { choices: { Apple: "apple", Banana: "banana" } });

        const items = Array.from(el.querySelectorAll(itemTag));
        expect(items.map(i => i.value)).toEqual(["apple", "banana"]);
        expect(items.map(i => i.textContent)).toEqual(["Apple", "Banana"]);
    });

    it("leaves non-item children alone", () => {
        const el = mount(
            `<cds-dropdown id="x"><span slot="helper">Help</span><cds-dropdown-item value="old"></cds-dropdown-item></cds-dropdown>`
        );

        rebuildCarbonChoices(el, { choices: { a: "a" } });

        expect(el.querySelector("span[slot=helper]")).not.toBeNull();
        expect(childValues(el, "cds-dropdown-item")).toEqual(["a"]);
    });
});
