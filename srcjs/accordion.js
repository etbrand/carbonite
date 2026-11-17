// Tell Shiny when an accordion item opens or closes.
//
// Closed items hide their content (see the accordion rule in carbonite.scss),
// and Shiny doesn't render outputs it thinks are hidden. Recent Shiny (1.14)
// notices visibility changes by itself, since it observes each output, but
// older versions only re-check on jQuery "shown"/"hidden" events, as
// Bootstrap tabs and collapses send.

export function notifyShiny(item) {
    const send = () => $(item).trigger(item.open ? "shown" : "hidden");

    // Carbon re-renders (showing the content) after `open` changes, so wait
    // for that; otherwise Shiny would still see the content as hidden.
    if (item.updateComplete?.then) {
        item.updateComplete.then(send);
    } else {
        send();
    }
}

document.addEventListener("cds-accordion-item-toggled", event => {
    if (event.target?.matches?.("cds-accordion-item")) {
        notifyShiny(event.target);
    }
});

// Carbon bug: when `cds-accordion`'s own `disabled` is set (including its
// initial `false`), it copies it onto every item, so `disabled` on an
// individual item is removed on the first render. Keep item-level
// `disabled` unless the whole accordion is being disabled. (`updated()` is
// patchable because Lit calls it as an ordinary method; lifecycle callbacks
// like connectedCallback are fixed when the element is defined.)
export function patchAccordion(Accordion) {
    if (Accordion.prototype._carbonitePatched) return;

    const { updated } = Accordion.prototype;

    Accordion.prototype.updated = function (changedProperties) {
        const keep = !this.disabled && changedProperties?.has("disabled")
            ? [...this.querySelectorAll(":scope > cds-accordion-item[disabled]")]
            : [];

        updated?.call(this, changedProperties);
        keep.forEach(item => item.setAttribute("disabled", ""));
    };
    Accordion.prototype._carbonitePatched = true;
}

// Patch synchronously when possible: Carbon's module (imported first in
// carbonite.js) has already defined the element, and its first render is
// queued as a microtask, which would run before a `whenDefined().then()`.
const Accordion = customElements.get("cds-accordion");
if (Accordion) {
    patchAccordion(Accordion);
} else {
    customElements.whenDefined("cds-accordion")
        .then(() => patchAccordion(customElements.get("cds-accordion")));
}
