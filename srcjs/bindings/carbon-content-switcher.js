// carbon_content_switcher(): the value is the selected option's `value`.
//
// Carbon fires cds-content-switcher-selected when the user selects an
// option (click or arrow keys), and shows the option's panel by toggling
// `hidden` on the element its `target` names. Setting the switcher's `value`
// from code updates the options but fires no event, so receiveMessage()
// tells Shiny itself.
//
// Shiny doesn't render outputs it thinks are hidden. Recent Shiny notices
// panels being shown by itself; older versions only re-check on jQuery
// "shown"/"hidden" events, so send those too (as for accordions).

import { toValueArray } from "./utils.js";

const SELECTED_EVENT = "cds-content-switcher-selected";

function items(el) {
    return [...el.querySelectorAll(":scope > cds-content-switcher-item")];
}

function isOn(item, property) {
    return typeof item[property] === "boolean" ? item[property] : item.hasAttribute(property);
}

function panelOf(item) {
    const target = item.getAttribute("target");
    return target ? document.getElementById(target) : null;
}

export function notifyPanels(el) {
    const send = () => items(el).forEach(item => {
        const panel = panelOf(item);
        if (panel) $(panel).trigger(panel.hidden ? "hidden" : "shown");
    });

    // Carbon toggles `hidden` as the options re-render
    Promise.all(items(el).map(item => item.updateComplete ?? Promise.resolve())).then(send);
}

// Select the option with this value, as Carbon does for a user's choice,
// minus the focus change. Returns whether anything changed.
export function selectValue(el, value) {
    const all = items(el);
    const index = all.findIndex(item => item.getAttribute("value") === value);
    const item = all[index];
    if (!item || isOn(item, "disabled") || isOn(item, "selected")) return false;

    el.value = value;
    all.forEach((other, i) => {
        const on = other === item;
        other.selected = on;
        other.toggleAttribute("selected", on);
        // Carbon hides the divider right after the selected option
        other.hideDivider = i === index + 1;

        const panel = panelOf(other);
        if (panel) panel.hidden = !on;
    });

    return true;
}

const carbonContentSwitcherBinding = new Shiny.InputBinding();

$.extend(carbonContentSwitcherBinding, {
    find(scope) {
        return $(scope).find("cds-content-switcher[id]");
    },

    getValue(el) {
        const selected = items(el).find(item => isOn(item, "selected"));
        // Before Carbon upgrades the element, `value` is only an attribute
        return selected?.getAttribute("value") ?? ((el.value ?? el.getAttribute("value")) || null);
    },

    subscribe(el, callback) {
        el._carbonInputHandler = () => {
            notifyPanels(el);
            callback(false);
        };
        el.addEventListener(SELECTED_EVENT, el._carbonInputHandler);
    },

    unsubscribe(el) {
        el.removeEventListener(SELECTED_EVENT, el._carbonInputHandler);
        delete el._carbonInputHandler;
    },

    receiveMessage(el, data) {
        const value = toValueArray(data.value)[0];
        if (value !== undefined && selectValue(el, value)) {
            el._carbonInputHandler?.();
        }
    }
});

Shiny.inputBindings.register(carbonContentSwitcherBinding, "carbon.contentSwitcher");
