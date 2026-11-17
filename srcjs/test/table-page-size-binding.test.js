import { describe, it, expect, vi, beforeAll } from "vitest";

let binding;

beforeAll(async () => {
    await import("../bindings/carbon-table-page-size.js");
    binding = getBinding("carbon.tablePageSize");
});

// Mirrors carbon_table(page_size = ) inside render_carbon_table(): a wrapper
// holding the table and a cds-pagination without an id.
function paginated({ tableId = "", pageSize = 10 } = {}) {
    return `
        <div class="carbonite-paginated-table">
            <cds-table${tableId ? ` id="${tableId}"` : ""}></cds-table>
            <cds-pagination page="1" page-size="${pageSize}" total-items="52"></cds-pagination>
        </div>`;
}

const flush = () => new Promise(resolve => setTimeout(resolve, 0));

describe("carbon.tablePageSize binding", () => {
    it("binds a paginated table's pagination, named after the output", () => {
        document.body.innerHTML = `<div id="table" class="shiny-html-output">${paginated()}</div>`;

        const found = binding.find(document.body);

        expect(found.length).toBe(1);
        expect(binding.getId(found[0])).toBe("table_page_size");
    });

    it("prefers the table's own id", () => {
        document.body.innerHTML = `<div id="out" class="shiny-html-output">${paginated({ tableId: "cars" })}</div>`;

        expect(binding.getId(binding.find(document.body)[0])).toBe("cars_page_size");
    });

    it("skips the loading skeleton's copy and tables it can't name", () => {
        document.body.innerHTML = `
            <div id="out" class="shiny-html-output">${paginated()}</div>
            <div class="carbon-table-output__skeleton">${paginated()}</div>
            ${paginated()}`;

        const found = binding.find(document.body);

        expect(found.length).toBe(1);
        expect(found[0].id).toBe("out_page_size");
    });

    it("reports the page size as a number", () => {
        document.body.innerHTML = `<div id="out" class="shiny-html-output">${paginated({ pageSize: 25 })}</div>`;
        const pagination = binding.find(document.body)[0];

        expect(binding.getValue(pagination)).toBe(25);

        pagination.pageSize = 50;
        expect(binding.getValue(pagination)).toBe(50);
    });

    it("reports when the user changes the page size", async () => {
        document.body.innerHTML = `<div id="out" class="shiny-html-output">${paginated()}</div>`;
        const pagination = binding.find(document.body)[0];
        const callback = vi.fn();
        binding.subscribe(pagination, callback);

        pagination.dispatchEvent(new CustomEvent("cds-page-sizes-select-changed", { bubbles: true }));
        await flush();
        expect(callback).toHaveBeenCalledWith(false);

        binding.unsubscribe(pagination);
        callback.mockClear();
        pagination.dispatchEvent(new CustomEvent("cds-page-sizes-select-changed", { bubbles: true }));
        await flush();
        expect(callback).not.toHaveBeenCalled();
    });
});
