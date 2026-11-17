import { describe, it, expect, beforeEach } from "vitest";
import { setTableLoading, snapshotTable } from "../carbon-table.js";

// Mirrors carbon_table_output() + a rendered carbon_table().
function mountOutput({ size = "sm", rows = 2 } = {}) {
    const bodyRows = Array.from({ length: rows }, (_, i) => `
        <cds-table-row size="${size}">
            <cds-table-cell>a${i}</cds-table-cell>
            <cds-table-cell>b${i}</cds-table-cell>
        </cds-table-row>`).join("");

    document.body.innerHTML = `
        <div class="carbon-table-output carbon-table-output--loading">
            <div id="tbl" class="carbon-table-output__table shiny-html-output">
                <cds-table size="${size}">
                    <cds-table-head>
                        <cds-table-header-row size="${size}">
                            <cds-table-header-cell>A</cds-table-header-cell>
                            <cds-table-header-cell>B</cds-table-header-cell>
                        </cds-table-header-row>
                    </cds-table-head>
                    <cds-table-body>${bodyRows}</cds-table-body>
                </cds-table>
            </div>
            <cds-table class="carbon-table-output__skeleton" size="md" aria-hidden="true">
                <cds-table-body></cds-table-body>
            </cds-table>
        </div>`;

    return {
        container: document.querySelector(".carbon-table-output"),
        output: document.getElementById("tbl")
    };
}

const skeletonOf = container =>
    container.querySelector(".carbon-table-output__skeleton");
const isLoading = container =>
    container.classList.contains("carbon-table-output--loading");

describe("snapshotTable", () => {
    it("copies the rendered table's size, headers and row count", () => {
        const { container } = mountOutput({ size: "xs", rows: 3 });

        snapshotTable(container);
        const skeleton = skeletonOf(container);

        expect(skeleton.getAttribute("size")).toBe("xs");
        expect(skeleton.getAttribute("aria-hidden")).toBe("true");
        expect(skeleton.querySelectorAll("cds-table-row")).toHaveLength(3);
        expect(
            Array.from(skeleton.querySelectorAll("cds-table-header-cell"))
                .map(cell => cell.textContent)
        ).toEqual(["A", "B"]);
        expect(container.querySelectorAll(".carbon-table-output__skeleton"))
            .toHaveLength(1);
    });

    it("replaces body cell content with skeleton text", () => {
        const { container } = mountOutput();

        snapshotTable(container);
        const cells = skeletonOf(container).querySelectorAll("cds-table-cell");

        expect(cells).toHaveLength(4);
        cells.forEach(cell => {
            expect(cell.textContent).toBe("");
            expect(cell.children).toHaveLength(1);
            expect(cell.firstElementChild.className).toBe("cds--skeleton__text");
        });
    });

    it("leaves the rendered table untouched", () => {
        const { container, output } = mountOutput();

        snapshotTable(container);

        expect(output.querySelector("cds-table-cell").textContent).toBe("a0");
        expect(output.querySelector("cds-table").classList
            .contains("carbon-table-output__skeleton")).toBe(false);
    });

    it("strips ids so the copy doesn't duplicate them", () => {
        const { container, output } = mountOutput();
        output.querySelector("cds-table").id = "my-table";
        output.querySelector("cds-table-cell").id = "first-cell";

        snapshotTable(container);

        expect(skeletonOf(container).querySelectorAll("[id]")).toHaveLength(0);
        expect(skeletonOf(container).id).toBe("");
    });

    it("keeps the initial skeleton when nothing has rendered yet", () => {
        const { container, output } = mountOutput();
        output.replaceChildren();
        const before = skeletonOf(container);

        snapshotTable(container);

        expect(skeletonOf(container)).toBe(before);
    });
});

describe("setTableLoading", () => {
    it("toggles the loading class on the container", () => {
        const { container } = mountOutput();

        setTableLoading(container, false);
        expect(isLoading(container)).toBe(false);

        setTableLoading(container, true);
        expect(isLoading(container)).toBe(true);
    });
});

describe("Shiny output events", () => {
    let container;
    let output;

    beforeEach(() => {
        ({ container, output } = mountOutput({ size: "lg", rows: 4 }));
        setTableLoading(container, false);
    });

    it("shiny:recalculating snapshots the table and shows the skeleton", () => {
        $(output).trigger("shiny:recalculating");

        expect(isLoading(container)).toBe(true);
        expect(skeletonOf(container).getAttribute("size")).toBe("lg");
        expect(skeletonOf(container).querySelectorAll("cds-table-row"))
            .toHaveLength(4);
    });

    it("shiny:value hides the skeleton", () => {
        $(output).trigger("shiny:recalculating");
        $(output).trigger("shiny:value");

        expect(isLoading(container)).toBe(false);
    });

    it("shiny:error hides the skeleton so the error shows", () => {
        $(output).trigger("shiny:recalculating");
        $(output).trigger({ type: "shiny:error", error: { type: ["simpleError"] } });

        expect(isLoading(container)).toBe(false);
    });

    it("a silent error (req()) keeps the skeleton up", () => {
        $(output).trigger("shiny:recalculating");
        $(output).trigger({
            type: "shiny:error",
            error: { type: ["shiny.silent.error", "validation"] }
        });

        expect(isLoading(container)).toBe(true);
    });

    it("ignores events from other outputs", () => {
        document.body.insertAdjacentHTML(
            "beforeend",
            `<div id="other" class="shiny-html-output"></div>`
        );

        $("#other").trigger("shiny:recalculating");

        expect(isLoading(container)).toBe(false);
    });
});
