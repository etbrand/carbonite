import { describe, it, expect, vi, beforeAll } from "vitest";

let showPage, selectPage, PAGE_HIDDEN, sortTableRows;

beforeAll(async () => {
    ({ showPage, selectPage, PAGE_HIDDEN } = await import("../table-pagination.js"));
    ({ sortTableRows } = await import("../table-sort.js"));
});

// Mirrors carbon_table(page_size = ): rows numbered 1..n with a numeric
// sort column, rows after the first page hidden.
function mountTable({ rows = 7, pageSize = 3, selectable = false } = {}) {
    const body = Array.from({ length: rows }, (_, i) => {
        const n = i + 1;
        const hidden = n > pageSize ? ` ${PAGE_HIDDEN}` : "";
        return `<cds-table-row data-row-index="${n}" data-row-key="${n}"${hidden}>` +
            `<cds-table-cell data-sort-value="${n}">${n}</cds-table-cell></cds-table-row>`;
    }).join("");

    document.body.innerHTML = `
        <div class="carbonite-paginated-table">
            <cds-table${selectable ? ` class="carbonite-selectable-table" is-selectable` : ""}>
                <cds-table-head><cds-table-header-row>
                    <cds-table-header-cell data-sort-type="numeric">N</cds-table-header-cell>
                </cds-table-header-row></cds-table-head>
                <cds-table-body>${body}</cds-table-body>
            </cds-table>
            <cds-pagination page="1" page-size="${pageSize}" total-items="${rows}"></cds-pagination>
        </div>`;

    return {
        table: document.querySelector("cds-table"),
        pagination: document.querySelector("cds-pagination")
    };
}

const rows = table => [...table.querySelectorAll("cds-table-row")];
const shown = table => rows(table)
    .filter(row => !row.hasAttribute(PAGE_HIDDEN))
    .map(row => row.textContent);
const selectedKeys = table => rows(table)
    .filter(row => row.selected)
    .map(row => row.dataset.rowKey);

const fire = (el, type, detail) =>
    el.dispatchEvent(new CustomEvent(type, { bubbles: true, composed: true, detail }));

describe("showPage", () => {
    it("shows the rows of the requested page", () => {
        const { table, pagination } = mountTable();

        expect(showPage(table, pagination, 2)).toBe(2);
        expect(shown(table)).toEqual(["4", "5", "6"]);

        expect(showPage(table, pagination, 3)).toBe(3);
        expect(shown(table)).toEqual(["7"]);
    });

    it("clamps the page to the pages there are", () => {
        const { table, pagination } = mountTable();

        expect(showPage(table, pagination, 99)).toBe(3);
        expect(showPage(table, pagination, 0)).toBe(1);
        expect(shown(table)).toEqual(["1", "2", "3"]);
    });

    it("defaults to the pagination's current page", () => {
        const { table, pagination } = mountTable();
        pagination.page = 2;

        expect(showPage(table, pagination)).toBe(2);
    });

    it("pages through only the rows that match the search", () => {
        const { table, pagination } = mountTable();
        // Carbon's search sets `filtered` as a property first
        rows(table).forEach((row, i) => { row.filtered = i % 2 === 1; });

        showPage(table, pagination, 1);
        expect(shown(table)).toEqual(["1", "3", "5"]);
        expect(pagination.totalItems).toBe(4);
        expect(pagination.getAttribute("total-items")).toBe("4");

        showPage(table, pagination, 2);
        expect(shown(table)).toEqual(["7"]);
    });

    it("updates the pagination's page and total as attributes too", () => {
        const { table, pagination } = mountTable();

        showPage(table, pagination, 2);

        expect(pagination.page).toBe(2);
        expect(pagination.getAttribute("page")).toBe("2");
        expect(pagination.totalItems).toBe(7);
    });

    it("uses the new page size", () => {
        const { table, pagination } = mountTable();
        pagination.pageSize = 5;

        showPage(table, pagination, 1);
        expect(shown(table)).toEqual(["1", "2", "3", "4", "5"]);
    });

    it("shows an empty table when nothing matches", () => {
        const { table, pagination } = mountTable();
        rows(table).forEach(row => { row.filtered = true; });

        expect(showPage(table, pagination, 2)).toBe(1);
        expect(shown(table)).toEqual([]);
        expect(pagination.totalItems).toBe(0);
    });
});

