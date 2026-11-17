import { describe, it, expect, vi, beforeAll } from "vitest";

let hideEmptyExpandButtons, expandedRowsByIndex, patchTable, sortTableRows, showPage, snapshotTable;

beforeAll(async () => {
    ({ hideEmptyExpandButtons, expandedRowsByIndex, patchTable } = await import("../table-expand.js"));
    ({ sortTableRows } = await import("../table-sort.js"));
    ({ showPage } = await import("../table-pagination.js"));
    ({ snapshotTable } = await import("../carbon-table.js"));
});

// Mirrors carbon_table(row_details = ): rows numbered 1..n by `value`, each
// followed by its expanded row; rows in `empty` have no details.
function bodyHtml(values, empty = []) {
    return values.map((value, i) => {
        const n = i + 1;
        const blank = empty.includes(n);
        return `<cds-table-row data-row-index="${n}" data-row-key="${n}"><cds-table-cell data-sort-value="${value}">${value}</cds-table-cell></cds-table-row>` +
            `<cds-table-expanded-row data-expands-row="${n}"${blank ? " data-empty" : ""}>${blank ? "" : `details ${n}`}</cds-table-expanded-row>`;
    }).join("");
}

function mountTable(values, empty = []) {
    document.body.innerHTML = `<cds-table expandable>
        <cds-table-head><cds-table-header-row>
            <cds-table-header-cell data-sort-type="numeric">N</cds-table-header-cell>
        </cds-table-header-row></cds-table-head>
        <cds-table-body>${bodyHtml(values, empty)}</cds-table-body>
    </cds-table>`;
    return document.querySelector("cds-table");
}

// The body's children, as "row:<index>" / "details:<index>"
const order = table => [...table.querySelector("cds-table-body").children].map(el =>
    el.matches("cds-table-row") ? `row:${el.dataset.rowIndex}` : `details:${el.dataset.expandsRow}`
);

describe("expandable rows", () => {
    it("takes the expand button off rows whose details are empty", () => {
        const table = mountTable([10, 20, 30], [2]);
        const rows = [...table.querySelectorAll("cds-table-row")];
        rows.forEach(row => { row.expandable = true; }); // as Carbon sets them

        hideEmptyExpandButtons(table);

        expect(rows.map(row => row.expandable)).toEqual([true, false, true]);
    });

    it("re-applies after Carbon's updateExpandable(), keeping its result", () => {
        const table = mountTable([10, 20], [1]);
        const update = vi.fn(function () {
            this.querySelectorAll("cds-table-row").forEach(row => { row.expandable = true; });
            return "carbon";
        });
        class FakeTable {}
        FakeTable.prototype.updateExpandable = update;
        patchTable(FakeTable);
        patchTable(FakeTable); // idempotent

        expect(FakeTable.prototype.updateExpandable.call(table)).toBe("carbon");
        expect(update).toHaveBeenCalledTimes(1);
        expect([...table.querySelectorAll("cds-table-row")].map(row => row.expandable)).toEqual([false, true]);
    });

    it("finds each row's expanded row by index", () => {
        const table = mountTable([10, 20]);
        const details = expandedRowsByIndex(table);

        expect([...details.keys()]).toEqual(["1", "2"]);
        expect(details.get("2").textContent).toBe("details 2");
    });

    it("keeps each row's details right after it when sorted", () => {
        const table = mountTable([30, 10, 20], [2]);

        sortTableRows(table, 0, "ascending");
        expect(order(table)).toEqual(["row:2", "details:2", "row:3", "details:3", "row:1", "details:1"]);

        sortTableRows(table, 0, "none");
        expect(order(table)).toEqual(["row:1", "details:1", "row:2", "details:2", "row:3", "details:3"]);
    });

    it("repairs pairs that Carbon's own sort mismatched", () => {
        const table = mountTable([30, 10, 20]);
        const body = table.querySelector("cds-table-body");
        // Rows with the wrong details after them
        const [r1, d1, r2, d2, r3, d3] = body.children;
        body.replaceChildren(r2, d1, r3, d3, r1, d2);

        sortTableRows(table, 0, "descending");

        expect(order(table)).toEqual(["row:1", "details:1", "row:3", "details:3", "row:2", "details:2"]);
    });

    it("pages details with their rows", () => {
        document.body.innerHTML = `<div class="carbonite-paginated-table">
            <cds-table expandable><cds-table-body>${bodyHtml([1, 2, 3, 4, 5])}</cds-table-body></cds-table>
            <cds-pagination page="1" page-size="2" total-items="5"></cds-pagination>
        </div>`;
        const table = document.querySelector("cds-table");

        showPage(table, document.querySelector("cds-pagination"), 2);

        const shown = [...table.querySelectorAll("cds-table-row, cds-table-expanded-row")]
            .filter(el => !el.hasAttribute("data-page-hidden"))
            .map(el => el.dataset.rowIndex ? `row:${el.dataset.rowIndex}` : `details:${el.dataset.expandsRow}`);
        expect(shown).toEqual(["row:3", "details:3", "row:4", "details:4"]);
    });

    it("shows details as skeleton text in the loading copy", () => {
        document.body.innerHTML = `<div class="carbon-table-output">
            <div id="tbl" class="carbon-table-output__table shiny-html-output">
                <cds-table expandable><cds-table-body>${bodyHtml([1, 2])}</cds-table-body></cds-table>
            </div>
            <cds-table class="carbon-table-output__skeleton"></cds-table>
        </div>`;
        document.querySelector("#tbl cds-table-expanded-row").setAttribute("expanded", "");

        snapshotTable(document.querySelector(".carbon-table-output"));

        const copies = document.querySelectorAll(".carbon-table-output__skeleton cds-table-expanded-row");
        expect(copies).toHaveLength(2);
        copies.forEach(copy => expect(copy.innerHTML).toBe('<span class="cds--skeleton__text"></span>'));
        expect(copies[0].hasAttribute("expanded")).toBe(true);
        expect(document.querySelector("#tbl cds-table-expanded-row").textContent).toBe("details 1");
    });
});

describe("checkbox alignment on rows without details", () => {
    it("adds one shared stylesheet to the row's shadow root, once", async () => {
        const { alignCheckbox } = await import("../table-expand.js");
        const row = document.createElement("cds-table-row");
        row.attachShadow({ mode: "open" });

        alignCheckbox(row);
        alignCheckbox(row);

        const sheets = row.shadowRoot.adoptedStyleSheets;
        expect(sheets).toHaveLength(1);
        const css = [...sheets[0].cssRules].map(rule => rule.cssText).join("");
        expect(css).toContain(".cds--table-column-checkbox");
    });

    it("skips rows Carbon hasn't rendered yet", async () => {
        const { alignCheckbox } = await import("../table-expand.js");
        expect(() => alignCheckbox(document.createElement("cds-table-row"))).not.toThrow();
    });
});
