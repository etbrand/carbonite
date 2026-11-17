// carbon_menu_button() / carbon_overflow_menu(): the value is the chosen
// item's `data-value`, sent as an event, so observeEvent() runs every time
// an item is chosen, even the same one twice (like an action button).
//
// Carbon menu items fire a plain `click` when chosen, by mouse or keyboard
// (Enter/Space call `click()`). Carbon ignores clicks on disabled items, but
// the event still bubbles, so check `disabled` here too. Items that open a
// submenu aren't actions.

import { updateCarbonAttributes } from "./utils.js";

export function chosenItem(event) {
    const item = event.target?.closest?.("cds-menu-item");
    if (!item || item.dataset.value === undefined) return null;

    const disabled = typeof item.disabled === "boolean" ? item.disabled : item.hasAttribute("disabled");
    if (disabled || item.querySelector(":scope > [slot=submenu]")) return null;

    return item;
}

const carbonMenuBinding = new Shiny.InputBinding();

$.extend(carbonMenuBinding, {
    find(scope) {
        return $(scope).find(".carbonite-menu[id]");
    },

    getValue(el) {
        return el._carbonMenuValue ?? null;
    },

    subscribe(el) {
        el._carbonMenuHandler = event => {
            const item = chosenItem(event);
            if (!item) return;

            el._carbonMenuValue = item.dataset.value;
            // With the "event" priority, choosing the same item again still
            // reaches the server; the binding callback would drop repeats.
            Shiny.setInputValue(el.id, el._carbonMenuValue, { priority: "event" });
        };

        el.addEventListener("click", el._carbonMenuHandler);
    },

    unsubscribe(el) {
        el.removeEventListener("click", el._carbonMenuHandler);
        delete el._carbonMenuHandler;
    },

    // update_carbon_menu(): `label` and `disabled` are properties of both
    // cds-menu-button and cds-overflow-menu.
    receiveMessage(el, data) {
        updateCarbonAttributes(el, data);
    }
});

Shiny.inputBindings.register(carbonMenuBinding, "carbon.menu");
