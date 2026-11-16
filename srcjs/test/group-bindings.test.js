import { describe, it, expect, vi } from "vitest";
import "../bindings/carbon-checkbox-group.js";
import "../bindings/carbon-radio-group.js";
import { mount, makeGroup, fire, checkedValues } from "./helpers.js";

describe("carbon.checkboxGroup", () => {
    const binding = getBinding("carbon.checkboxGroup");
    const group = (items = [{ value: "a" }, { value: "b" }, { value: "bb" }]) =>
        makeGroup("cds-checkbox-group", "cds-checkbox", items);

    it("finds only checkbox groups with an id", () => {
        mount(`<div>
            <cds-checkbox-group id="one"></cds-checkbox-group>
            <cds-checkbox-group></cds-checkbox-group>
            <cds-radio-button-group id="two"></cds-radio-button-group>
        </div>`);

        const found = binding.find(document.body);
        expect(found.length).toBe(1);
        expect(found[0].id).toBe("one");
    });

    it("returns the checked values in order", () => {
        const el = group([{ value: "a", checked: true }, { value: "b" }, { value: "c", checked: true }]);

        expect(binding.getValue(el)).toEqual(["a", "c"]);
    });

    it("returns an empty array when nothing is checked", () => {
        expect(binding.getValue(group())).toEqual([]);
    });

    it("notifies Shiny on cds-checkbox-changed only", () => {
        const el = group();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        fire(el, "change");
        expect(callback).not.toHaveBeenCalled();

        fire(el.querySelector("cds-checkbox"), "cds-checkbox-changed");
        expect(callback).toHaveBeenCalledWith(false);

        binding.unsubscribe(el);
        fire(el, "cds-checkbox-changed");
        expect(callback).toHaveBeenCalledTimes(1);
    });

    it("applies a selection without new choices", () => {
        const el = group([{ value: "a", checked: true }, { value: "b" }, { value: "bb" }]);
        const callback = vi.fn();
        binding.subscribe(el, callback);

        binding.receiveMessage(el, { value: ["b", "bb"] });

        expect(checkedValues(el, "cds-checkbox")).toEqual(["b", "bb"]);
        expect(el.value).toBeUndefined();
        expect(callback).toHaveBeenCalledTimes(1);
    });

    it("matches a scalar selection exactly", () => {
        const el = group();

        binding.receiveMessage(el, { value: "bb" });

        expect(checkedValues(el, "cds-checkbox")).toEqual(["bb"]);
    });

    it("clears the selection with an empty array", () => {
        const el = group([{ value: "a", checked: true }]);

        binding.receiveMessage(el, { value: [] });

        expect(binding.getValue(el)).toEqual([]);
    });

    it("rebuilds choices and updates properties", () => {
        const el = group();

        binding.receiveMessage(el, {
            choices: { X: "x", Y: "y" },
            value: "y",
            legendText: "Pick"
        });

        expect(binding.getValue(el)).toEqual(["y"]);
        expect(el.legendText).toBe("Pick");
    });

    it("does not fail when unsubscribed", () => {
        expect(() => binding.receiveMessage(group(), { value: "a" })).not.toThrow();
    });
});

describe("carbon.radioGroup", () => {
    const binding = getBinding("carbon.radioGroup");
    const group = (items = [{ value: "s" }, { value: "l" }]) =>
        makeGroup("cds-radio-button-group", "cds-radio-button", items, "size");

    it("finds radio button groups with an id", () => {
        mount(`<div><cds-radio-button-group id="r"></cds-radio-button-group></div>`);

        expect(binding.find(document.body).length).toBe(1);
    });

    it("returns the checked value, or null", () => {
        expect(binding.getValue(group())).toBeNull();
        expect(binding.getValue(group([{ value: "s" }, { value: "l", checked: true }]))).toBe("l");
    });

    it("notifies Shiny on cds-radio-button-changed", () => {
        const el = group();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        fire(el.querySelector("cds-radio-button"), "cds-radio-button-changed");
        expect(callback).toHaveBeenCalledWith(false);

        binding.unsubscribe(el);
        fire(el, "cds-radio-button-changed");
        expect(callback).toHaveBeenCalledTimes(1);
    });

    it("sets the group value (Carbon syncs it to the radios)", () => {
        const el = group();

        binding.receiveMessage(el, { value: "l", legendText: "Size" });

        expect(el.value).toBe("l");
        expect(el.legendText).toBe("Size");
    });

    it("rebuilds choices with or without a selection", () => {
        const el = group();

        binding.receiveMessage(el, { choices: { A: "a", B: "b" }, value: "b" });
        expect(binding.getValue(el)).toBe("b");

        expect(() => binding.receiveMessage(el, { choices: { C: "c" } })).not.toThrow();
        expect(binding.getValue(el)).toBeNull();
    });
});
