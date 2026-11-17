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

describe("carbon.textInput with a password input", () => {
    const binding = getBinding("carbon.textInput");
    const make = () => mount(`<cds-password-input id="pw"></cds-password-input>`);

    it("finds password inputs with an id, alongside text inputs", () => {
        document.body.innerHTML = `<cds-text-input id="a"></cds-text-input><cds-password-input id="b"></cds-password-input><cds-password-input></cds-password-input>`;
        expect(binding.find(document.body).toArray().map(el => el.id)).toEqual(["a", "b"]);
    });

    it("reads the value and notifies Shiny on the native input event", () => {
        const el = make();
        const callback = vi.fn();
        binding.subscribe(el, callback);
        expect(binding.getValue(el)).toBe("");

        el.value = "s3cret";
        fire(el, "input");

        expect(binding.getValue(el)).toBe("s3cret");
        expect(callback).toHaveBeenCalledWith(false);
    });

    it("can be cleared from update_carbon_password_input()", () => {
        const el = make();
        el.value = "s3cret";
        const callback = vi.fn();
        binding.subscribe(el, callback);

        binding.receiveMessage(el, { value: "", helperText: "Try again" });

        expect(binding.getValue(el)).toBe("");
        expect(el.helperText).toBe("Try again");
        expect(callback).toHaveBeenCalledTimes(1);
    });
});

describe("carbon.textInput with a text area", () => {
    const binding = getBinding("carbon.textInput");

    it("finds text areas with an id", () => {
        document.body.innerHTML = `<cds-textarea id="c"></cds-textarea><cds-textarea></cds-textarea>`;
        expect(binding.find(document.body).toArray().map(el => el.id)).toEqual(["c"]);
    });

    it("reads multi-line text and notifies Shiny on input", () => {
        const el = mount(`<cds-textarea id="c"></cds-textarea>`);
        const callback = vi.fn();
        binding.subscribe(el, callback);

        el.value = "line 1\nline 2";
        fire(el, "input");

        expect(binding.getValue(el)).toBe("line 1\nline 2");
        expect(callback).toHaveBeenCalledWith(false);
    });
});
