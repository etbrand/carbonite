// Carbon bug: `cds-date-picker` takes `min-date`/`max-date` as ISO dates
// ("2026-11-01"), but hands the strings to Flatpickr, which parses strings
// with the display format (`date-format`, "m/d/Y" by default). "2026-11-01"
// read as m/d/Y is a date in 2027, so every day is disabled and the initial
// value is rejected as before the minimum. Give Flatpickr Date objects
// instead.

// "YYYY-MM-DD" as a local date (what Flatpickr compares days against).
export function parseISODate(value) {
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value ?? "");
    return match ? new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3])) : undefined;
}

export function patchDatePicker(DatePicker) {
    if (DatePicker.prototype._carbonitePatched) return;

    const { _setCalendar: setCalendar } = DatePicker.prototype;

    DatePicker.prototype._setCalendar = function (property, calendar) {
        if (property !== "date") return setCalendar.call(this, property, calendar);

        calendar.set({
            minDate: parseISODate(this.minDate),
            maxDate: parseISODate(this.maxDate)
        });
        return calendar;
    };
    DatePicker.prototype._carbonitePatched = true;
}

// Patch before any date picker connects (see accordion.js for why
// synchronously).
const DatePicker = customElements.get("cds-date-picker");
if (DatePicker) {
    patchDatePicker(DatePicker);
} else {
    customElements.whenDefined("cds-date-picker")
        .then(() => patchDatePicker(customElements.get("cds-date-picker")));
}
