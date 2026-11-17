// Lazy row details for carbon_table(lazy_details = TRUE).
//
// The table carries a token (`data-lazy-details`) and each expanded row
// starts as a placeholder (`data-lazy`). When rows are expanded, this asks
// the server for the ones not yet requested with
// `input$<id>_details_request` = {token, rows: [data-row-index, ...]}
// (render_carbon_table() answers; see .register_lazy_details() in R), and
// puts the HTML it sends back in place with Shiny.renderContent(), so the
// details can hold Shiny inputs and outputs.
//
// Requests are batched: Shiny can merge several setInputValue() calls for
// the same input in one tick, so the header's "expand all" sends one
// request with every row rather than one per row.

import { hideEmptyExpandButtons } from "./table-expand.js";

const EXPANDED_ROW = "cds-table-expanded-row";

export function isLazyTable(table) {
    return Boolean(table?.matches?.("cds-table[data-lazy-details]"));
}

// The input id's base: the table's own id, or the output it's rendered in
// (like the selection input)
export function detailsBaseId(table) {
    return table.id || table.closest(".shiny-html-output")?.id || null;
}

// Expanded rows whose details haven't been requested yet
export function rowsToRequest(table) {
    return [...table.querySelectorAll(":scope > cds-table-body > cds-table-row")]
        .filter(row => row.expanded)
        .map(row => row.nextElementSibling)
        .filter(details => details?.matches(`${EXPANDED_ROW}[data-lazy]:not([data-requested])`));
}

/**
 * Ask the server for the details of every expanded row not yet requested.
 *
 * @returns {number[]} The rows (`data-row-index`) requested.
 */
export function requestDetails(table) {
    const base = detailsBaseId(table);
    if (!isLazyTable(table) || !base || !window.Shiny?.setInputValue) return [];

    const pending = rowsToRequest(table);
    if (!pending.length) return [];

    pending.forEach(details => details.setAttribute("data-requested", ""));
    const rows = pending.map(details => Number(details.dataset.expandsRow));
    Shiny.setInputValue(
        `${base}_details_request`,
        { token: table.dataset.lazyDetails, rows },
        { priority: "event" }
    );
    return rows;
}

const scheduled = new WeakSet();

// Rows are expanded one at a time by the user, or all at once by the
// header's button; either way, request once Carbon has updated them.
function scheduleRequest(table) {
    if (scheduled.has(table)) return;
    scheduled.add(table);
    queueMicrotask(() => {
        scheduled.delete(table);
        requestDetails(table);
    });
}

document.addEventListener("cds-table-row-expando-toggled", event => {
    const table = event.target.closest?.("cds-table");
    if (isLazyTable(table)) scheduleRequest(table);
});

// The table a reply is for: by its own id, or inside the output of that id
export function findDetailsTable(base) {
    const el = document.getElementById(base);
    if (!el) return null;
    return el.matches("cds-table") ? el : el.querySelector("cds-table[data-lazy-details]");
}

async function renderInto(el, html, deps) {
    const render = window.Shiny?.renderContentAsync ?? window.Shiny?.renderContent;
    if (render) {
        await render.call(window.Shiny, el, { html, deps: deps ?? [] });
    } else {
        el.innerHTML = html;
    }
}

/**
 * Put the server's reply in place: {table, token, details: [{row, empty,
 * html, deps}]}. Replies for an earlier render (another token) are ignored.
 */
export async function applyDetails(message) {
    const table = findDetailsTable(message.table);
    if (!table || table.dataset.lazyDetails !== message.token) return;

    let emptied = false;
    for (const item of message.details ?? []) {
        const details = table.querySelector(
            `:scope > cds-table-body > ${EXPANDED_ROW}[data-expands-row="${item.row}"]`
        );
        if (!details) continue;

        details.removeAttribute("data-lazy");
        if (item.empty) {
            // Nothing to show: collapse the row and take its button off
            details.replaceChildren();
            details.setAttribute("data-empty", "");
            const row = details.previousElementSibling;
            if (row?.matches("cds-table-row")) row.expanded = false;
            emptied = true;
        } else {
            await renderInto(details, item.html, item.deps);
        }
    }

    if (emptied) hideEmptyExpandButtons(table);
}

window.Shiny?.addCustomMessageHandler?.("carbonite-table-details", applyDetails);
