import { updateCarbonAttributes } from "./utils.js";

const carbonNumberInputBinding = new Shiny.InputBinding();

$.extend(carbonNumberInputBinding, {
    find(scope) {
        return $(scope).find("cds-number-input[id]");
    },

    getValue(el) {
        if (el.value === "" || el.value == null) {
            return null;
        }

        const value = Number(el.value);

        return Number.isNaN(value) ? null : value;
    },

    subscribe(el, callback) {
        el._carbonInputHandler = () => {
            callback(false);
        };

        el.addEventListener("cds-number-input", el._carbonInputHandler);
    },

    unsubscribe(el) {
        el.removeEventListener("cds-number-input", el._carbonInputHandler);
        delete el._carbonInputHandler;
    },

    receiveMessage(el, data) {
        updateCarbonAttributes(el, data);
        el._carbonInputHandler?.();
    }
});

Shiny.inputBindings.register(carbonNumberInputBinding, "carbon.numberInput");