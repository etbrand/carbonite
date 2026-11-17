// Client-side pagination for carbon_table(page_size = ).
//
// carbon_table() wraps the table and a `cds-pagination` in a
// .carbonite-paginated-table div, and marks the rows beyond the first page
// with `data-page-hidden` (hidden by carbonite.scss). All rows are in the
// page; this shows one page of them at a time, so it works with the
// browser-side sorting (table-sort.js) and search (Carbon's toolbar search,
// which hides rows with its own `filtered` attribute):
//   * paging and changing the page size show the requested page;
//   * searching goes back to page 1 and pages through the matching rows only;
//   * sorting keeps the current page, now in the new order.
//
// The header "select all" checkbox selects the rows on the current page, as
// Carbon's guidance describes; selections on other pages are kept.

import { syncCarbonSelection, isFiltered } from "./bindings/carbon-table-selection.js";
import { expandedRowsByIndex } from "./table-expand.js";

const WRAPPER = ".carbonite-paginated-table";
export const PAGE_HIDDEN = "data-page-hidden";

export function partsOf(el) {
    const wrapper = el?.closest?.(WRAPPER);
    if (!wrapper) return null;

    const table = wrapper.querySelector(":scope > cds-table");
    const pagination = wrapper.querySelector(":scope > cds-pagination");
    return table && pagination ? { table, pagination } : null;
}

function bodyRows(table) {
    return [...table.querySelectorAll(":scope > cds-table-body > cds-table-row")];
}

function numberOf(el, property, attribute, fallback) {
    const value = Number(el[property] ?? el.getAttribute(attribute));
    return Number.isFinite(value) && value > 0 ? value : fallback;
}

/**
 * Show one page of a paginated carbon_table().
 *
 * @param {Element} table The `cds-table`.
 * @param {Element} pagination Its `cds-pagination`.
 * @param {number} [page] The page to show (clamped to the pages there are).
 *   Defaults to the pagination's current page.
 * @returns {number} The page shown.
 */
export function showPage(table, pagination, page) {
    const pageSize = numberOf(pagination, "pageSize", "page-size", 10);
    const rows = bodyRows(table);
    const matching = rows.filter(row => !isFiltered(row));
    const pages = Math.max(1, Math.ceil(matching.length / pageSize));

    page = Math.min(Math.max(1, Math.floor(page ?? numberOf(pagination, "page", "page", 1))), pages);

    const start = (page - 1) * pageSize;
    const onPage = new Set(matching.slice(start, start + pageSize));
    // A row's expanded row (carbon_table(row_details = )) is on its page
    const details = expandedRowsByIndex(table);
    rows.forEach(row => {
        const hidden = !onPage.has(row);
        row.toggleAttribute(PAGE_HIDDEN, hidden);
        details.get(row.dataset.rowIndex)?.toggleAttribute(PAGE_HIDDEN, hidden);
    });

    // Attributes as well as properties, so a copy of the pagination (the
    // carbon_table_output() loading skeleton) shows the same status.
    pagination.totalItems = matching.length;
    pagination.setAttribute("total-items", matching.length);
    pagination.page = page;
    pagination.setAttribute("page", page);

    // The header checkbox reflects the rows on this page.
    if (table.classList.contains("carbonite-selectable-table")) {
        syncCarbonSelection(table);
    }

    return page;
}

/**
 * "Select all" on a paginated table: select or clear the rows on the
 * current page that match the search.
 */
export function selectPage(table, selected) {
    bodyRows(table)
        .filter(row => !row.hasAttribute(PAGE_HIDDEN) && !isFiltered(row) && !row.hasAttribute("disabled"))
        .forEach(row => {
            row.selected = selected;
            row.toggleAttribute("selected", selected);
        });

    syncCarbonSelection(table);
    // Tells the selection binding to report the new value.
    table.dispatchEvent(new CustomEvent("carbonite:table-selection-change"));
}

// Paging and page size: Carbon has already updated `page`/`pageSize`.
document.addEventListener("cds-pagination-changed-current", event => {
    const parts = partsOf(event.target);
    if (parts) showPage(parts.table, parts.pagination, event.detail?.page);
});

document.addEventListener("cds-page-sizes-select-changed", event => {
    const parts = partsOf(event.target);
    if (parts) showPage(parts.table, parts.pagination, 1);
});

// Carbon filters the rows in its own listener on the table, which runs
// before this one on the document.
document.addEventListener("cds-search-input", event => {
    const parts = partsOf(event.target);
    if (parts) showPage(parts.table, parts.pagination, 1);
});

// Fired by table-sort.js once the rows are in their new order.
document.addEventListener("carbonite:table-sorted", event => {
    const parts = partsOf(event.target);
    if (parts) showPage(parts.table, parts.pagination);
});

// Carbon's own select-all handler (a listener on the table) would select
// every row, on every page. Stop the event on its way down, in the capture
// phase, and select the current page instead. The header row still updates
// itself, since the event isn't cancelled.
document.addEventListener("cds-table-change-selection-all", event => {
    const parts = partsOf(event.target);
    if (!parts || event.target.closest("cds-table") !== parts.table) return;

    event.stopPropagation();
    selectPage(parts.table, Boolean(event.detail?.selected));
}, true);
