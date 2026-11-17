// Loading skeleton for `carbon_table_output()`.
//
// The container holds the Shiny output and a skeleton `cds-table` (built in
// R). The `carbon-table-output--loading` class decides which one shows; the
// styles live in carbonite.scss. The skeleton is an ordinary `cds-table`, so
// it gets its row heights from `size` exactly like the real table.

const CONTAINER = ".carbon-table-output";
const OUTPUT = ".carbon-table-output__table";
const SKELETON = ".carbon-table-output__skeleton";
const LOADING = "carbon-table-output--loading";

export function setTableLoading(container, loading) {
    container.classList.toggle(LOADING, loading);
}

// Replace the skeleton with a copy of the rendered table whose body cells
// hold skeleton text, so it matches the table's columns, rows and size.
export function snapshotTable(container) {
    const table = container.querySelector(`${OUTPUT} cds-table`);
    const skeleton = container.querySelector(SKELETON);

    if (!table || !skeleton) return;

    const clone = table.cloneNode(true);

    clone.classList.add(SKELETON.slice(1));
    clone.setAttribute("aria-hidden", "true");
    // The copy may include a toolbar (buttons, search) and selection
    // checkboxes: keep it out of the tab order and away from Shiny's
    // selection binding.
    clone.setAttribute("inert", "");
    clone.classList.remove("carbonite-selectable-table");
    clone.removeAttribute("id");
    clone.querySelectorAll("[id]").forEach(el => el.removeAttribute("id"));
    clone.querySelectorAll("cds-table-cell").forEach(cell => {
        const text = document.createElement("span");
        text.className = "cds--skeleton__text";
        cell.replaceChildren(text);
    });
    copyColumnWidths(table, clone);

    skeleton.replaceWith(clone);
}

// Without the cell text, the skeleton's columns would size themselves
// differently from the table's. Pin each column to the share of the table's
// width it had, as a percentage so it still holds if the page is resized.
function copyColumnWidths(table, clone) {
    const tableWidth = table.getBoundingClientRect().width;
    if (!tableWidth) return;

    const sourceCells = table.querySelectorAll("cds-table-header-cell");
    const cloneCells = clone.querySelectorAll("cds-table-header-cell");

    sourceCells.forEach((cell, i) => {
        const share = cell.getBoundingClientRect().width / tableWidth;
        if (cloneCells[i] && share > 0) {
            cloneCells[i].style.width = `${(share * 100).toFixed(3)}%`;
        }
    });
}

function isSilentError(error) {
    return [].concat(error?.type ?? []).includes("shiny.silent.error");
}

function containerOf(event) {
    return event.target.matches?.(OUTPUT)
        ? event.target.closest(CONTAINER)
        : null;
}

// The old table is still in the DOM when recalculation starts, so take the
// skeleton snapshot here rather than after the new value renders.
$(document).on("shiny:recalculating", event => {
    const container = containerOf(event);
    if (!container) return;

    snapshotTable(container);
    setTableLoading(container, true);
});

$(document).on("shiny:value", event => {
    const container = containerOf(event);
    if (container) setTableLoading(container, false);
});

// Show real errors in place of the skeleton. Silent ones (`req()`) leave
// nothing to show, so keep the skeleton up until a value arrives.
$(document).on("shiny:error", event => {
    const container = containerOf(event);
    if (container && !isSilentError(event.error)) {
        setTableLoading(container, false);
    }
});
