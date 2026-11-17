// Single selection for carbon_structured_list(selection = "single").
//
// The value is the selected row's `selection-value`: its row_key, or its
// row number (as a number) when the list has no row_key (`data-row-key-type`
// "index"); null when no row is selected.
//
// Carbon fires no event when the selection changes: each row selects itself
// in its own click/keydown listener (arrow keys move the selection through
// Carbon's radio group manager). So listen for those events on the list,
// which run after the row's, and read the rows' `selected` state.

import { toValueArray } from "./utils.js";

const CHANGE_EVENT = "carbonite:structured-list-change";

function rows(el) {
    return [...el.querySelectorAll(":scope > cds-structured-list-body > cds-structured-list-row")];
}

function isSelected(row) {
    return typeof row.selected === "boolean" ? row.selected : row.hasAttribute("selected");
}

export function selectRow(el, value) {
    const wanted = toValueArray(value)[0];
    let found = false;

    rows(el).forEach(row => {
        const on = !found && wanted !== undefined && row.getAttribute("selection-value") === wanted;
        if (on) found = true;
        row.selected = on;
        row.toggleAttribute("selected", on);
        // Keep Carbon's roving focus on the selected row
        row.tabIndex = on ? 0 : -1;
    });
}

const carbonStructuredListBinding = new Shiny.InputBinding();

$.extend(carbonStructuredListBinding, {
    find(scope) {
        return $(scope).find("cds-structured-list.carbonite-structured-list-input[id]");
    },

    getValue(el) {
        const row = rows(el).find(isSelected);
        if (!row) return null;

        const value = row.getAttribute("selection-value");
        return el.dataset.rowKeyType === "index" ? Number(value) : value;
    },

    subscribe(el, callback) {
        el._carbonInputHandler = () => {
            Promise.resolve().then(() => callback(false));
        };

        ["click", "keydown", CHANGE_EVENT].forEach(type =>
            el.addEventListener(type, el._carbonInputHandler)
        );
    },

    unsubscribe(el) {
        ["click", "keydown", CHANGE_EVENT].forEach(type =>
            el.removeEventListener(type, el._carbonInputHandler)
        );
        delete el._carbonInputHandler;
    },

    receiveMessage(el, data) {
        if (!("selected" in data)) return;

        selectRow(el, data.selected);
        el.dispatchEvent(new CustomEvent(CHANGE_EVENT));
    }
});

Shiny.inputBindings.register(carbonStructuredListBinding, "carbon.structuredList");
