import { updateCarbonAttributes } from "./utils.js";

const carbonTextInputBinding = new Shiny.InputBinding();

$.extend(carbonTextInputBinding, {
    find(scope) {
        return $(scope).find("cds-text-input[id]");
    },

    getValue(el) {
        return el.value ?? "";
    },

    subscribe(el, callback) {

        el._carbonInputHandler = () => {
            callback(false);
        };

        el.addEventListener("input", el._carbonInputHandler);
    },

    unsubscribe(el) {
        el.removeEventListener("input", el._carbonInputHandler);
        delete el._carbonInputHandler;
    },

    receiveMessage(el, data) {
        updateCarbonAttributes(el, data);
        el._carbonInputHandler?.();
    }
});

Shiny.inputBindings.register(carbonTextInputBinding, "carbon.textInput");