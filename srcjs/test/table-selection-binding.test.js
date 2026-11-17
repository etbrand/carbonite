import { describe, it, expect, vi, beforeAll } from "vitest";

let binding;
let mod;

beforeAll(async () => {
    mod = await import("../bindings/carbon-table-selection.js");
    binding = getBinding("carbon.tableSelection");
});

// Mirrors carbon_table(selection = ...): rows carry data-row-index,
// data-row-key and (when selected) the `selected` attribute.
function mountTable({ keys = ["1", "2", "3"], selected = [], keyType = "index", single = false, id = "", inOutput = "out1" } = {}) {
    const rows = keys.map((key, i) =>
        `<cds-table-row data-row-index="${i + 1}" data-row-key="${key}" selection-name="${key}"${selected.includes(key) ? " selected" : ""}><cds-table-cell>${key}</cds-table-cell></cds-table-row>`
    ).join("");
    const table = `
        <cds-table ${id ? `id="${id}"` : ""} class="carbonite-selectable-table" is-selectable data-row-key-type="${keyType}"${single ? " radio" : ""}>
            <cds-table-head><cds-table-header-row></cds-table-header-row></cds-table-head>
            <cds-table-body>${rows}</cds-table-body>
        </cds-table>`;

    document.body.innerHTML = inOutput
        ? `<div id="${inOutput}" class="shiny-html-output">${table}</div>`
        : table;
    return document.querySelector("cds-table");
}

// What Shiny binds: the marker that find() attaches next to the table.
function bound(table) {
    const markers = binding.find(document.body);
    return [...markers].find(marker => marker.previousElementSibling === table);
}

const row = (table, key) => table.querySelector(`cds-table-row[data-row-key="${key}"]`);
const flush = () => new Promise(resolve => setTimeout(resolve, 0));

describe("carbon.tableSelection binding: find and ids", () => {
    it("attaches a hidden marker to each selectable table only", () => {
        document.body.innerHTML = `
            <div id="o1" class="shiny-html-output"><cds-table class="carbonite-selectable-table"></cds-table></div>
            <div id="o2" class="shiny-html-output"><cds-table></cds-table></div>`;

        const found = binding.find(document.body);

        expect(found).toHaveLength(1);
        expect(found[0].hidden).toBe(true);
        expect(found[0].previousElementSibling.tagName).toBe("CDS-TABLE");
    });

    it("names the input after the enclosing output's id", () => {
        const table = mountTable({ inOutput: "cars" });

        expect(bound(table).id).toBe("cars_selected");
        expect(binding.getId(bound(table))).toBe("cars_selected");
    });

    it("prefers the table's own id, and leaves that id alone", () => {
        const table = mountTable({ id: "t1", inOutput: "" });

        expect(bound(table).id).toBe("t1_selected");
        expect(table.id).toBe("t1");
    });

    it("is idempotent", () => {
        const table = mountTable();
        binding.find(document.body);
        binding.find(document.body);

        expect(document.querySelectorAll(".carbonite-table-selection")).toHaveLength(1);
        expect(bound(table)).toBeDefined();
    });

    it("skips tables with no id to name the input after", () => {
        mountTable({ inOutput: "" });

        expect(binding.find(document.body)).toHaveLength(0);
    });
});

describe("carbon.tableSelection binding: values", () => {
    it("reports row numbers as numbers, in data order", () => {
        const table = mountTable({ selected: ["3", "1"] });
        // Display order shouldn't matter (e.g. after sorting)
        table.querySelector("cds-table-body").prepend(row(table, "3"));

        expect(binding.getValue(bound(table))).toEqual([1, 3]);
    });

    it("reports row_key values as strings", () => {
        const table = mountTable({ keys: ["a", "b", "c"], keyType: "key", selected: ["b"] });

        expect(binding.getValue(bound(table))).toEqual(["b"]);
    });

    it("prefers the row's selected property over its attribute", () => {
        const table = mountTable({ selected: ["1"] });
        row(table, "1").selected = false;
        row(table, "2").selected = true;

        expect(binding.getValue(bound(table))).toEqual([2]);
    });

    it("returns null when nothing is selected", () => {
        const table = mountTable();

        expect(binding.getValue(bound(table))).toBeNull();
    });
});

