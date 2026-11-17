// carbon_date_picker() / carbon_date_range_picker(): Carbon keeps the value
// as an ISO date ("2026-01-31"), or "start/end" for a range. The binding
// reports "YYYY-MM-DD" strings as Shiny's "shiny.date" type, which R turns
// into Dates (like shiny::dateInput() / dateRangeInput()): one date (or null),
// or [start, end] with null for a missing end.
//
// Carbon fires cds-date-picker-changed whenever Flatpickr's selection
// changes, including the first click of a range (start only); a range is
// only reported once both ends are picked, or it's cleared. Setting the value
// from code fires nothing, so receiveMessage() notifies Shiny itself.

import { updateCarbonAttributes } from "./utils.js";

const CHANGE_EVENT = "cds-date-picker-changed";

export function isRange(el) {
    return el.querySelector('cds-date-picker-input[kind="to"]') !== null;
}

function rawValue(el) {
    // Before Carbon upgrades the element, the value is only an attribute
    return el.value ?? el.getAttribute("value") ?? "";
}

const carbonDatePickerBinding = new Shiny.InputBinding();

$.extend(carbonDatePickerBinding, {
    find(scope) {
        return $(scope).find("cds-date-picker[id]");
    },

    getType() {
        return "shiny.date";
    },

    getValue(el) {
        const [start = "", end = ""] = rawValue(el).split("/");

        return isRange(el) ? [start || null, end || null] : start || null;
    },

    subscribe(el, callback) {
        el._carbonInputHandler = event => {
            const picked = event?.detail?.selectedDates?.length;
            if (isRange(el) && picked === 1) return;
            callback(false);
        };
        el.addEventListener(CHANGE_EVENT, el._carbonInputHandler);
    },

    unsubscribe(el) {
        el.removeEventListener(CHANGE_EVENT, el._carbonInputHandler);
        delete el._carbonInputHandler;
    },

    receiveMessage(el, data) {
        const before = JSON.stringify(this.getValue(el));

        updateCarbonAttributes(el, data);

        if (JSON.stringify(this.getValue(el)) !== before) {
            el._carbonInputHandler?.();
        }
    }
});

Shiny.inputBindings.register(carbonDatePickerBinding, "carbon.datePicker");
