function setTableLoading(output, loading) {
    const container = output.closest(".carbon-table-output");
    const skeleton = container?.querySelector("cds-table-skeleton");

    if (!skeleton) return;

    skeleton.shadowRoot
        ?.querySelectorAll("th")
        .forEach(th => {
            th.style.fontWeight = "600";
        });

    skeleton.showHeader = skeleton.dataset.showHeader === "true";
    skeleton.showToolbar = skeleton.dataset.showToolbar === "true";
    skeleton.headers = JSON.parse(skeleton.dataset.headers);

    output.style.display = loading ? "none" : "";
    skeleton.style.display = loading ? "block" : "none";
}

$(document).on("shiny:recalculating", (event) => {
    console.log("Recalculating");
    if (event.target.matches(".carbon-table-output__table")) {
        setTableLoading(event.target, true);
    }
});

$(document).on("shiny:value", (event) => {
    console.log("value");
    if (event.target.matches(".carbon-table-output__table")) {
        const output = event.target;
        setTableLoading(output, false);
        requestAnimationFrame(() => {
            syncTableSkeleton(output);
        });
    }
});

function syncTableSkeleton(output) {
    const container = output.closest(".carbon-table-output");
    const skeleton = container?.querySelector("cds-table-skeleton");
    const table = output.querySelector("cds-table");

    if (!skeleton || !table) return;

    const rows = table.querySelectorAll(
        "cds-table-body > cds-table-row"
    );

    const columns = table.querySelectorAll(
        "cds-table-header-cell"
    );

    const headerRow = table.querySelector(
        "cds-table-header-row"
    );

    skeleton.rowCount = rows.length;
    skeleton.columnCount = columns.length;
    skeleton.showHeader = table.dataset.showHeader === "true";
    skeleton.showToolbar = table.dataset.showToolbar === "true";

    if (headerRow?.size) {
        skeleton.size = headerRow.size;
    }
}
