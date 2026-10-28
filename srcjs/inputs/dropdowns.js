document.addEventListener('cds-dropdown-selected', (event) => {
    Shiny.setInputValue(
        event.target.id,
        event.target.value,
        { priority: "event" }
    );
});

document.addEventListener('cds-combo-box-selected', (event) => {
    Shiny.setInputValue(
        event.target.id,
        event.target.value,
        { priority: "event" }
    );
});

document.addEventListener('cds-multi-select-selected', (event) => {
    Shiny.setInputValue(
        event.target.id,
        event.target.value === "" ? [] : event.target.value.split(","),
        { priority: "event" }
    );
});
