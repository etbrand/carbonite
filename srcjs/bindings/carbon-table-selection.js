// Row selection for carbon_table(selection = "multiple" | "single").
//
// The input is named `<table id>_selected`; inside render_carbon_table() the
// table has no id of its own, so the enclosing output's id is used (see
// ensureMarker() for how the input is attached to the page). Its value
// is the selected rows' `data-row-key`s in data order: numbers (row numbers)
// when the table has no row_key, strings otherwise; null when none.
//
// Selection state is read from the rows themselves. Carbon's own list of
// selected rows (`table._selectedRows`) is unreliable (in single mode it only
// ever grows), and its `cds-table-row-selected` event fires before the row's
// `selected` property changes, so values are read a microtask later.

import { toValueArray } from "./utils.js";

const SELECTION_EVENTS = [
    "cds-table-row-selected",
    "cds-table-row-all-selected",
    "carbonite:table-selection-change"
];

function bodyRows(table) {
    return [...table.querySelectorAll(":scope > cds-table-body > cds-table-row")];
}

function isSelected(row) {
    return typeof row.selected === "boolean" ? row.selected : row.hasAttribute("selected");
}

function whenRendered(...elements) {
    return Promise.all(elements.map(el => el?.updateComplete ?? Promise.resolve()));
}

export function selectedKeys(table) {
    const numeric = table.dataset.rowKeyType === "index";

    return bodyRows(table)
        .filter(isSelected)
        .sort((a, b) => Number(a.dataset.rowIndex) - Number(b.dataset.rowIndex))
        .map(row => numeric ? Number(row.dataset.rowKey) : row.dataset.rowKey);
}

// Bring Carbon's own UI in line with the rows' `selected` state: the
// single-select radios, the header select-all checkbox, the batch actions
// bar, and Carbon's internal list (used when the user next clicks).
export function syncCarbonSelection(table) {
    const rows = bodyRows(table);
    const selected = rows.filter(isSelected);
    const count = selected.length;

    if ("_selectedRows" in table) table._selectedRows = selected;

    if (table.hasAttribute("radio")) {
        rows.forEach(row => {
            const radio = row.shadowRoot?.querySelector("cds-radio-button");
            if (radio) radio.checked = isSelected(row);
        });
    }

    const headerRow = table.querySelector("cds-table-head cds-table-header-row");
    const headerCheckbox = headerRow?.shadowRoot?.querySelector("cds-checkbox");
    if (headerCheckbox) {
        const selectable = rows.filter(row =>
            !row.hasAttribute("filtered") && !row.hasAttribute("disabled")
        ).length;
        headerRow.selected = count > 0;
        headerCheckbox.checked = count > 0;
        headerCheckbox.indeterminate = count > 0 && count < selectable;
    }

    const batch = table.querySelector("cds-table-batch-actions");
    if (batch) {
        batch.selectedRowsCount = count;
        batch.active = count > 0;
    }

    const toolbarContent = table.querySelector("cds-table-toolbar-content");
    if (toolbarContent) toolbarContent.hasBatchActions = count > 0;
}

// Select exactly the rows whose keys are in `keys` (unknown keys ignored;
// in single mode only the first match).
export function applySelection(table, keys) {
    const wanted = new Set(toValueArray(keys));
    const single = table.hasAttribute("radio");
    let taken = false;

    const rows = bodyRows(table);
    rows.forEach(row => {
        let on = wanted.has(row.dataset.rowKey);
        if (single && on) {
            on = !taken;
            taken = true;
        }
        row.selected = on;
        row.toggleAttribute("selected", on);
    });

    return whenRendered(table, ...rows).then(() => syncCarbonSelection(table));
}

// Shiny routes update messages to `.shiny-bound-input#<input id>`, so the
// bound element must carry the input id as its DOM id. Rather than renaming
// the table (its id may be the user's, or absent inside an output), each
// selectable table gets a hidden sibling marker with that id; the binding
// works on the marker and reads/updates the table next to it.
const MARKER = "carbonite-table-selection";

export function selectionInputId(table) {
    const base = table.id || table.closest(".shiny-html-output")?.id;
    return base ? `${base}_selected` : null;
}

export function ensureMarker(table) {
    const existing = table.nextElementSibling;
    if (existing?.classList.contains(MARKER)) return existing;

    const id = selectionInputId(table);
    if (!id) return null;

    const marker = document.createElement("span");
    marker.className = MARKER;
    marker.id = id;
    marker.hidden = true;
    table.after(marker);
    return marker;
}

export function tableOf(marker) {
    const table = marker.previousElementSibling;
    return table?.matches("cds-table.carbonite-selectable-table") ? table : null;
}

const carbonTableSelectionBinding = new Shiny.InputBinding();

$.extend(carbonTableSelectionBinding, {
    find(scope) {
        $(scope).find("cds-table.carbonite-selectable-table").each((_, table) => ensureMarker(table));
        return $(scope).find(`.${MARKER}`);
    },

    getId(marker) {
        return marker.id;
    },

    initialize(marker) {
        // Rows selected in the markup (carbon_table(selected = )): Carbon
        // doesn't reflect them in its radios/header/batch bar by itself.
        const table = tableOf(marker);
        if (table) whenRendered(table, ...bodyRows(table)).then(() => syncCarbonSelection(table));
    },

    getValue(marker) {
        const table = tableOf(marker);
        const keys = table ? selectedKeys(table) : [];
        return keys.length ? keys : null;
    },

    subscribe(marker, callback) {
        const table = tableOf(marker);
        if (!table) return;

        marker._carbonInputHandler = () => {
            Promise.resolve().then(() => callback(false));
        };
        SELECTION_EVENTS.forEach(type => table.addEventListener(type, marker._carbonInputHandler));
    },

    unsubscribe(marker) {
        const table = tableOf(marker);
        SELECTION_EVENTS.forEach(type => table?.removeEventListener(type, marker._carbonInputHandler));
        delete marker._carbonInputHandler;
    },

    receiveMessage(marker, data) {
        const table = tableOf(marker);
        if (!table || !("selected" in data)) return;

        applySelection(table, data.selected);
        table.dispatchEvent(new CustomEvent("carbonite:table-selection-change"));
    }
});

Shiny.inputBindings.register(carbonTableSelectionBinding, "carbon.tableSelection");
