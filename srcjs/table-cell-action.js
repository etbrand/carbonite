// Clickable cells for carbon_table_column(action = TRUE).
//
// carbon_table() renders those cells' content as
// <button class="carbonite-cell-action" data-column="...">. Clicking one
// (or pressing Enter/Space, since it's a real button) sets
// `input$<id>_cell_click` = {row, key, column} as an event, where <id> is
// the table's id or the output it's rendered in, like the selection input.

const ACTION = "button.carbonite-cell-action";

// The input id's base: the table's own id, or the output it's rendered in
export function cellClickBaseId(table) {
    return table.id || table.closest(".shiny-html-output")?.id || null;
}

/**
 * The value reported for a click on `button`, or null if it isn't in a
 * table row Shiny can report.
 */
export function cellClickValue(button) {
    const row = button.closest("cds-table-row");
    const table = row?.closest("cds-table");
    if (!row || !table) return null;

    return {
        row: Number(row.dataset.rowIndex),
        key: row.dataset.rowKey,
        column: button.dataset.column
    };
}

document.addEventListener("click", event => {
    const button = event.target.closest?.(ACTION);
    if (!button) return;

    const table = button.closest("cds-table");
    const base = table && cellClickBaseId(table);
    const value = cellClickValue(button);
    if (!base || !value || !window.Shiny?.setInputValue) return;

    Shiny.setInputValue(`${base}_cell_click`, value, { priority: "event" });
});
