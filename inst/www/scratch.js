// function notifyIfChanged(el, oldValue, newValue) {
//     const changed = Array.isArray(oldValue) && Array.isArray(newValue)
//         ? oldValue.length !== newValue.length ||
//         oldValue.some((value, i) => value !== newValue[i])
//         : oldValue !== newValue;

//     if (changed) {
//         el._carbonInputHandler?.();
//     }
// }

function updateCarbonAttributes(el, data) {
    Object.entries(data).forEach(
        ([key, value]) => {

            if (key === "choices") {
                return;
            }

            // if (key === "value" && Array.isArray(value)) {
            //     Array.from(el.children).forEach(item => {
            //         const selected = value.includes(item.value);

            //         if ("selected" in item) {
            //             item.selected = selected;
            //         }

            //         if ("checked" in item) {
            //             item.checked = selected;
            //         }
            //     });

            //     return;

            // }

            el[key] = value;
        }
    );
}

function rebuildCarbonChoices(el, message) {

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
// const carbonNumberInputBinding = new Shiny.InputBinding();

// $.extend(carbonNumberInputBinding, {
//     find(scope) {
//         return $(scope).find("cds-number-input[id]");
//     },

//     getValue(el) {
//         if (el.value === "" || el.value == null) {
//             return null;
//         }

//         const value = Number(el.value);

//         return Number.isNaN(value) ? null : value;
//     },

//     subscribe(el, callback) {
//         el._carbonInputHandler = () => {
//             callback(false);
//         };

//         el.addEventListener("cds-number-input", el._carbonInputHandler);
//     },

//     unsubscribe(el) {
//         el.removeEventListener("cds-number-input", el._carbonInputHandler);
//         delete el._carbonInputHandler;
//     },

//     receiveMessage(el, data) {
//         updateCarbonAttributes(el, data);

//         if (data.value !== undefined) {
//             el._carbonInputHandler?.();
//         }
//     }
// });

// Shiny.inputBindings.register(
//     carbonNumberInputBinding,
//     "carbon.numberInput"
// );

// const carbonCheckboxGroupBinding = new Shiny.InputBinding();

// $.extend(carbonCheckboxGroupBinding, {
//     find(scope) {
//         return $(scope).find("cds-checkbox-group[id]");
//     },

//     getValue(el) {
//         return Array.from(
//             el.querySelectorAll("cds-checkbox")
//         )
//             .filter(checkbox => checkbox.checked)
//             .map(checkbox => checkbox.value);
//     },

//     subscribe(el, callback) {
//         el._carbonInputHandler = () => {
//             callback(false);
//         };

//         el.addEventListener(
//             "cds-checkbox-changed",
//             el._carbonInputHandler
//         );
//     },

//     unsubscribe(el) {
//         el.removeEventListener(
//             "cds-checkbox-changed",
//             el._carbonInputHandler
//         );

//         delete el._carbonInputHandler;
//     },

//     receiveMessage(el, data) {
//         if (data.choices !== undefined) {
//             rebuildCarbonChoices(el, data);
//         }

//         updateCarbonAttributes(el, data);

//         if (data.choices !== undefined || data.value !== undefined) {
//             el._carbonInputHandler?.();
//         }
//     }
// });

// Shiny.inputBindings.register(
//     carbonCheckboxGroupBinding,
//     "carbon.checkboxGroup"
// );

// function resolveCarbonValue(data, currentValue, fallbackValue = null) {
//     if (
//         data.choices === undefined ||
//         data.value !== undefined
//     ) {
//         return data;
//     }

//     const availableValues = Object.keys(data.choices);

//     let value;

//     if (currentValue === "" || currentValue == null) {
//         value = currentValue;
//     } else if (availableValues.includes(currentValue)) {
//         value = currentValue;
//     } else {
//         value = availableValues[0] ?? fallbackValue;
//     }

//     return {
//         ...data,
//         value
//     };
// }

// const carbonSelectBinding = new Shiny.InputBinding();

// $.extend(carbonSelectBinding, {
//     find(scope) {
//         return $(scope).find("cds-select[id]");
//     },

//     getValue(el) {
//         return el.value ?? null;
//     },

//     subscribe(el, callback) {
//         el._carbonInputHandler = () => {
//             callback(false);
//         };

//         el.addEventListener(
//             "cds-select-selected",
//             el._carbonInputHandler
//         );
//     },

//     unsubscribe(el) {
//         el.removeEventListener(
//             "cds-select-selected",
//             el._carbonInputHandler
//         );

//         delete el._carbonInputHandler;
//     },

//     receiveMessage(el, data) {

//         const oldValue = this.getValue(el);

//         if (data.choices !== undefined) {
//             rebuildCarbonChoices(el, data);
//         }

//         updateCarbonAttributes(el, data);

//         const newValue = this.getValue(el);
//         //if (data.value !== undefined) {
//         el._carbonInputHandler?.();
//         //}
//         // notifyIfChanged(el, oldValue, newValue);

//     }
// });

// Shiny.inputBindings.register(
//     carbonSelectBinding,
//     "carbon.select"
// );

// import {
//     rebuildCarbonChoices,
//     updateCarbonAttributes
// } from "./utils.js";

// const carbonDropdownBinding = new Shiny.InputBinding();

// $.extend(carbonDropdownBinding, {
//     find(scope) {
//         return $(scope).find("cds-dropdown[id]");
//     },

//     getValue(el) {
//         return el.value ?? null;
//     },

//     subscribe(el, callback) {
//         el._carbonInputHandler = () => {
//             callback(false);
//         };

//         el.addEventListener("cds-dropdown-selected", el._carbonInputHandler);
//     },

//     unsubscribe(el) {
//         el.removeEventListener("cds-dropdown-selected", el._carbonInputHandler);
//         delete el._carbonInputHandler;
//     },

//     receiveMessage(el, data) {
//         if (data.choices !== undefined) {
//             rebuildCarbonChoices(el, data);
//         }

//         updateCarbonAttributes(el, data);
//         el._carbonInputHandler?.();
//     }
// });

// Shiny.inputBindings.register(
//     carbonDropdownBinding,
//     "carbon.dropdown"
// );


// import {
//   rebuildCarbonChoices,
//   updateCarbonAttributes
// } from "./utils.js";

// const carbonComboBoxBinding = new Shiny.InputBinding();

// $.extend(carbonComboBoxBinding, {
//     find(scope) {
//         return $(scope).find("cds-combo-box[id]");
//     },

//     getValue(el) {
//         return el.value ?? null;
//     },

//     subscribe(el, callback) {
//         el._carbonInputHandler = () => {
//             callback(false);
//         };

//         el.addEventListener("cds-combo-box-selected", el._carbonInputHandler);
//     },

//     unsubscribe(el) {
//         el.removeEventListener("cds-combo-box-selected", el._carbonInputHandler);
//         delete el._carbonInputHandler;
//     },

//     receiveMessage(el, data) {
//         if (data.choices !== undefined) {
//             rebuildCarbonChoices(el, data);
//         }

//         updateCarbonAttributes(el, data);
//         el._carbonInputHandler?.();
//     }
// });

// Shiny.inputBindings.register(carbonComboBoxBinding, "carbon.comboBox");

// import {
//     rebuildCarbonChoices,
//     updateCarbonAttributes
// } from "./utils.js";

// const carbonMultiSelectBinding = new Shiny.InputBinding();

// $.extend(carbonMultiSelectBinding, {
//     find(scope) {
//         const elements = $(scope).find("cds-multi-select[id]");

//         elements.each((_, el) => {
//             if (el.dataset.sort === "false") {
//                 el.sortItems = items => [...items];
//             }
//         });

//         return elements;
//     },

//     getValue(el) {
//         console.log("getValue called");
//         console.log("el.value:", el.value);
//         console.log("typeof:", typeof el.value);
//         return el.value ? el.value.split(",").sort() : [];
//     },

//     subscribe(el, callback) {
//         el._carbonInputHandler = () => {
//             console.log("multiselect event fired");
//             console.log("value before callback:", el.value);
//             callback(false);
//         };

//         el.addEventListener("cds-multi-select-selected", el._carbonInputHandler);
//     },

//     unsubscribe(el) {
//         el.removeEventListener("cds-multi-select-selected", el._carbonInputHandler);
//         delete el._carbonInputHandler;
//     },

//     receiveMessage(el, data) {
//         if (data.choices !== undefined) {
//             rebuildCarbonChoices(el, data);
//         }

//         updateCarbonAttributes(el, data);
//         el._carbonInputHandler?.();
//     }
// });

// Shiny.inputBindings.register(carbonMultiSelectBinding, "carbon.multiSelect");

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
