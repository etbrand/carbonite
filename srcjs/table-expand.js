// Expandable rows for carbon_table(row_details = ).
//
// Carbon's search reads each row's next sibling as its expanded row, so
// carbon_table() gives every row a `cds-table-expanded-row`, empty
// (`data-empty`, hidden by carbonite.scss) for rows without details. But
// Carbon then marks every row expandable and draws an expand button on it.
// Carbon resets that in `updateExpandable()` whenever the table's rows
// change, so patch it to take the button off rows whose details are empty.

const EXPANDED_ROW = "cds-table-expanded-row";

// Carbon pads the selection checkbox of an expandable row differently
// (`:host(cds-table-row[selection-name][expandable][size=md|sm])`), so a row
// without the button would have its checkbox out of line with the rest.
// Give those rows the same padding, inside their shadow root.
let alignSheet = null;

function checkboxAlignSheet() {
    if (!alignSheet && typeof CSSStyleSheet === "function") {
        alignSheet = new CSSStyleSheet();
        alignSheet.replaceSync(
            ":host([selection-name][size=md]) .cds--table-column-checkbox," +
            ":host([selection-name][size=sm]) .cds--table-column-checkbox" +
            "{padding:.1875rem .375rem}"
        );
    }
    return alignSheet;
}

export function alignCheckbox(row) {
    const root = row.shadowRoot;
    const sheet = checkboxAlignSheet();
    if (!root || !sheet || !("adoptedStyleSheets" in root) || root.adoptedStyleSheets.includes(sheet)) return;

    root.adoptedStyleSheets = [...root.adoptedStyleSheets, sheet];
}

export function hideEmptyExpandButtons(table) {
    table.querySelectorAll(`:scope > cds-table-body > ${EXPANDED_ROW}[data-empty]`).forEach(details => {
        const row = details.previousElementSibling;
        if (!row?.matches("cds-table-row")) return;

        row.expandable = false;
        alignCheckbox(row);
    });
}

// The expanded row that belongs to each row, by `data-expands-row` (the
// row's `data-row-index`): they're linked by index, not position, so
// sorting and paging can't mismatch them.
export function expandedRowsByIndex(table) {
    const rows = table.querySelectorAll(`:scope > cds-table-body > ${EXPANDED_ROW}[data-expands-row]`);
    return new Map([...rows].map(details => [details.dataset.expandsRow, details]));
}

export function patchTable(Table) {
    if (Table.prototype._carbonitePatched) return;

    const { updateExpandable } = Table.prototype;

    Table.prototype.updateExpandable = function (...args) {
        const result = updateExpandable.apply(this, args);
        hideEmptyExpandButtons(this);
        return result;
    };
    Table.prototype._carbonitePatched = true;

    // Tables upgraded before this patch (see slider.js)
    document.querySelectorAll("cds-table[expandable]").forEach(hideEmptyExpandButtons);
}

const Table = customElements.get("cds-table");
if (Table) {
    patchTable(Table);
} else {
    customElements.whenDefined("cds-table").then(() => patchTable(customElements.get("cds-table")));
}
