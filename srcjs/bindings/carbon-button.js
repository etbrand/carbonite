import { updateCarbonAttributes } from "./utils.js";

// Icons are rendered in R (carbon_icon()) as an <svg slot="icon"> child, so
// the binding only has to keep it in place.
function isIcon(node) {
    return node.nodeType === Node.ELEMENT_NODE && node.getAttribute("slot") === "icon";
}

// Replace (or with "" remove) the slotted icon with SVG markup from R.
function setButtonIcon(el, markup) {
    Array.from(el.childNodes).filter(isIcon).forEach(node => node.remove());

    if (!markup) return;

    const template = document.createElement("template");
    template.innerHTML = markup;
    const svg = template.content.firstElementChild;

    if (svg) {
        svg.setAttribute("slot", "icon");
        el.prepend(svg);
    }
}

// Replace the button's text without removing the slotted icon SVG
// (setting textContent would wipe every child node, icon included).
function setButtonLabel(el, label) {
    Array.from(el.childNodes)
        .filter(node => !isIcon(node))
        .forEach(node => node.remove());

    el.appendChild(document.createTextNode(label));
}

const carbonButtonBinding = new Shiny.InputBinding();

$.extend(carbonButtonBinding, {

    find(scope) {
        return $(scope).find("cds-button[id]");
    },

    getValue(el) {
        return Number(el.dataset.clickCount ?? 0);
    },

    // Like shiny::actionButton(): R then treats 0 clicks as "not clicked",
    // so observeEvent(input$btn, ...) doesn't fire on startup or when the
    // button is re-rendered (e.g. inside renderUI or a table toolbar).
    getType() {
        return "shiny.action";
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
        const { label, icon, ...attributes } = data;

        if (icon !== undefined) {
            setButtonIcon(el, icon);
        }

        if (label !== undefined) {
            setButtonLabel(el, label);
        }

        updateCarbonAttributes(el, attributes);
    }
});

Shiny.inputBindings.register(carbonButtonBinding, "carbon.button");
