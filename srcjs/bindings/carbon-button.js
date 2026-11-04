import { updateCarbonAttributes } from "./utils.js";
import { getAttributes, toSVG } from "@carbon/icon-helpers/es/index.js";
import { carbonIcons } from "../icons.js";

function setButtonIcon(el) {
    const iconName = el.dataset.icon;
    console.log("icon name:", iconName);

    if (!iconName) return;

    const icon = carbonIcons[iconName];
    console.log("icon definition:", icon);

    if (!icon) {
        console.warn(`Unknown Carbon icon: "${iconName}"`);
        return;
    }

    const svg = toSVG({
        ...icon,
        attrs: getAttributes(icon.attrs)
    });

    console.log("generated svg:", svg);

    svg.setAttribute("slot", "icon");
    el.appendChild(svg);
}

const carbonButtonBinding = new Shiny.InputBinding();

$.extend(carbonButtonBinding, {

    find(scope) {
        return $(scope).find("cds-button[id]");
    },

    initialize(el) {
        setButtonIcon(el);
    },

    getValue(el) {
        return Number(el.dataset.clickCount ?? 0);
    },

    subscribe(el, callback) {
        el._carbonClickHandler = () => {
            const value = Number(el.dataset.clickCount ?? 0);

            el.dataset.clickCount = value + 1;

            callback(true);
        };

        el.addEventListener("click", el._carbonClickHandler);
    },

    unsubscribe(el) {
        el.removeEventListener("click", el._carbonClickHandler);
        delete el._carbonClickHandler;
    },

    receiveMessage(el, data) {
        updateCarbonAttributes(el, data);
    }
});

Shiny.inputBindings.register(carbonButtonBinding, "carbon.button");