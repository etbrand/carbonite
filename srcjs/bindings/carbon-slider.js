// carbon_slider(): a number, or [start, end] for a range slider (Carbon's
// two-handle mode, set by its `value-upper`).
//
// Carbon fires cds-slider-changed for every step while a handle is dragged
// (and when the number box changes), so the value is debounced like
// shiny::sliderInput()'s. Setting the value from code fires nothing, so
// receiveMessage() notifies Shiny itself.

import { updateCarbonAttributes } from "./utils.js";

const CHANGE_EVENT = "cds-slider-changed";

// Before Carbon upgrades the element, values are only attributes.
function read(el, property, attribute) {
    const value = el[property] ?? el.getAttribute(attribute);
    return value === null || value === undefined || value === "" ? null : Number(value);
}

export function isRange(el) {
    return el.unstable_valueUpper !== undefined
        ? el.unstable_valueUpper !== null
        : el.hasAttribute("value-upper");
}

const carbonSliderBinding = new Shiny.InputBinding();

$.extend(carbonSliderBinding, {
    find(scope) {
        return $(scope).find("cds-slider[id]");
    },

    getValue(el) {
        const value = read(el, "value", "value");
        return isRange(el) ? [value, read(el, "unstable_valueUpper", "value-upper")] : value;
    },

    subscribe(el, callback) {
        el._carbonInputHandler = () => callback(true);
        el.addEventListener(CHANGE_EVENT, el._carbonInputHandler);
    },

    unsubscribe(el) {
        el.removeEventListener(CHANGE_EVENT, el._carbonInputHandler);
        delete el._carbonInputHandler;
    },

    getRatePolicy() {
        return { policy: "debounce", delay: 250 };
    },

    receiveMessage(el, data) {
        const { value, ...attributes } = data;
        const before = JSON.stringify(this.getValue(el));

        // Limits first, so a new value outside the old ones isn't clamped
        updateCarbonAttributes(el, attributes);

        if (value !== undefined) {
            const [start, end] = [].concat(value).map(Number);
            el.value = start;
            if (isRange(el) && end !== undefined) el.unstable_valueUpper = end;
        }

        if (JSON.stringify(this.getValue(el)) !== before) {
            el._carbonInputHandler?.();
        }
    }
});

Shiny.inputBindings.register(carbonSliderBinding, "carbon.slider");
