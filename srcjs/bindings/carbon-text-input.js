import { updateCarbonAttributes } from "./utils.js";

// Also carbon_password_input() and carbon_textarea(): `cds-password-input`
// and `cds-textarea` extend Carbon's text input, with the same `value` and
// native `input` event.
const carbonTextInputBinding = new Shiny.InputBinding();

$.extend(carbonTextInputBinding, {
    find(scope) {
        return $(scope).find("cds-text-input[id], cds-password-input[id], cds-textarea[id]");
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