describe("pagination events", () => {
    it("shows the page Carbon moved to", () => {
        const { table, pagination } = mountTable();

        fire(pagination, "cds-pagination-changed-current", { page: 2, pageSize: 3 });

        expect(shown(table)).toEqual(["4", "5", "6"]);
    });

    it("goes back to page 1 when the page size changes", () => {
        const { table, pagination } = mountTable();
        showPage(table, pagination, 3);
        pagination.pageSize = 4;

        fire(pagination, "cds-page-sizes-select-changed", { page: 1, pageSize: 4 });

        expect(shown(table)).toEqual(["1", "2", "3", "4"]);
    });

    it("goes back to page 1 on search", () => {
        const { table, pagination } = mountTable();
        showPage(table, pagination, 3);

        fire(table, "cds-search-input", { value: "x" });

        expect(pagination.page).toBe(1);
        expect(shown(table)).toEqual(["1", "2", "3"]);
    });

    it("keeps the current page when sorted, showing the new order", () => {
        const { table, pagination } = mountTable();
        showPage(table, pagination, 1);

        sortTableRows(table, 0, "descending");
        fire(table, "carbonite:table-sorted");

        expect(pagination.page).toBe(1);
        expect(shown(table)).toEqual(["7", "6", "5"]);
    });

    it("leaves tables without pagination alone", () => {
        document.body.innerHTML = `<cds-table><cds-table-body>
            <cds-table-row data-row-index="1"><cds-table-cell>1</cds-table-cell></cds-table-row>
        </cds-table-body></cds-table>`;

        fire(document.querySelector("cds-table"), "cds-search-input", { value: "x" });

        expect(document.querySelector(`[${PAGE_HIDDEN}]`)).toBeNull();
    });
});

describe("select all on a paginated table", () => {
    it("selects only the rows on the current page and tells the binding", () => {
        const { table, pagination } = mountTable({ selectable: true });
        showPage(table, pagination, 2);
        const changed = vi.fn();
        table.addEventListener("carbonite:table-selection-change", changed);

        selectPage(table, true);

        expect(selectedKeys(table)).toEqual(["4", "5", "6"]);
        expect(changed).toHaveBeenCalledTimes(1);
    });

    it("clears the current page, keeping other pages' selections", () => {
        const { table, pagination } = mountTable({ selectable: true });
        rows(table).forEach(row => { row.selected = true; });
        showPage(table, pagination, 2);

        selectPage(table, false);

        expect(selectedKeys(table)).toEqual(["1", "2", "3", "7"]);
    });

    it("skips rows hidden by the search", () => {
        const { table, pagination } = mountTable({ selectable: true });
        rows(table)[1].filtered = true;
        showPage(table, pagination, 1);

        selectPage(table, true);

        expect(selectedKeys(table)).toEqual(["1", "3", "4"]);
    });

    it("stops Carbon's select-all from reaching the table", () => {
        const { table } = mountTable({ selectable: true });
        const headerRow = table.querySelector("cds-table-header-row");
        const carbonHandler = vi.fn();
        table.addEventListener("cds-table-change-selection-all", carbonHandler);

        fire(headerRow, "cds-table-change-selection-all", { selected: true });

        expect(carbonHandler).not.toHaveBeenCalled();
        expect(selectedKeys(table)).toEqual(["1", "2", "3"]);
    });

    it("lets Carbon handle select-all on tables without pagination", () => {
        document.body.innerHTML = `<cds-table class="carbonite-selectable-table">
            <cds-table-head><cds-table-header-row></cds-table-header-row></cds-table-head>
        </cds-table>`;
        const table = document.querySelector("cds-table");
        const carbonHandler = vi.fn();
        table.addEventListener("cds-table-change-selection-all", carbonHandler);

        fire(table.querySelector("cds-table-header-row"), "cds-table-change-selection-all", { selected: true });

        expect(carbonHandler).toHaveBeenCalledTimes(1);
    });
});
