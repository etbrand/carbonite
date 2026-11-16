import { updateCarbonAttributes } from "./utils.js";
import { getAttributes, toSVG } from "@carbon/icon-helpers/es/index.js";
import { carbonIcons } from "../icons.js";

function setButtonIcon(el) {
    const iconName = el.dataset.icon;

    if (!iconName) return;

    const icon = carbonIcons[iconName];

    if (!icon) {
        console.warn(`Unknown Carbon icon: "${iconName}"`);
        return;
    }

    const svg = toSVG({
        ...icon,
        attrs: getAttributes(icon.attrs)
    });

    svg.setAttribute("slot", "icon");
    el.appendChild(svg);
}

// Replace the button's text without removing the slotted icon SVG
// (setting textContent would wipe every child node, icon included).
function setButtonLabel(el, label) {
    Array.from(el.childNodes)
        .filter(node => !(node.nodeType === Node.ELEMENT_NODE && node.getAttribute("slot") === "icon"))
        .forEach(node => node.remove());

    el.appendChild(document.createTextNode(label));
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
        const { label, ...attributes } = data;

        if (label !== undefined) {
            setButtonLabel(el, label);
        }

        updateCarbonAttributes(el, attributes);
    }
});

Shiny.inputBindings.register(carbonButtonBinding, "carbon.button");