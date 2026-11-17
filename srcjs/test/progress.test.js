import { describe, it, expect, vi, beforeAll } from "vitest";
import "../bindings/carbon-progress-indicator.js";
import { mount } from "./helpers.js";

let updateProgressBar;

beforeAll(async () => {
    ({ updateProgressBar } = await import("../progress-bar.js"));
});

describe("carbon.progressIndicator", () => {
    const binding = getBinding("carbon.progressIndicator");
    const make = ({ current = 1, clickable = false } = {}) => mount(
        `<cds-progress-indicator id="steps" current-index="${current}"${clickable ? " data-clickable" : ""}>` +
        ["A", "B", "C", "D"].map(label => `<cds-progress-step label="${label}"></cds-progress-step>`).join("") +
        `</cds-progress-indicator>`
    );

    it("finds indicators with an id", () => {
        document.body.innerHTML = `<cds-progress-indicator id="a"></cds-progress-indicator><cds-progress-indicator></cds-progress-indicator>`;
        expect(binding.find(document.body).toArray().map(el => el.id)).toEqual(["a"]);
    });

    it("reports the current step from 1, from the attribute or Carbon's property", () => {
        const el = make({ current: 1 });
        expect(binding.getValue(el)).toBe(2);

        el.currentIndex = 3;
        expect(binding.getValue(el)).toBe(4);
    });

    it("only makes steps clickable when asked, then goes to the clicked step", () => {
        const plain = make();
        binding.subscribe(plain, vi.fn());
        expect(plain.onChange).toBeUndefined();

        const el = make({ clickable: true });
        const callback = vi.fn();
        binding.subscribe(el, callback);
        expect(typeof el.onChange).toBe("function");

        // As Carbon calls it on a click
        el.onChange(new CustomEvent("change", { detail: { index: 0 } }));
        expect(binding.getValue(el)).toBe(1);
        expect(callback).toHaveBeenCalledWith(false);

        binding.unsubscribe(el);
        expect(el.onChange).toBeUndefined();
    });

    it("moves to a step from update_carbon_progress_indicator(), within range", () => {
        const el = make();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        binding.receiveMessage(el, { current: 3 });
        expect(binding.getValue(el)).toBe(3);
        expect(el.getAttribute("current-index")).toBe("2");

        binding.receiveMessage(el, { current: 99 });
        expect(binding.getValue(el)).toBe(4);

        binding.receiveMessage(el, { current: 4 });
        expect(callback).toHaveBeenCalledTimes(2);
    });
});

describe("progress bar updates", () => {
    const make = () => mount(`<cds-progress-bar id="bar" label="Loading" value="10" max="100"></cds-progress-bar>`);

    it("sets the properties sent", () => {
        const bar = make();

        expect(updateProgressBar({ id: "bar", value: 40, helperText: "4 of 10", status: "active", label: "Uploading" })).toBe(true);

        expect(bar.value).toBe(40);
        expect(bar.helperText).toBe("4 of 10");
        expect(bar.label).toBe("Uploading");
        expect(bar.status).toBe("active");
        expect(bar.max).toBeUndefined();
    });

    it("makes the bar indeterminate with a null value", () => {
        const bar = make();

        updateProgressBar({ id: "bar", value: null });

        expect(bar.value).toBeNull();
        expect(bar.hasAttribute("value")).toBe(false);
    });

    it("ignores unknown ids and elements that aren't progress bars", () => {
        document.body.innerHTML = `<div id="other"></div>`;

        expect(updateProgressBar({ id: "missing", value: 1 })).toBe(false);
        expect(updateProgressBar({ id: "other", value: 1 })).toBe(false);
        expect(document.getElementById("other").value).toBeUndefined();
    });
});
