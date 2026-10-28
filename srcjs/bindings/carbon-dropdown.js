import {
    rebuildCarbonChoices,
    updateCarbonAttributes
} from "./utils.js";

const carbonDropdownBinding = new Shiny.InputBinding();

$.extend(carbonDropdownBinding, {
    find(scope) {
        return $(scope).find("cds-dropdown[id]");
    },

    getValue(el) {
        return el.value ?? null;
    },

    subscribe(el, callback) {
        el._carbonInputHandler = () => {
            callback(false);
        };

        el.addEventListener("cds-dropdown-selected", el._carbonInputHandler);
    },

    unsubscribe(el) {
        el.removeEventListener("cds-dropdown-selected", el._carbonInputHandler);
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

Shiny.inputBindings.register(carbonDropdownBinding, "carbon.dropdown");