// Inputs for the interactive tag variants. update_carbon_tag() sends Carbon
// property names (`text`, `type`, `selected`, `disabled`), which apply to
// all three.
//
// * carbon_selectable_tag(): TRUE/FALSE. Carbon toggles `selected` on click
//   (or Enter/Space) and then fires cds-selectable-tag-selected.
// * carbon_dismissible_tag(): NULL until dismissed, then TRUE. Carbon hides
//   the tag (`open` = false) and fires cds-dismissible-tag-closed.
// * carbon_operational_tag(): a click count, like an action button. Carbon
//   would toggle a `selected`/`aria-pressed` state on each click, which
//   operational tags don't have (Carbon gives it no style), so the toggle is
//   cancelled through its cancelable "beingselected" event, which is also
//   where the click is counted.

import { updateCarbonAttributes } from "./utils.js";

function isOn(el, property) {
    return typeof el[property] === "boolean" ? el[property] : el.hasAttribute(property);
}

function register(name, binding) {
    Shiny.inputBindings.register($.extend(new Shiny.InputBinding(), binding), name);
}

register("carbon.selectableTag", {
    find(scope) {
        return $(scope).find("cds-selectable-tag[id]");
    },

    getValue(el) {
        return isOn(el, "selected");
    },

    subscribe(el, callback) {
        el._carbonTagHandler = () => callback(false);
        el.addEventListener("cds-selectable-tag-selected", el._carbonTagHandler);
    },

    unsubscribe(el) {
        el.removeEventListener("cds-selectable-tag-selected", el._carbonTagHandler);
        delete el._carbonTagHandler;
    },

    // Setting `selected` fires no event, so tell Shiny when it changes.
    receiveMessage(el, data) {
        const before = this.getValue(el);
        updateCarbonAttributes(el, data);
        el.toggleAttribute("selected", this.getValue(el));
        if (this.getValue(el) !== before) el._carbonTagHandler?.();
    }
});

register("carbon.dismissibleTag", {
    find(scope) {
        return $(scope).find("cds-dismissible-tag[id]");
    },

    getValue(el) {
        const open = typeof el.open === "boolean" ? el.open : el.getAttribute("open") !== "false";
        return open ? null : true;
    },

    subscribe(el, callback) {
        el._carbonTagHandler = () => callback(false);
        el.addEventListener("cds-dismissible-tag-closed", el._carbonTagHandler);
    },

    unsubscribe(el) {
        el.removeEventListener("cds-dismissible-tag-closed", el._carbonTagHandler);
        delete el._carbonTagHandler;
    },

    receiveMessage(el, data) {
        updateCarbonAttributes(el, data);
    }
});

register("carbon.operationalTag", {
    find(scope) {
        return $(scope).find("cds-operational-tag[id]");
    },

    getValue(el) {
        return Number(el.dataset.clickCount ?? 0);
    },

    // Like shiny::actionButton(): 0 clicks counts as "not clicked".
    getType() {
        return "shiny.action";
    },

    subscribe(el, callback) {
        el._carbonTagHandler = event => {
            event.preventDefault();
            el.dataset.clickCount = this.getValue(el) + 1;
            callback(false);
        };
        el.addEventListener("cds-operational-tag-beingselected", el._carbonTagHandler);
    },

    unsubscribe(el) {
        el.removeEventListener("cds-operational-tag-beingselected", el._carbonTagHandler);
        delete el._carbonTagHandler;
    },

    receiveMessage(el, data) {
        updateCarbonAttributes(el, data);
    }
});
