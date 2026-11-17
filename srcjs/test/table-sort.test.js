import { describe, it, expect } from "vitest";
import { sortTableRows } from "../table-sort.js";

// Mirrors carbon_table(): numeric columns carry data-sort-type on the header
// and data-sort-value on each cell; rows carry data-row-index.
// columns: [{ label, numeric }]; rows: [[{ text, value? }, ...], ...]
function mountTable(columns, rows) {
    const head = columns.map(({ label, numeric }) =>
        `<cds-table-header-cell is-sortable="none"${numeric ? ' data-sort-type="numeric"' : ""}>${label}</cds-table-header-cell>`
    ).join("");
    const body = rows.map((cells, i) => `
        <cds-table-row data-row-index="${i + 1}">${cells.map(({ text, value }) =>
            `<cds-table-cell${value !== undefined ? ` data-sort-value="${value}"` : ""}>${text}</cds-table-cell>`
        ).join("")}</cds-table-row>`).join("");

    document.body.innerHTML = `
        <cds-table>
            <cds-table-head><cds-table-header-row>${head}</cds-table-header-row></cds-table-head>
            <cds-table-body>${body}</cds-table-body>
        </cds-table>`;
    return document.querySelector("cds-table");
}

const order = table =>
    [...table.querySelectorAll("cds-table-row")].map(row => row.dataset.rowIndex);

const columnText = (table, i) =>
    [...table.querySelectorAll("cds-table-row")].map(
        row => row.querySelectorAll("cds-table-cell")[i].textContent
    );

// hp column formatted as "<n> hp": text sort would give 110, 175, 93
const hpTable = () => mountTable(
    [{ label: "Name" }, { label: "HP", numeric: true }],
    [
        [{ text: "Mazda" }, { text: "110 hp", value: "110" }],
        [{ text: "Datsun" }, { text: "93 hp", value: "93" }],
        [{ text: "Hornet" }, { text: "175 hp", value: "175" }]
    ]
);

describe("sortTableRows", () => {
    it("sorts numeric columns by value, not text", () => {
        const table = hpTable();

        sortTableRows(table, 1, "ascending");
        expect(columnText(table, 1)).toEqual(["93 hp", "110 hp", "175 hp"]);

        sortTableRows(table, 1, "descending");
        expect(columnText(table, 1)).toEqual(["175 hp", "110 hp", "93 hp"]);
    });

    it("handles negatives and decimals", () => {
        const table = mountTable([{ label: "x", numeric: true }], [
            [{ text: "2.9", value: "2.9" }],
            [{ text: "-10", value: "-10" }],
            [{ text: "2.10", value: "2.1" }],
            [{ text: "-5", value: "-5" }]
        ]);

        sortTableRows(table, 0, "ascending");
        expect(columnText(table, 0)).toEqual(["-10", "-5", "2.10", "2.9"]);
    });

    it("sorts text columns by text", () => {
        const table = hpTable();

        sortTableRows(table, 0, "ascending");
        expect(columnText(table, 0)).toEqual(["Datsun", "Hornet", "Mazda"]);
    });

    it("puts missing values last in both directions", () => {
        const table = mountTable([{ label: "x", numeric: true }], [
            [{ text: "NA" }],
            [{ text: "2", value: "2" }],
            [{ text: "1", value: "1" }]
        ]);

        sortTableRows(table, 0, "ascending");
        expect(columnText(table, 0)).toEqual(["1", "2", "NA"]);

        sortTableRows(table, 0, "descending");
        expect(columnText(table, 0)).toEqual(["2", "1", "NA"]);
    });

    it("keeps the original order for ties", () => {
        const table = mountTable([{ label: "x", numeric: true }], [
            [{ text: "1", value: "1" }],
            [{ text: "0", value: "0" }],
            [{ text: "1", value: "1" }]
        ]);

        sortTableRows(table, 0, "descending");
        expect(order(table)).toEqual(["1", "3", "2"]);
    });

    it("restores the original order for 'none'", () => {
        const table = hpTable();

        sortTableRows(table, 1, "descending");
        sortTableRows(table, 1, "none");
        expect(order(table)).toEqual(["1", "2", "3"]);
    });

    it("leaves tables without row indices alone", () => {
        const table = hpTable();
        table.querySelector("cds-table-row").removeAttribute("data-row-index");
        const before = columnText(table, 1);

        expect(sortTableRows(table, 1, "ascending")).toBe(false);
        expect(columnText(table, 1)).toEqual(before);
    });
});

describe("cds-table-header-cell-sort event", () => {
    const fireSort = (header, sortDirection, cancel = false) => {
        const event = new CustomEvent("cds-table-header-cell-sort", {
            bubbles: true, composed: true, cancelable: true,
            detail: { sortDirection }
        });
        if (cancel) header.addEventListener("cds-table-header-cell-sort", e => e.preventDefault(), { once: true });
        header.dispatchEvent(event);
    };

    it("sorts by the clicked column in the event's direction", () => {
        const table = hpTable();
        const headers = table.querySelectorAll("cds-table-header-cell");

        fireSort(headers[1], "ascending");
        expect(columnText(table, 1)).toEqual(["93 hp", "110 hp", "175 hp"]);

        fireSort(headers[0], "descending");
        expect(columnText(table, 0)).toEqual(["Mazda", "Hornet", "Datsun"]);
    });

    it("does nothing when the sort is cancelled", () => {
        const table = hpTable();
        const before = order(table);

        fireSort(table.querySelectorAll("cds-table-header-cell")[1], "ascending", true);
        expect(order(table)).toEqual(before);
    });
});
