import { updateCarbonAttributes } from "./utils.js";

// carbon_toggle(): TRUE/FALSE, like shiny::checkboxInput(). Carbon keeps the
// state in `toggled` (`checked` is a deprecated alias).
const carbonToggleBinding = new Shiny.InputBinding();

$.extend(carbonToggleBinding, {
    find(scope) {
        return $(scope).find("cds-toggle[id]");
    },

    getValue(el) {
        return Boolean(el.toggled);
    },

    subscribe(el, callback) {
        el._carbonToggleHandler = () => {
            callback(false);
        };

        el.addEventListener("cds-toggle-changed", el._carbonToggleHandler);
    },

    unsubscribe(el) {
        el.removeEventListener("cds-toggle-changed", el._carbonToggleHandler);
        delete el._carbonToggleHandler;
    },

    // Setting `toggled` doesn't fire cds-toggle-changed (Carbon only fires it
    // for clicks), so tell Shiny directly when update_carbon_toggle() changes
    // the state. No loop: nothing here triggers the event.
    receiveMessage(el, data) {
        const before = this.getValue(el);

        updateCarbonAttributes(el, data);

        if (this.getValue(el) !== before) {
            el._carbonToggleHandler?.();
        }
    }
});

Shiny.inputBindings.register(carbonToggleBinding, "carbon.toggle");
