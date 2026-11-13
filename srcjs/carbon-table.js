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

    if (loading) {
        output.style.visibility = "hidden";
        output.style.position = "absolute";
        output.style.inset = "0";
        output.style.pointerEvents = "none";
    } else {
        output.style.visibility = "";
        output.style.position = "";
        output.style.inset = "";
        output.style.pointerEvents = "";
    }

    skeleton.style.display = loading ? "block" : "none";
}

$(document).on("shiny:recalculating", (event) => {
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
