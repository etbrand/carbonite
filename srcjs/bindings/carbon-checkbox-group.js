import {
    updateCarbonAttributes,
    rebuildCarbonChoices,
    toValueArray
} from "./utils.js";

const carbonCheckboxGroupBinding = new Shiny.InputBinding();

$.extend(carbonCheckboxGroupBinding, {
    find(scope) {
        return $(scope).find("cds-checkbox-group[id]");
    },

    getValue(el) {
        return Array.from(
            el.querySelectorAll("cds-checkbox")
        )
            .filter(checkbox => checkbox.checked)
            .map(checkbox => checkbox.value);
    },

    subscribe(el, callback) {
        el._carbonInputHandler = () => {
            callback(false);
        };

        el.addEventListener("cds-checkbox-changed", el._carbonInputHandler);
    },

    unsubscribe(el) {
        el.removeEventListener("cds-checkbox-changed", el._carbonInputHandler);
        delete el._carbonInputHandler;
    },

    receiveMessage(el, data) {
        const { value, ...attributes } = data;

        if (data.choices !== undefined) {
            rebuildCarbonChoices(el, data);
        } else if (value !== undefined) {
            // cds-checkbox-group has no `value` property, so selection has to
            // be applied to the child checkboxes directly.
            const selected = toValueArray(value);

            el.querySelectorAll("cds-checkbox").forEach(checkbox => {
                checkbox.checked = selected.includes(String(checkbox.value));
            });
        }

        updateCarbonAttributes(el, attributes);
        el._carbonInputHandler?.();
    }
});

Shiny.inputBindings.register(carbonCheckboxGroupBinding, "carbon.checkboxGroup");