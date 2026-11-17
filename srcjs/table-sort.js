// Value-aware sorting for `carbon_table()`.
//
// Carbon's `cds-table` sorts rows by their cells' text, so numbers sort as
// strings ("110" < "93") and clearing a sort ("none") leaves rows in an
// arbitrary order. carbon_table() marks numeric columns with
// `data-sort-type="numeric"` on the header cell and the raw value as
// `data-sort-value` on each cell, and numbers each row with `data-row-index`.
//
// Carbon sorts in a listener on the table itself; this listener is on the
// document, so it runs afterwards (same event, bubbling) and puts the rows
// in the right order.

function cellsOf(row) {
    return row.querySelectorAll(":scope > cds-table-cell");
}

function rowIndex(row) {
    return Number(row.dataset.rowIndex);
}

function sortKey(row, columnIndex, numeric) {
    const cell = cellsOf(row)[columnIndex];
    if (!cell) return null;

    if (numeric) {
        const value = parseFloat(cell.dataset.sortValue);
        return Number.isNaN(value) ? null : value;
    }
    return cell.textContent.trim();
}

/**
 * Reorder a carbon_table()'s rows by one column.
 *
 * @param {Element} table The `cds-table`.
 * @param {number} columnIndex Index of the column among the header cells.
 * @param {string} direction "ascending", "descending", or "none" (original
 *   order).
 * @returns {boolean} Whether the table was sorted (false for tables not made
 *   by carbon_table()).
 */
export function sortTableRows(table, columnIndex, direction) {
    const body = table.querySelector(":scope > cds-table-body");
    if (!body) return false;

    const rows = [...body.querySelectorAll(":scope > cds-table-row")];
    if (rows.length === 0 || !rows.every(row => row.dataset.rowIndex)) {
        return false;
    }

    const factor = { ascending: 1, descending: -1 }[direction];
    const header = table.querySelectorAll(
        ":scope > cds-table-head > cds-table-header-row > cds-table-header-cell"
    )[columnIndex];
    const numeric = header?.dataset.sortType === "numeric";
    const collator = table.collator ?? new Intl.Collator(table.locale);

    const keyed = rows.map(row => ({
        row,
        index: rowIndex(row),
        key: factor ? sortKey(row, columnIndex, numeric) : null
    }));

    keyed.sort((a, b) => {
        if (factor) {
            const aMissing = a.key === null || a.key === "";
            const bMissing = b.key === null || b.key === "";

            // Missing values go last in either direction.
            if (aMissing !== bMissing) return aMissing ? 1 : -1;

            if (!aMissing) {
                const cmp = numeric ? a.key - b.key : collator.compare(a.key, b.key);
                if (cmp !== 0) return factor * cmp;
            }
        }
        return a.index - b.index;
    });

    keyed.forEach(({ row }) => body.appendChild(row));
    return true;
}

document.addEventListener("cds-table-header-cell-sort", event => {
    if (event.defaultPrevented) return;

    const header = event.target;
    const table = header.closest?.("cds-table");
    if (!table || !header.parentElement) return;

    const columnIndex = [...header.parentElement.children].indexOf(header);
    if (sortTableRows(table, columnIndex, event.detail?.sortDirection)) {
        // Lets table-pagination.js show the current page in the new order.
        table.dispatchEvent(new CustomEvent("carbonite:table-sorted", { bubbles: true }));
    }
});
