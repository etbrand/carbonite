// carbon_popover(id = ): TRUE while the popover is open, FALSE otherwise.
//
// The popover opens and closes on its trigger (srcjs/popover.js, which
// fires `carbonite:popover-toggled`), and Carbon closes it on an outside
// click, Escape, or tabbing away (`cds-popover-closed`).
// update_carbon_popover() opens or closes it from the server.

import { setOpen, TOGGLED_EVENT } from "../popover.js";

const EVENTS = [TOGGLED_EVENT, "cds-popover-closed"];

const carbonPopoverBinding = new Shiny.InputBinding();

$.extend(carbonPopoverBinding, {
    find(scope) {
        return $(scope).find("cds-popover.carbonite-popover[id]");
    },

    getValue(el) {
        return typeof el.open === "boolean" ? el.open : el.hasAttribute("open");
    },

    subscribe(el, callback) {
        // Only this popover's events, not those of a popover inside it
        el._carbonInputHandler = event => {
            if (event.target === el) callback(false);
        };
        EVENTS.forEach(type => el.addEventListener(type, el._carbonInputHandler));
    },

    unsubscribe(el) {
        EVENTS.forEach(type => el.removeEventListener(type, el._carbonInputHandler));
        delete el._carbonInputHandler;
    },

    // setOpen() fires the toggled event, which reports the change
    receiveMessage(el, data) {
        if (typeof data.open === "boolean") setOpen(el, data.open);
    }
});

Shiny.inputBindings.register(carbonPopoverBinding, "carbon.popover");
