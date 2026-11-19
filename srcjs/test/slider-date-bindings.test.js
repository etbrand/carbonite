import { describe, it, expect, vi } from "vitest";
import "../bindings/carbon-slider.js";
import "../bindings/carbon-date-picker.js";
import { mount, fire } from "./helpers.js";

describe("carbon.slider", () => {
    const binding = getBinding("carbon.slider");
    const single = () => mount(`<cds-slider id="bins" min="1" max="50" value="30"></cds-slider>`);
    const range = () => mount(`<cds-slider id="price" min="0" max="1000" value="200" value-upper="800"></cds-slider>`);

    it("finds sliders with an id", () => {
        document.body.innerHTML = `<cds-slider id="a"></cds-slider><cds-slider></cds-slider>`;
        expect(binding.find(document.body).toArray().map(el => el.id)).toEqual(["a"]);
    });

    it("reads a number, from the attribute before Carbon upgrades", () => {
        const el = single();
        expect(binding.getValue(el)).toBe(30);

        el.value = 12;
        expect(binding.getValue(el)).toBe(12);
    });

    it("reads [start, end] for a range slider", () => {
        const el = range();
        expect(binding.getValue(el)).toEqual([200, 800]);

        el.value = 100;
        el.unstable_valueUpper = 900;
        expect(binding.getValue(el)).toEqual([100, 900]);
    });

    it("debounces like sliderInput, on cds-slider-changed", () => {
        const el = single();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        expect(binding.getRatePolicy(el)).toEqual({ policy: "debounce", delay: 250 });

        fire(el, "input");
        expect(callback).not.toHaveBeenCalled();

        fire(el, "cds-slider-changed");
        expect(callback).toHaveBeenCalledWith(true);

        binding.unsubscribe(el);
        fire(el, "cds-slider-changed");
        expect(callback).toHaveBeenCalledTimes(1);
    });

    it("updates the value and limits, notifying Shiny on a change", () => {
        const el = single();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        binding.receiveMessage(el, { value: 70, max: 100, labelText: "Bins", disabled: true });

        expect(binding.getValue(el)).toBe(70);
        expect(el.max).toBe(100);
        expect(el.labelText).toBe("Bins");
        expect(el.disabled).toBe(true);
        expect(callback).toHaveBeenCalledTimes(1);

        binding.receiveMessage(el, { step: 5 });
        binding.receiveMessage(el, { value: 70 });
        expect(callback).toHaveBeenCalledTimes(1);
    });

    it("updates both ends of a range", () => {
        const el = range();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        binding.receiveMessage(el, { value: [10, 20] });

        expect(binding.getValue(el)).toEqual([10, 20]);
        expect(callback).toHaveBeenCalledTimes(1);
    });
});

