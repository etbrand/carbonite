// Clean up a modal shown with show_carbon_modal() once the user closes it.
//
// show_carbon_modal() inserts the modal (already open) into the page inside
// a .carbon-modal-wrapper, with shiny::insertUI(). Carbon only hides a
// modal when the user closes it (close button, Escape, a
// [data-modal-close] button, or a click outside), so remove it here: unbind
// its inputs straight away and remove the markup once Carbon's 240ms
// fade-out has played. (Like removeUI(), this doesn't reset the inputs'
// values on the server.)
// remove_carbon_modal() removes the wrapper from the server instead.

export const REMOVE_DELAY = 300;

export function removeClosedModal(modal) {
    const wrapper = modal.closest?.(".carbon-modal-wrapper");
    if (!wrapper) return;

    window.Shiny?.unbindAll?.(wrapper);
    // The wrapper element itself, not a selector: the server may already
    // have shown another modal in a new wrapper.
    setTimeout(() => wrapper.remove(), REMOVE_DELAY);
}

document.addEventListener("cds-modal-closed", event => {
    if (event.target?.matches?.("cds-modal")) {
        removeClosedModal(event.target);
    }
});