describe("carbon.tableSelection binding: events and messages", () => {
    it("subscribe fires on Carbon's selection events, after the row updates", async () => {
        for (const type of ["cds-table-row-selected", "cds-table-row-all-selected"]) {
            const table = mountTable();
            const marker = bound(table);
            const callback = vi.fn(() => { callback.value = binding.getValue(marker); });
            binding.subscribe(marker, callback);

            // Carbon fires the event before setting the row's `selected`
            table.dispatchEvent(new CustomEvent(type, { bubbles: true }));
            row(table, "2").selected = true;
            expect(callback).not.toHaveBeenCalled();

            await flush();
            expect(callback).toHaveBeenCalledWith(false);
            expect(callback.value).toEqual([2]);
        }
    });

    it("unsubscribe removes the listeners", async () => {
        const table = mountTable();
        const marker = bound(table);
        const callback = vi.fn();
        binding.subscribe(marker, callback);
        binding.unsubscribe(marker);

        table.dispatchEvent(new CustomEvent("cds-table-row-selected", { bubbles: true }));
        await flush();

        expect(callback).not.toHaveBeenCalled();
        expect(marker._carbonInputHandler).toBeUndefined();
    });

    it("receiveMessage sets the selection and notifies Shiny", async () => {
        const table = mountTable({ selected: ["1"] });
        const marker = bound(table);
        const callback = vi.fn();
        binding.subscribe(marker, callback);

        binding.receiveMessage(marker, { selected: ["2", "3"] });
        await flush();

        expect(binding.getValue(marker)).toEqual([2, 3]);
        expect(row(table, "1").hasAttribute("selected")).toBe(false);
        expect(callback).toHaveBeenCalledTimes(1);
    });

    it("receiveMessage accepts a scalar and an empty selection", () => {
        const table = mountTable();
        const marker = bound(table);

        binding.receiveMessage(marker, { selected: "2" });
        expect(binding.getValue(marker)).toEqual([2]);

        binding.receiveMessage(marker, { selected: [] });
        expect(binding.getValue(marker)).toBeNull();
    });

    it("receiveMessage ignores unknown keys and messages without `selected`", () => {
        const table = mountTable({ selected: ["1"] });
        const marker = bound(table);

        binding.receiveMessage(marker, {});
        expect(binding.getValue(marker)).toEqual([1]);

        binding.receiveMessage(marker, { selected: ["9", "2"] });
        expect(binding.getValue(marker)).toEqual([2]);
    });

    it("selects at most one row in single mode", () => {
        const table = mountTable({ single: true });
        const marker = bound(table);

        binding.receiveMessage(marker, { selected: ["2", "3"] });

        expect(binding.getValue(marker)).toEqual([2]);
    });
});

describe("syncCarbonSelection", () => {
    it("updates the batch actions bar and toolbar", () => {
        const table = mountTable({ selected: ["1", "2"] });
        table.insertAdjacentHTML("afterbegin", `
            <cds-table-toolbar slot="toolbar">
                <cds-table-batch-actions></cds-table-batch-actions>
                <cds-table-toolbar-content></cds-table-toolbar-content>
            </cds-table-toolbar>`);
        table._selectedRows = [];

        mod.syncCarbonSelection(table);

        const batch = table.querySelector("cds-table-batch-actions");
        expect(batch.selectedRowsCount).toBe(2);
        expect(batch.active).toBe(true);
        expect(table.querySelector("cds-table-toolbar-content").hasBatchActions).toBe(true);
        expect(table._selectedRows.map(r => r.dataset.rowKey)).toEqual(["1", "2"]);
    });

    it("checks only the selected row's radio in single mode", () => {
        const table = mountTable({ single: true, selected: ["2"] });
        // Stand-in for the radio Carbon renders in each row's shadow root
        const radios = ["1", "2", "3"].map(key => {
            const r = row(table, key);
            r.attachShadow({ mode: "open" }).innerHTML = "<cds-radio-button></cds-radio-button>";
            const radio = r.shadowRoot.querySelector("cds-radio-button");
            radio.checked = true;
            return radio;
        });

        mod.syncCarbonSelection(table);

        expect(radios.map(r => r.checked)).toEqual([false, true, false]);
    });
});
