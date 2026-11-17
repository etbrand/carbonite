import { describe, it, expect, vi, beforeAll, beforeEach, afterEach } from "vitest";

let STACK_CLASS, collectToasts;

beforeAll(async () => {
    ({ STACK_CLASS, collectToasts } = await import("../notifications.js"));
});

const toast = id => `<cds-toast-notification id="${id}" class="carbonite-toast"></cds-toast-notification>`;
const stack = () => document.querySelector(`.${STACK_CLASS}`);
const stackIds = () => [...(stack()?.children ?? [])].map(el => el.id);
const closed = el => el.dispatchEvent(
    new CustomEvent("cds-notification-closed", { bubbles: true, composed: true })
);
// MutationObserver callbacks run as microtasks
const settle = () => new Promise(resolve => setTimeout(resolve));

describe("toast notifications", () => {
    beforeEach(() => {
        document.body.innerHTML = "";
        Shiny.unbindAll = vi.fn();
    });

    afterEach(() => {
        delete Shiny.unbindAll;
    });

    it("moves toasts inserted into <body> into a stack, in order", async () => {
        document.body.insertAdjacentHTML("beforeend", toast("a"));
        await settle();
        document.body.insertAdjacentHTML("beforeend", toast("b"));
        await settle();

        expect(stackIds()).toEqual(["a", "b"]);
        expect(document.querySelectorAll(`.${STACK_CLASS}`)).toHaveLength(1);
        expect(document.querySelector("body > cds-toast-notification")).toBeNull();
    });

    it("collects toasts that arrived before it ran", () => {
        document.body.innerHTML = toast("early");

        collectToasts();

        expect(stackIds()).toEqual(["early"]);
    });

    it("leaves other elements in <body> alone", async () => {
        document.body.insertAdjacentHTML("beforeend", `<div id="x"></div><cds-toast-notification id="plain"></cds-toast-notification>`);
        await settle();

        expect(document.querySelector("body > #x")).not.toBeNull();
        expect(document.querySelector("body > #plain")).not.toBeNull();
        expect(stack()).toBeNull();
    });

    it("removes a toast once it closes, unbinding anything inside", async () => {
        document.body.insertAdjacentHTML("beforeend", toast("a") + toast("b"));
        await settle();
        const a = document.getElementById("a");

        closed(a);

        expect(Shiny.unbindAll).toHaveBeenCalledWith(a);
        expect(stackIds()).toEqual(["b"]);
    });

    it("leaves closed inline notifications in place", () => {
        document.body.innerHTML = `<cds-inline-notification id="inline"></cds-inline-notification>`;

        closed(document.getElementById("inline"));

        expect(document.getElementById("inline")).not.toBeNull();
        expect(Shiny.unbindAll).not.toHaveBeenCalled();
    });
});
