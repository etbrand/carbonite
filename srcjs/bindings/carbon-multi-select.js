import {
    rebuildCarbonChoices,
    updateCarbonAttributes
} from "./utils.js";

const carbonMultiSelectBinding = new Shiny.InputBinding();

$.extend(carbonMultiSelectBinding, {
    find(scope) {
        return $(scope).find("cds-multi-select[id]");
    },

    // Setting value attribute initially doesn't work - count badge doesn't show
    initialize(el) {
        const value = Array.from(
            el.querySelectorAll(
                "cds-multi-select-item[selected]"
            )
        )
            .map(item => item.value)
            .join(",");

        if (value) {
            el.value = value;
        }
    },

    getValue(el) {
        return el.value ? el.value.split(",") : [];
    },

    subscribe(el, callback) {
        el._carbonInputHandler = () => {
            callback(false);
        };

        el.addEventListener("cds-multi-select-selected", el._carbonInputHandler);
    },

    unsubscribe(el) {
        el.removeEventListener("cds-multi-select-selected", el._carbonInputHandler);
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

Shiny.inputBindings.register(carbonMultiSelectBinding, "carbon.multiSelect");