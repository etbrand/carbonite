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

export function rebuildCarbonChoices(el, message) {

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
