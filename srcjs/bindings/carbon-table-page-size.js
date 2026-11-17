// Rows per page for carbon_table(page_size = ).
//
// The input is named `<table id>_page_size`, like the selection input
// (carbon-table-selection.js): inside render_carbon_table() the table has no
// id of its own, so the enclosing output's id is used. Its value is the
// pagination's current page size, reported when the table renders and
// whenever the user picks another size. Apps pass it back as
// carbon_table(page_size = shiny::isolate(input$<id>_page_size)) so a
// re-render keeps the user's choice.
//
// The binding is on the table's `cds-pagination`, which carbon_table()
// creates without an id; find() gives it the input id.

const WRAPPER = ".carbonite-paginated-table";
// The carbon_table_output() loading skeleton copies the pagination bar; the
// copy must never be bound.
const SKELETON = ".carbon-table-output__skeleton";

export function pageSizeInputId(pagination) {
    const wrapper = pagination.closest(WRAPPER);
    const table = wrapper?.querySelector(":scope > cds-table");
    const base = table?.id || wrapper?.closest(".shiny-html-output")?.id;
    return base ? `${base}_page_size` : null;
}

export function pageSizeOf(pagination) {
    const value = Number(pagination.pageSize ?? pagination.getAttribute("page-size"));
    return Number.isFinite(value) && value > 0 ? value : null;
}

const carbonTablePageSizeBinding = new Shiny.InputBinding();

$.extend(carbonTablePageSizeBinding, {
    find(scope) {
        return $(scope)
            .find(`${WRAPPER} > cds-pagination`)
            .filter((_, pagination) => {
                if (pagination.closest(SKELETON)) return false;
                if (!pagination.id) {
                    const id = pageSizeInputId(pagination);
                    if (!id) return false;
                    pagination.id = id;
                }
                return true;
            });
    },

    getId(pagination) {
        return pagination.id;
    },

    getValue(pagination) {
        return pageSizeOf(pagination);
    },

    subscribe(pagination, callback) {
        // Carbon has already updated `pageSize` when this fires; report a
        // microtask later anyway, after table-pagination.js has re-paged.
        pagination._carbonInputHandler = () => {
            Promise.resolve().then(() => callback(false));
        };
        pagination.addEventListener("cds-page-sizes-select-changed", pagination._carbonInputHandler);
    },

    unsubscribe(pagination) {
        pagination.removeEventListener("cds-page-sizes-select-changed", pagination._carbonInputHandler);
        delete pagination._carbonInputHandler;
    }
});

Shiny.inputBindings.register(carbonTablePageSizeBinding, "carbon.tablePageSize");
