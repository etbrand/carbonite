import {
    rebuildCarbonChoices,
    updateCarbonAttributes
} from "./utils.js";

const carbonComboBoxBinding = new Shiny.InputBinding();

$.extend(carbonComboBoxBinding, {
    find(scope) {
        return $(scope).find("cds-combo-box[id]");
    },

    getValue(el) {
        return el.value ?? null;
    },

    subscribe(el, callback) {
        el._carbonInputHandler = () => {
            callback(false);
        };

        el.addEventListener("cds-combo-box-selected", el._carbonInputHandler);
    },

    unsubscribe(el) {
        el.removeEventListener("cds-combo-box-selected", el._carbonInputHandler);
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

Shiny.inputBindings.register(carbonComboBoxBinding, "carbon.comboBox");