import { describe, it, expect, vi, beforeAll, beforeEach, afterEach } from "vitest";

let REMOVE_DELAY;

beforeAll(async () => {
    ({ REMOVE_DELAY } = await import("../carbon-modal.js"));
});

// Carbon fires this on the cds-modal when the user closes it.
const closed = modal => modal.dispatchEvent(
    new CustomEvent("cds-modal-closed", { bubbles: true, composed: true })
);

describe("modal cleanup", () => {
    beforeEach(() => {
        vi.useFakeTimers();
        Shiny.unbindAll = vi.fn();
    });

    afterEach(() => {
        vi.useRealTimers();
        delete Shiny.unbindAll;
    });

    it("unbinds a shown modal's inputs on close, then removes it after the fade-out", () => {
        document.body.innerHTML = `<div class="carbon-modal-wrapper"><cds-modal open><cds-text-input id="name"></cds-text-input></cds-modal></div>`;
        const wrapper = document.querySelector(".carbon-modal-wrapper");

        closed(document.querySelector("cds-modal"));

        expect(Shiny.unbindAll).toHaveBeenCalledWith(wrapper);
        expect(wrapper.isConnected).toBe(true);

        vi.advanceTimersByTime(REMOVE_DELAY);
        expect(wrapper.isConnected).toBe(false);
    });

    it("leaves a modal shown since the close in place", () => {
        document.body.innerHTML = `<div class="carbon-modal-wrapper" id="old"><cds-modal></cds-modal></div>`;
        closed(document.querySelector("#old cds-modal"));

        document.body.insertAdjacentHTML("beforeend", `<div class="carbon-modal-wrapper" id="new"><cds-modal open></cds-modal></div>`);
        vi.advanceTimersByTime(REMOVE_DELAY);

        expect(document.getElementById("old")).toBeNull();
        expect(document.getElementById("new")).not.toBeNull();
    });

    it("ignores modals that weren't shown with show_carbon_modal()", () => {
        document.body.innerHTML = `<div id="page"><cds-modal></cds-modal></div>`;

        closed(document.querySelector("cds-modal"));
        vi.advanceTimersByTime(REMOVE_DELAY);

        expect(Shiny.unbindAll).not.toHaveBeenCalled();
        expect(document.querySelector("#page cds-modal")).not.toBeNull();
    });

    it("ignores the same event from other elements", () => {
        document.body.innerHTML = `<div class="carbon-modal-wrapper"><cds-text-input></cds-text-input></div>`;

        closed(document.querySelector("cds-text-input"));
        vi.advanceTimersByTime(REMOVE_DELAY);

        expect(document.querySelector(".carbon-modal-wrapper")).not.toBeNull();
    });
});