describe("carbon.datePicker", () => {
    const binding = getBinding("carbon.datePicker");
    const single = (value = "") => mount(
        `<cds-date-picker id="due"${value ? ` value="${value}"` : ""}><cds-date-picker-input kind="single"></cds-date-picker-input></cds-date-picker>`
    );
    const range = (value = "") => mount(
        `<cds-date-picker id="period"${value ? ` value="${value}"` : ""}>` +
        `<cds-date-picker-input kind="from"></cds-date-picker-input><cds-date-picker-input kind="to"></cds-date-picker-input></cds-date-picker>`
    );
    const changed = (el, dates) => el.dispatchEvent(new CustomEvent("cds-date-picker-changed", {
        bubbles: true, composed: true, detail: { selectedDates: dates }
    }));

    it("finds date pickers with an id and reports Shiny's date type", () => {
        document.body.innerHTML = `<cds-date-picker id="a"></cds-date-picker><cds-date-picker></cds-date-picker>`;
        const found = binding.find(document.body);
        expect(found.toArray().map(el => el.id)).toEqual(["a"]);
        expect(binding.getType(found[0])).toBe("shiny.date");
    });

    it("reads one ISO date, or null", () => {
        expect(binding.getValue(single("2026-12-01"))).toBe("2026-12-01");
        expect(binding.getValue(single())).toBeNull();

        const el = single("2026-12-01");
        el.value = "";
        expect(binding.getValue(el)).toBeNull();
    });

    it("reads a range as [start, end], with null for missing ends", () => {
        expect(binding.getValue(range("2026-01-01/2026-03-31"))).toEqual(["2026-01-01", "2026-03-31"]);
        expect(binding.getValue(range("2026-01-01"))).toEqual(["2026-01-01", null]);
        expect(binding.getValue(range())).toEqual([null, null]);
    });

    it("notifies Shiny on cds-date-picker-changed", () => {
        const el = single();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        fire(el, "change");
        expect(callback).not.toHaveBeenCalled();

        changed(el, [new Date()]);
        expect(callback).toHaveBeenCalledWith(false);

        binding.unsubscribe(el);
        changed(el, [new Date()]);
        expect(callback).toHaveBeenCalledTimes(1);
    });

    it("waits for both ends of a range, but reports clearing it", () => {
        const el = range();
        const callback = vi.fn();
        binding.subscribe(el, callback);

        changed(el, [new Date()]);
        expect(callback).not.toHaveBeenCalled();

        changed(el, [new Date(), new Date()]);
        changed(el, []);
        expect(callback).toHaveBeenCalledTimes(2);
    });

    it("updates the value and limits, notifying Shiny on a change", () => {
        const el = range("2026-01-01/2026-01-31");
        const callback = vi.fn();
        binding.subscribe(el, callback);

        binding.receiveMessage(el, { value: "2026-02-01/2026-02-28", minDate: "2026-01-01" });
        expect(binding.getValue(el)).toEqual(["2026-02-01", "2026-02-28"]);
        expect(el.minDate).toBe("2026-01-01");
        expect(callback).toHaveBeenCalledTimes(1);

        binding.receiveMessage(el, { maxDate: "2026-12-31" });
        expect(callback).toHaveBeenCalledTimes(1);

        binding.receiveMessage(el, { value: "" });
        expect(binding.getValue(el)).toEqual([null, null]);
        expect(callback).toHaveBeenCalledTimes(2);
    });
});

describe("date picker min/max patch", () => {
    it("parses ISO dates as local dates, and nothing else", async () => {
        const { parseISODate } = await import("../date-picker.js");

        const date = parseISODate("2026-11-01");
        expect([date.getFullYear(), date.getMonth(), date.getDate()]).toEqual([2026, 10, 1]);
        expect(parseISODate(undefined)).toBeUndefined();
        expect(parseISODate("")).toBeUndefined();
        expect(parseISODate("11/01/2026")).toBeUndefined();
    });

    it("gives Flatpickr Date objects for min and max, leaving other properties to Carbon", async () => {
        const { patchDatePicker } = await import("../date-picker.js");
        const original = vi.fn(() => "original");
        class FakeDatePicker {}
        FakeDatePicker.prototype._setCalendar = original;
        patchDatePicker(FakeDatePicker);
        patchDatePicker(FakeDatePicker); // idempotent

        const picker = Object.assign(new FakeDatePicker(), { minDate: "2026-11-01", maxDate: undefined });
        const calendar = { set: vi.fn() };

        expect(picker._setCalendar("date", calendar)).toBe(calendar);
        const { minDate, maxDate } = calendar.set.mock.calls[0][0];
        expect(minDate).toBeInstanceOf(Date);
        expect(minDate.getMonth()).toBe(10);
        expect(maxDate).toBeUndefined();
        expect(original).not.toHaveBeenCalled();

        expect(picker._setCalendar("value", calendar)).toBe("original");
        expect(original).toHaveBeenCalledTimes(1);
    });
});

