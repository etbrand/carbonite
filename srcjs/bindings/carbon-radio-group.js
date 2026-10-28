import { updateCarbonAttributes, rebuildCarbonChoices } from "./utils.js";

const carbonRadioGroupBinding = new Shiny.InputBinding();

$.extend(carbonRadioGroupBinding, {
    find(scope) {
        return $(scope).find("cds-radio-button-group[id]");
    },

    getValue(el) {
        const selected = Array.from(
            el.querySelectorAll("cds-radio-button")
        ).find(radio => radio.checked);

        return selected?.value ?? null;
    },

    subscribe(el, callback) {
        el._carbonInputHandler = () => {
            callback(false);
        };

        el.addEventListener("cds-radio-button-changed", el._carbonInputHandler);
    },

    unsubscribe(el) {
        el.removeEventListener("cds-radio-button-changed", el._carbonInputHandler);
        delete el._carbonInputHandler;
    },

    receiveMessage(el, data) {

        if (data.choices !== undefined) {
            rebuildCarbonChoices(el, data);
        }

        updateCarbonAttributes(el, data);
        el._carbonInputHandler?.();
    }
});

Shiny.inputBindings.register(carbonRadioGroupBinding, "carbon.radioGroup");