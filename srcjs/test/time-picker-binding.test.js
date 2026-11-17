import { describe, it, expect, vi } from "vitest";
import "../bindings/carbon-time-picker.js";
import { mount, fire } from "./helpers.js";

const binding = getBinding("carbon.timePicker");

// Mirrors carbon_time_picker()
function make({ clock = "12", value = "", period = "AM" } = {}) {
    const select = clock === "12"
        ? `<cds-time-picker-select value="${period}"><cds-select-item value="AM">AM</cds-select-item><cds-select-item value="PM">PM</cds-select-item></cds-time-picker-select>`
        : "";
    return mount(`<cds-time-picker id="t" data-clock="${clock}"${value ? ` value="${value}"` : ""}>${select}</cds-time-picker>`);
}

const selectOf = el => el.querySelector("cds-time-picker-select");

describe("carbon.timePicker", () => {
    it("finds time pickers with an id", () => {
        document.body.innerHTML = `<cds-time-picker id="a"></cds-time-picker><cds-time-picker></cds-time-picker>`;
        expect(binding.find(document.body).toArray().map(el => el.id)).toEqual(["a"]);
    });

    it.each([
        ["9:30", "AM", "09:30"],
        ["09:30", "AM", "09:30"],
        ["12:15", "AM", "00:15"],
        ["12:15", "PM", "12:15"],
        ["2:05", "PM", "14:05"],
        [" 11:59 ", "PM", "23:59"]
    ])("12-hour: %j %s is %j", (text, period, expected) => {
        const el = make({ value: text, period });
        expect(binding.getValue(el)).toBe(expected);
    });

    it.each(["", "13:00", "0:30", "9:60", "930", "9:3", "abc"])("12-hour: %j is null", text => {
        expect(binding.getValue(make({ value: text }))).toBeNull();
    });

    it("reads AM/PM from Carbon's select property", () => {
        const el = make({ value: "7:00" });
        selectOf(el).value = "PM";
        expect(binding.getValue(el)).toBe("19:00");
    });

    it.each([
        ["0:00", "00:00"],
        ["9:30", "09:30"],
        ["23:59", "23:59"],
        ["24:00", null],
        ["7:5", null]
    ])("24-hour: %j is %j", (text, expected) => {
        expect(binding.getValue(make({ clock: "24", value: text }))).toBe(expected);
    });

    it("notifies Shiny on typing (debounced) and on AM/PM, not on other events", () => {
        const el = make({ value: "9:30" });
        const callback = vi.fn();
        binding.subscribe(el, callback);
        expect(binding.getRatePolicy(el)).toEqual({ policy: "debounce", delay: 250 });

        fire(el, "input");
        expect(callback).not.toHaveBeenCalled();

        fire(el, "change");
        expect(callback).toHaveBeenLastCalledWith(true);

        fire(selectOf(el), "cds-select-selected");
        expect(callback).toHaveBeenLastCalledWith(false);

        binding.unsubscribe(el);
        fire(el, "change");
        expect(callback).toHaveBeenCalledTimes(2);
    });

    it("flags an invalid time on leaving the box, and clears it once valid", () => {
        const el = make();
        binding.subscribe(el, vi.fn());

        el.value = "25:00";
        fire(el, "change");
        expect(el.invalid).toBeFalsy();
        fire(el, "focusout");
        expect(el.invalid).toBe(true);

        el.value = "11:00";
        fire(el, "change");
        expect(el.invalid).toBe(false);

        el.value = "";
        fire(el, "focusout");
        expect(el.invalid).toBe(false);
    });

    it("shows a 24-hour time from the server on a 12-hour clock", () => {
        const el = make({ value: "9:30" });
        const callback = vi.fn();
        binding.subscribe(el, callback);

        binding.receiveMessage(el, { value: "14:05", labelText: "Start", disabled: true });

        expect(el.value).toBe("2:05");
        expect(selectOf(el).value).toBe("PM");
        expect(binding.getValue(el)).toBe("14:05");
        expect(el.labelText).toBe("Start");
        expect(el.disabled).toBe(true);
        expect(selectOf(el).disabled).toBe(true);
        expect(callback).toHaveBeenCalledTimes(1);

        binding.receiveMessage(el, { value: "00:10" });
        expect([el.value, selectOf(el).value]).toEqual(["12:10", "AM"]);
    });

    it("shows a 24-hour time on a 24-hour clock, and clears with an empty value", () => {
        const el = make({ clock: "24", value: "09:00" });
        const callback = vi.fn();
        binding.subscribe(el, callback);

        binding.receiveMessage(el, { value: "09:00" });
        expect(callback).not.toHaveBeenCalled();

        binding.receiveMessage(el, { value: "18:45" });
        expect(el.value).toBe("18:45");

        binding.receiveMessage(el, { value: "" });
        expect(binding.getValue(el)).toBeNull();
        expect(callback).toHaveBeenCalledTimes(2);
    });
});
