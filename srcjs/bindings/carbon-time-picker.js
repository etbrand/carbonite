// carbon_time_picker(): Carbon's time picker is a free-text "hh:mm" box,
// with an AM/PM `cds-time-picker-select` on a 12-hour clock
// (`data-clock="12"`). It doesn't validate or convert the text, so the
// binding does: the value is the time as a 24-hour "HH:MM" string, or null
// while the box is empty or doesn't hold a valid time.
//
// Carbon fires a plain `change` event for each keystroke in the box, and
// `cds-select-selected` when AM/PM changes. Typing is debounced like
// shiny::textInput(). An invalid time is marked (Carbon's `invalid`) when the
// user leaves the box, and unmarked as soon as it's valid again.

import { updateCarbonAttributes } from "./utils.js";

const EVENTS = ["change", "cds-select-selected"];
const TWELVE_HOUR = /^\s*(1[0-2]|0?[1-9]):([0-5][0-9])\s*$/;
const TWENTY_FOUR_HOUR = /^\s*([01]?[0-9]|2[0-3]):([0-5][0-9])\s*$/;

const pad = n => String(n).padStart(2, "0");

function isTwelveHour(el) {
    return el.dataset.clock !== "24";
}

function periodSelect(el) {
    return el.querySelector(":scope > cds-time-picker-select");
}

function text(el) {
    return String(el.value ?? el.getAttribute("value") ?? "");
}

// The time in the box as 24-hour "HH:MM", or null.
export function parseTime(el) {
    const value = text(el);

    if (!isTwelveHour(el)) {
        const match = TWENTY_FOUR_HOUR.exec(value);
        return match ? `${pad(match[1])}:${match[2]}` : null;
    }

    const match = TWELVE_HOUR.exec(value);
    if (!match) return null;

    const select = periodSelect(el);
    const period = (select?.value || select?.getAttribute("value") || "AM").toUpperCase();
    const hour = Number(match[1]) % 12 + (period === "PM" ? 12 : 0);
    return `${pad(hour)}:${match[2]}`;
}

// Show a 24-hour "HH:MM" in the box (and AM/PM), or clear it with "".
export function showTime(el, time) {
    const select = periodSelect(el);
    const match = TWENTY_FOUR_HOUR.exec(time ?? "");

    if (!match) {
        el.value = "";
        return;
    }

    const hour = Number(match[1]);
    if (isTwelveHour(el)) {
        el.value = `${(hour + 11) % 12 + 1}:${match[2]}`;
        if (select) {
            select.value = hour >= 12 ? "PM" : "AM";
            select.setAttribute("value", select.value);
        }
    } else {
        el.value = `${pad(hour)}:${match[2]}`;
    }
}

// Mark an invalid time; an empty box isn't an error.
export function markValidity(el) {
    el.invalid = text(el).trim() !== "" && parseTime(el) === null;
}

const carbonTimePickerBinding = new Shiny.InputBinding();

$.extend(carbonTimePickerBinding, {
    find(scope) {
        return $(scope).find("cds-time-picker[id]");
    },

    getValue(el) {
        return parseTime(el);
    },

    subscribe(el, callback) {
        el._carbonInputHandler = event => {
            // Fix a time as soon as it's valid; flag it only on leaving
            if (el.invalid && parseTime(el) !== null) el.invalid = false;
            callback(event.type === "change");
        };
        el._carbonBlurHandler = () => markValidity(el);

        EVENTS.forEach(type => el.addEventListener(type, el._carbonInputHandler));
        el.addEventListener("focusout", el._carbonBlurHandler);
    },

    unsubscribe(el) {
        EVENTS.forEach(type => el.removeEventListener(type, el._carbonInputHandler));
        el.removeEventListener("focusout", el._carbonBlurHandler);
        delete el._carbonInputHandler;
        delete el._carbonBlurHandler;
    },

    getRatePolicy() {
        return { policy: "debounce", delay: 250 };
    },

    receiveMessage(el, data) {
        const { value, ...attributes } = data;
        const before = parseTime(el);

        updateCarbonAttributes(el, attributes);
        if ("disabled" in attributes && periodSelect(el)) {
            periodSelect(el).disabled = attributes.disabled;
        }

        if (value !== undefined) {
            showTime(el, value);
            el.invalid = false;
        }

        if (parseTime(el) !== before) el._carbonInputHandler?.({ type: "update" });
    }
});

Shiny.inputBindings.register(carbonTimePickerBinding, "carbon.timePicker");
