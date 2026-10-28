document.addEventListener("click", (e) => {
    const btn = e.target.closest("cds-button");

    if (!btn || !btn.id) return;

    Shiny.setInputValue(
        btn.id,
        Date.now(),
        { priority: "event" }
    );
});

document.addEventListener('cds-select-selected', (event) => {
    Shiny.setInputValue(
        event.target.id,
        event.detail.value,
        { priority: "event" }
    );
});

document.addEventListener('input', (event) => {
    const textInput = event.target.closest("cds-text-input");
    if (!textInput) {
        return;
    }
    Shiny.setInputValue(
        textInput.id,
        textInput.value,
        { priority: "event" }
    );
});

document.addEventListener('cds-checkbox-changed', (event) => {

    const checkbox = event.target;
    const group = checkbox.closest("cds-checkbox-group");

    if (!group || !group.id) return;

    const selected = Array.from(
        group.querySelectorAll("cds-checkbox")
    )
        .filter(cb => cb.checked)
        .map(cb => cb.value);

    Shiny.setInputValue(
        group.id,
        selected,
        { priority: "event" }
    );
});

document.addEventListener('cds-number-input', (event) => {
    const value = parseFloat(event.target.value);
    Shiny.setInputValue(
        event.target.id,
        Number.isNaN(value) ? null : value,
        { priority: "event" }
    );
});

document.addEventListener('cds-radio-button-group-changed', (event) => {
    Shiny.setInputValue(
        event.target.id,
        event.target.value,
        { priority: "event" }
    );
});

// Updaters

Shiny.addCustomMessageHandler(
    "carbon-update-text-input",
    (message) => {

        const el =
            document.getElementById(message.id);

        if (!el) return;

        if (message.value !== undefined) {
            el.value = message.value;
        }

    }
);

function rebuildChoices(el, message) {
    console.log(el.tagName);

    if (["CDS-RADIO-BUTTON-GROUP", "CDS-CHECKBOX-GROUP"].includes(el.tagName)) {
        el.replaceChildren();
        const itemTag = el.tagName.replace(/-GROUP$/, "").toLowerCase();
        Object.entries(message.choices).forEach(
            ([label, value]) => {
                const item = document.createElement(itemTag);
                item.id = `${el.id}__${value}`;
                item.value = value;
                item.labelText = label;
                if (itemTag === "cds-radio-button") {
                    item.name = el.id;
                }
                if (message.value.includes(value)) {
                    item.checked = true;
                }
                el.appendChild(item);
            })
        return;
    }

    const itemTag = el.tagName + "-ITEM";

    el.querySelectorAll(itemTag).forEach(item => item.remove());

    Object.entries(message.choices).forEach(
        ([label, value]) => {

            const item = document.createElement(itemTag);

            item.value = value;
            item.textContent = label;

            el.appendChild(item);
        });
}

Shiny.addCustomMessageHandler(
    "carbon-update",
    (message) => {

        const el =
            document.getElementById(message.id);

        if (!el) return;

        if (message.choices) {
            rebuildChoices(el, message);
        }

        Object.entries(message).forEach(
            ([key, value]) => {

                if (
                    key === "id" ||
                    key === "choices"
                ) {
                    return;
                }

                el[key] = value;
            }
        );
        Shiny.setInputValue(message.id, message.value);
    }
);
