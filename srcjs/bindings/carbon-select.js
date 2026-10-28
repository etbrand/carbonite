import { updateCarbonAttributes, rebuildCarbonChoices } from "./utils.js";

const carbonSelectBinding = new Shiny.InputBinding();

$.extend(carbonSelectBinding, {
    find(scope) {
        return $(scope).find("cds-select[id]");
    },

    getValue(el) {
        return el.value ?? null;
    },

    subscribe(el, callback) {
        el._carbonInputHandler = () => {
            callback(false);
        };

        el.addEventListener("cds-select-selected", el._carbonInputHandler);
    },

    unsubscribe(el) {
        el.removeEventListener("cds-select-selected", el._carbonInputHandler);
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

Shiny.inputBindings.register(carbonSelectBinding, "carbon.select");