describe("range slider patch", () => {
    // A stand-in for Carbon's slider: `_rate`/`_rateUpper` setters move the
    // handles (to whole values, like step = 1), and a 1000px track at x = 0.
    async function makeSlider({ min = 0, max = 1000, value = 200, upper = 800 } = {}) {
        const { patchSlider } = await import("../slider.js");
        const pointermove = vi.fn();
        const click = vi.fn();

        class FakeSlider extends HTMLElement {
            get _rate() { return (this.value - this.min) / (this.max - this.min); }
            set _rate(rate) { this.value = Math.round(this.min + rate * (this.max - this.min)); }
            get _rateUpper() { return (this.unstable_valueUpper - this.min) / (this.max - this.min); }
            set _rateUpper(rate) { this.unstable_valueUpper = Math.round(this.min + rate * (this.max - this.min)); }
        }
        FakeSlider.prototype._handlePointermoveImpl = pointermove;
        FakeSlider.prototype._handleClick = click;
        patchSlider(FakeSlider);
        patchSlider(FakeSlider); // idempotent

        const name = `fake-slider-${Math.random().toString(36).slice(2)}`;
        customElements.define(name, FakeSlider);
        const slider = document.createElement(name);
        Object.assign(slider, { min, max, value, unstable_valueUpper: upper });
        slider._trackNode = Object.assign(document.createElement("div"), { getBoundingClientRect: () => ({ left: 0, width: 1000 }) });
        document.body.replaceChildren(slider);

        const events = [];
        slider.addEventListener("cds-slider-changed", e => events.push(e.detail));
        return { slider, pointermove, click, events };
    }

    it("lets the upper handle be dragged on a slider that isn't 0-100", async () => {
        const { slider, pointermove, events } = await makeSlider();
        slider._draggingUpper = true;

        slider._handlePointermoveImpl({ clientX: 600 });

        expect(slider.unstable_valueUpper).toBe(600);
        expect(events).toEqual([{ value: 600, intermediate: true }]);
        expect(pointermove).not.toHaveBeenCalled();
    });

    it("keeps each handle on its side of the other", async () => {
        const { slider } = await makeSlider();

        slider._draggingUpper = true;
        slider._handlePointermoveImpl({ clientX: 50 });
        expect(slider.unstable_valueUpper).toBe(200);

        slider._draggingUpper = false;
        slider._dragging = true;
        slider._handlePointermoveImpl({ clientX: 950 });
        expect(slider.value).toBe(200);

        slider._handlePointermoveImpl({ clientX: 100 });
        expect(slider.value).toBe(100);
    });

    it("moves the nearer handle on a track click", async () => {
        const { slider, events } = await makeSlider();

        slider._handleClick({ clientX: 700, target: slider });
        expect([slider.value, slider.unstable_valueUpper]).toEqual([200, 700]);

        slider._handleClick({ clientX: 300, target: slider });
        expect([slider.value, slider.unstable_valueUpper]).toEqual([300, 700]);
        expect(events).toEqual([{ value: 700 }, { value: 300 }]);
    });

    it("works for negative ranges", async () => {
        const { slider } = await makeSlider({ min: -100, max: 100, value: -50, upper: 50 });
        slider._draggingUpper = true;

        slider._handlePointermoveImpl({ clientX: 900 }); // 90% of the track

        expect(slider.unstable_valueUpper).toBe(80);
    });

    it("re-points sliders that connected before the patch at the patched handler", async () => {
        const { patchSlider } = await import("../slider.js");
        const original = vi.fn();
        class EarlySlider extends HTMLElement {}
        EarlySlider.prototype._handlePointermoveImpl = original;
        EarlySlider.prototype._handleClick = vi.fn();
        const name = `early-slider-${Math.random().toString(36).slice(2)}`;
        customElements.define(name, EarlySlider);

        // Connected before the patch, as Carbon's upgrade does: its throttled
        // copy calls the original handler
        document.body.innerHTML = `<${name}></${name}>`;
        const early = document.body.firstElementChild;
        early._throttledHandlePointermoveImpl = event => original.call(early, event);

        // The patch looks for cds-slider elements; stand in for that lookup
        const querySelectorAll = document.querySelectorAll;
        document.querySelectorAll = sel => (sel === "cds-slider" ? [early] : querySelectorAll.call(document, sel));
        try {
            patchSlider(EarlySlider);
        } finally {
            document.querySelectorAll = querySelectorAll;
        }

        const patched = vi.spyOn(EarlySlider.prototype, "_handlePointermoveImpl");
        early._throttledHandlePointermoveImpl({ clientX: 1 });
        expect(patched).toHaveBeenCalledTimes(1);
    });

    it("leaves single sliders, handle clicks, and cool-downs to Carbon", async () => {
        const { slider, pointermove, click } = await makeSlider({ upper: null });
        slider._dragging = true;

        slider._handlePointermoveImpl({ clientX: 500 });
        slider._handleClick({ clientX: 500, target: slider });
        expect(pointermove).toHaveBeenCalledTimes(1);
        expect(click).toHaveBeenCalledTimes(1);

        slider.unstable_valueUpper = 800;
        const thumb = document.createElement("div");
        thumb.id = "thumb-upper";
        slider._handleClick({ clientX: 500, target: thumb });
        slider.dragCoolDown = true;
        slider._handleClick({ clientX: 500, target: slider });
        expect(click).toHaveBeenCalledTimes(3);
    });
});

