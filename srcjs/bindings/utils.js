export function updateCarbonAttributes(el, data) {
    Object.entries(data).forEach(
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
}

// Shiny serialises length-1 R vectors as scalars, so a selected value may
// arrive as "a" or ["a", "b"]. Normalise to an array of strings so membership
// checks are exact matches rather than substring matches on a string.
export function toValueArray(value) {
    if (value === undefined || value === null) {
        return [];
    }

    return [].concat(value).map(String);
}

export function rebuildCarbonChoices(el, message) {

    if (["CDS-RADIO-BUTTON-GROUP", "CDS-CHECKBOX-GROUP"].includes(el.tagName)) {
        const selected = toValueArray(message.value);
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
                if (selected.includes(String(value))) {
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
