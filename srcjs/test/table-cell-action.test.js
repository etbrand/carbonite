import { describe, it, expect, vi, beforeAll, afterEach } from "vitest";

let mod;

beforeAll(async () => {
    mod = await import("../table-cell-action.js");
});

afterEach(() => {
    delete globalThis.Shiny.setInputValue;
});

// Mirrors carbon_table() with carbon_table_column(action = TRUE) on "name",
// rendered in output "out"
function mountTable({ tableId = "" } = {}) {
    document.body.innerHTML = `<div id="out" class="shiny-html-output">
        <cds-table${tableId ? ` id="${tableId}"` : ""}>
            <cds-table-body>
                <cds-table-row data-row-index="1" data-row-key="1">
                    <cds-table-cell><button type="button" class="carbonite-cell-action" data-column="name">Chad</button></cds-table-cell>
                    <cds-table-cell>18,000,000</cds-table-cell>
                </cds-table-row>
                <cds-table-row data-row-index="2" data-row-key="NER">
                    <cds-table-cell><button type="button" class="carbonite-cell-action" data-column="name"><span>Niger</span></button></cds-table-cell>
                    <cds-table-cell>27,000,000</cds-table-cell>
                </cds-table-row>
            </cds-table-body>
        </cds-table>
    </div>`;
    return document.querySelector("cds-table");
}

describe("clickable table cells", () => {
    it("reports the clicked row and column, named after the output", () => {
        mountTable();
        globalThis.Shiny.setInputValue = vi.fn();

        document.querySelectorAll(".carbonite-cell-action")[0].click();

        expect(globalThis.Shiny.setInputValue).toHaveBeenCalledWith(
            "out_cell_click",
            { row: 1, key: "1", column: "name" },
            { priority: "event" }
        );
    });

    it("works for clicks on content inside the button, and uses the row key", () => {
        mountTable();
        globalThis.Shiny.setInputValue = vi.fn();

        document.querySelector(".carbonite-cell-action span").click();

        expect(globalThis.Shiny.setInputValue.mock.calls[0][1]).toEqual({ row: 2, key: "NER", column: "name" });
    });

    it("prefers the table's own id", () => {
        mountTable({ tableId: "countries" });
        globalThis.Shiny.setInputValue = vi.fn();

        document.querySelector(".carbonite-cell-action").click();

        expect(globalThis.Shiny.setInputValue.mock.calls[0][0]).toBe("countries_cell_click");
    });

    it("ignores clicks on other cells", () => {
        mountTable();
        globalThis.Shiny.setInputValue = vi.fn();

        document.querySelectorAll("cds-table-cell")[1].click();

        expect(globalThis.Shiny.setInputValue).not.toHaveBeenCalled();
    });

    it("reports nothing for buttons outside a table row", () => {
        document.body.innerHTML = `<button class="carbonite-cell-action" data-column="x">x</button>`;

        expect(mod.cellClickValue(document.querySelector("button"))).toBeNull();
    });
});
