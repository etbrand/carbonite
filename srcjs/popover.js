// carbon_popover(): Carbon's popover closes itself (outside click, Escape,
// tabbing away) but leaves opening it to the app, so a click on the
// trigger (the popover's first child) toggles it here.
//
// `caret` and `dropShadow` default to true and boolean attributes can't
// turn them off, so carbon_popover() marks them with `data-caret="false"` /
// `data-drop-shadow="false"` and they're set as properties before the
// popover first opens.

const POPOVER = "cds-popover.carbonite-popover";
export const TOGGLED_EVENT = "carbonite:popover-toggled";

export function applyOptions(popover) {
    if (popover.dataset.caret === "false") popover.caret = false;
    if (popover.dataset.dropShadow === "false") popover.dropShadow = false;
}

function isOpen(popover) {
    return typeof popover.open === "boolean" ? popover.open : popover.hasAttribute("open");
}

// Open or close; returns whether it changed. Fires TOGGLED_EVENT for the
// input binding (Carbon only fires an event when it closes the popover).
export function setOpen(popover, open) {
    if (isOpen(popover) === open) return false;

    applyOptions(popover);
    popover.open = open;
    popover.toggleAttribute("open", open);
    popover.dispatchEvent(new CustomEvent(TOGGLED_EVENT, { bubbles: true }));
    return true;
}

// The trigger: the popover's first child that isn't its content
export function triggerOf(popover) {
    return [...popover.children].find(child => child.getAttribute("slot") !== "content") ?? null;
}

document.addEventListener("click", event => {
    const path = event.composedPath();
    const popover = path.find(node => node instanceof Element && node.matches(POPOVER));
    if (!popover) return;

    const trigger = triggerOf(popover);
    if (trigger && path.includes(trigger)) setOpen(popover, !isOpen(popover));
});

// Popovers that start open
function applyAll() {
    document.querySelectorAll(POPOVER).forEach(applyOptions);
}

if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", applyAll);
} else {
    applyAll();
}