describe("narrow sliders", () => {
    it("lets the track shrink, with one shared stylesheet added once", async () => {
        const { allowNarrow } = await import("../slider.js");
        const slider = document.createElement("cds-slider");
        slider.attachShadow({ mode: "open" });

        allowNarrow(slider);
        allowNarrow(slider);

        const sheets = slider.shadowRoot.adoptedStyleSheets;
        expect(sheets).toHaveLength(1);
        expect([...sheets[0].cssRules].map(rule => rule.cssText).join("")).toContain("min-inline-size");
    });

    it("adds it when Lit creates a slider's shadow root", async () => {
        const { patchSlider } = await import("../slider.js");
        class RootSlider extends HTMLElement {}
        RootSlider.prototype._handlePointermoveImpl = () => {};
        RootSlider.prototype._handleClick = () => {};
        RootSlider.prototype.createRenderRoot = function () { return this.attachShadow({ mode: "open" }); };
        patchSlider(RootSlider);
        const name = `root-slider-${Math.random().toString(36).slice(2)}`;
        customElements.define(name, RootSlider);

        const slider = document.createElement(name);
        const root = slider.createRenderRoot();

        expect(root).toBe(slider.shadowRoot);
        expect(root.adoptedStyleSheets).toHaveLength(1);
    });

    it("skips sliders without a shadow root yet", async () => {
        const { allowNarrow } = await import("../slider.js");
        expect(() => allowNarrow(document.createElement("cds-slider"))).not.toThrow();
    });
});

describe("number boxes in narrow columns", () => {
    // A slider whose contents are `content` px wide in a slider `width` px wide
    function fakeSlider({ width, content, hideTextInput = false }) {
        const slider = document.createElement("div");
        slider.attachShadow({ mode: "open" }).innerHTML = `<div class="cds--slider-container"></div>`;
        const container = slider.shadowRoot.firstElementChild;
        Object.defineProperty(container, "clientWidth", { get: () => slider._width });
        Object.defineProperty(container, "scrollWidth", { get: () => Math.max(slider._width, slider._content) });
        Object.defineProperty(slider, "clientWidth", { get: () => slider._width });
        Object.assign(slider, { _width: width, _content: content, hideTextInput });
        return slider;
    }

    it("hides the boxes while they overflow, and shows them once there's room", async () => {
        const { fitNumberBoxes } = await import("../slider.js");
        const slider = fakeSlider({ width: 190, content: 300 });

        fitNumberBoxes(slider);
        expect(slider.hideTextInput).toBe(true);

        // Without the boxes it fits, but not yet wide enough to bring them back
        Object.assign(slider, { _width: 250, _content: 200 });
        fitNumberBoxes(slider);
        expect(slider.hideTextInput).toBe(true);

        slider._width = 320;
        fitNumberBoxes(slider);
        expect(slider.hideTextInput).toBe(false);
    });

    it("leaves sliders that fit, and boxes the app hid, alone", async () => {
        const { fitNumberBoxes } = await import("../slider.js");

        const fits = fakeSlider({ width: 400, content: 300 });
        fitNumberBoxes(fits);
        expect(fits.hideTextInput).toBe(false);

        const appHid = fakeSlider({ width: 190, content: 300, hideTextInput: true });
        fitNumberBoxes(appHid);
        appHid._width = 600;
        fitNumberBoxes(appHid);
        expect(appHid.hideTextInput).toBe(true);
    });
});
