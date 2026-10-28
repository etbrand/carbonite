import { updateCarbonAttributes } from "./utils.js";

const carbonButtonBinding = new Shiny.InputBinding();

$.extend(carbonButtonBinding, {

    find(scope) {
        return $(scope).find("cds-button[id]");
    },

    getValue(el) {
        return Number(el.dataset.clickCount ?? 0);
    },

    subscribe(el, callback) {
        el._carbonClickHandler = () => {
            const value = Number(el.dataset.clickCount ?? 0);

            el.dataset.clickCount = value + 1;

            callback(true);
        };

        el.addEventListener("click", el._carbonClickHandler);
    },

    unsubscribe(el) {
        el.removeEventListener("click", el._carbonClickHandler);
        delete el._carbonClickHandler;
    },

    receiveMessage(el, data) {
        updateCarbonAttributes(el, data);
    }
});

Shiny.inputBindings.register(carbonButtonBinding, "carbon.button");