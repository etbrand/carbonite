import { describe, it, expect, vi } from "vitest";
import "../bindings/carbon-text-input.js";
import "../bindings/carbon-number-input.js";
import { mount, fire } from "./helpers.js";

describe("carbon.textInput", () => {
    const binding = getBinding("carbon.textInput");
    const make = () => mount(`<cds-text-input id="t"></cds-text-input>`);

    it("reads the value, defaulting to an empty string", () => {
        const el = make();
        expect(binding.getValue(el)).toBe("");

        el.value = "hello";
        expect(binding.getValue(el)).toBe("hello");
    });

    // cds-text-input has no custom input event; the native `input` event from
    // its inner <input> is composed and bubbles out of the shadow root.
    it("notifies Shiny on the native input event", () => {
        const el = make();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        fire(el, "input");
        expect(callback).toHaveBeenCalledWith(false);

        binding.unsubscribe(el);
        fire(el, "input");
        expect(callback).toHaveBeenCalledTimes(1);
    });

    it("updates properties and notifies Shiny", () => {
        const el = make();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        binding.receiveMessage(el, { value: "new", placeholder: "Type", helperText: "Help" });

        expect(binding.getValue(el)).toBe("new");
        expect(el.placeholder).toBe("Type");
        expect(el.helperText).toBe("Help");
        expect(callback).toHaveBeenCalledTimes(1);
    });
});

describe("carbon.numberInput", () => {
    const binding = getBinding("carbon.numberInput");
    const make = () => mount(`<cds-number-input id="n"></cds-number-input>`);

    it.each([
        [undefined, null],
        ["", null],
        ["abc", null],
        ["3.5", 3.5],
        ["0", 0],
        ["-2", -2]
    ])("converts value %j to %j", (value, expected) => {
        const el = make();
        el.value = value;

        expect(binding.getValue(el)).toBe(expected);
    });

    it("notifies Shiny on cds-number-input", () => {
        const el = make();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        fire(el, "input");
        expect(callback).not.toHaveBeenCalled();

        fire(el, "cds-number-input");
        expect(callback).toHaveBeenCalledWith(false);

        binding.unsubscribe(el);
        fire(el, "cds-number-input");
        expect(callback).toHaveBeenCalledTimes(1);
    });

    it("updates properties and notifies Shiny", () => {
        const el = make();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        binding.receiveMessage(el, { value: 7, min: 0, max: 10 });

        expect(binding.getValue(el)).toBe(7);
        expect(el.min).toBe(0);
        expect(el.max).toBe(10);
        expect(callback).toHaveBeenCalledTimes(1);
    });
});
