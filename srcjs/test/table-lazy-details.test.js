import { describe, it, expect, vi, beforeAll, afterEach } from "vitest";

let mod;

beforeAll(async () => {
    mod = await import("../table-lazy-details.js");
});

afterEach(() => {
    delete globalThis.Shiny.setInputValue;
    delete globalThis.Shiny.renderContent;
    delete globalThis.Shiny.renderContentAsync;
});

// Mirrors carbon_table(lazy_details = TRUE) inside render_carbon_table(
// output "out"): rows 1..n, each followed by a placeholder expanded row.
function mountTable({ rows = 3, token = "lazy-1", tableId = "" } = {}) {
    const body = Array.from({ length: rows }, (_, i) => {
        const n = i + 1;
        return `<cds-table-row data-row-index="${n}" data-row-key="${n}"><cds-table-cell>${n}</cds-table-cell></cds-table-row>` +
            `<cds-table-expanded-row data-expands-row="${n}" data-lazy><div class="carbonite-details-loading"></div></cds-table-expanded-row>`;
    }).join("");

    document.body.innerHTML = `<div id="out" class="shiny-html-output">
        <cds-table${tableId ? ` id="${tableId}"` : ""} expandable data-lazy-details="${token}">
            <cds-table-body>${body}</cds-table-body>
        </cds-table>
    </div>`;
    return document.querySelector("cds-table");
}

const row = (table, n) => table.querySelector(`cds-table-row[data-row-index="${n}"]`);
const details = (table, n) => table.querySelector(`cds-table-expanded-row[data-expands-row="${n}"]`);
const flush = () => new Promise(resolve => setTimeout(resolve, 0));

describe("requesting lazy details", () => {
    it("asks for the expanded rows not yet requested, once each", () => {
        const table = mountTable();
        globalThis.Shiny.setInputValue = vi.fn();
        row(table, 1).expanded = true;
        row(table, 3).expanded = true;

        expect(mod.requestDetails(table)).toEqual([1, 3]);
        expect(globalThis.Shiny.setInputValue).toHaveBeenCalledWith(
            "out_details_request",
            { token: "lazy-1", rows: [1, 3] },
            { priority: "event" }
        );

        // Already requested: nothing more to ask for
        expect(mod.requestDetails(table)).toEqual([]);
        expect(globalThis.Shiny.setInputValue).toHaveBeenCalledTimes(1);
    });

    it("names the input after the table's own id when it has one", () => {
        const table = mountTable({ tableId: "cars" });
        globalThis.Shiny.setInputValue = vi.fn();
        row(table, 2).expanded = true;

        mod.requestDetails(table);

        expect(globalThis.Shiny.setInputValue.mock.calls[0][0]).toBe("cars_details_request");
    });

    it("sends one request when several rows expand together", async () => {
        const table = mountTable();
        globalThis.Shiny.setInputValue = vi.fn();

        // What the header's "expand all" does: every row, then one event
        [1, 2, 3].forEach(n => { row(table, n).expanded = true; });
        [1, 2, 3].forEach(n => row(table, n).dispatchEvent(
            new CustomEvent("cds-table-row-expando-toggled", { bubbles: true, composed: true, detail: { expanded: true } })
        ));
        await flush();

        expect(globalThis.Shiny.setInputValue).toHaveBeenCalledTimes(1);
        expect(globalThis.Shiny.setInputValue.mock.calls[0][1].rows).toEqual([1, 2, 3]);
    });

    it("leaves tables without lazy details alone", async () => {
        const table = mountTable();
        table.removeAttribute("data-lazy-details");
        globalThis.Shiny.setInputValue = vi.fn();
        row(table, 1).expanded = true;

        row(table, 1).dispatchEvent(new CustomEvent("cds-table-row-expando-toggled", { bubbles: true }));
        await flush();

        expect(mod.requestDetails(table)).toEqual([]);
        expect(globalThis.Shiny.setInputValue).not.toHaveBeenCalled();
    });
});

describe("applying the server's reply", () => {
    it("renders each row's details with Shiny, binding inputs and outputs", async () => {
        const table = mountTable();
        const deps = [{ name: "dep", version: "1" }];
        globalThis.Shiny.renderContentAsync = vi.fn(async (el, content) => { el.innerHTML = content.html; });

        await mod.applyDetails({
            table: "out",
            token: "lazy-1",
            details: [{ row: 2, empty: false, html: "<p>Two</p>", deps }]
        });

        expect(details(table, 2).innerHTML).toBe("<p>Two</p>");
        expect(details(table, 2).hasAttribute("data-lazy")).toBe(false);
        expect(globalThis.Shiny.renderContentAsync).toHaveBeenCalledWith(details(table, 2), { html: "<p>Two</p>", deps });
        // Other rows are still placeholders
        expect(details(table, 1).hasAttribute("data-lazy")).toBe(true);
    });

    it("collapses rows without details and takes their button off", async () => {
        const table = mountTable();
        row(table, 1).expanded = true;
        row(table, 1).expandable = true;

        await mod.applyDetails({ table: "out", token: "lazy-1", details: [{ row: 1, empty: true }] });

        expect(details(table, 1).hasAttribute("data-empty")).toBe(true);
        expect(details(table, 1).children.length).toBe(0);
        expect(row(table, 1).expanded).toBe(false);
        expect(row(table, 1).expandable).toBe(false);
    });

    it("ignores replies meant for an earlier render", async () => {
        const table = mountTable({ token: "lazy-2" });

        await mod.applyDetails({
            table: "out",
            token: "lazy-1",
            details: [{ row: 1, empty: false, html: "<p>Stale</p>" }]
        });

        expect(details(table, 1).hasAttribute("data-lazy")).toBe(true);
        expect(details(table, 1).textContent).not.toContain("Stale");
    });

    it("finds the table by its own id too", () => {
        const table = mountTable({ tableId: "cars" });

        expect(mod.findDetailsTable("cars")).toBe(table);
        expect(mod.findDetailsTable("out")).toBe(table);
        expect(mod.findDetailsTable("nope")).toBeNull();
    });
});
