import { describe, it, expect, vi, beforeAll, afterEach } from "vitest";

let page;

beforeAll(async () => {
    page = await import("../carbon-page.js");
});

afterEach(() => {
    delete globalThis.Shiny.setInputValue;
    history.replaceState(null, "", "#");
});

function mountApp({ defaultRoute, panels = [] } = {}) {
    document.body.innerHTML = `
        <div id="carbon-app"${defaultRoute ? ` data-default-route="${defaultRoute}"` : ""}>
            <main>${panels.map(id => `<div id="${id}" class="carbon-panel"></div>`).join("")}</main>
        </div>`;
}

const active = () => [...document.querySelectorAll(".carbon-panel.active")].map(el => el.id);

describe("carbon_page routing", () => {
    it("does nothing on pages that aren't a carbon_page()", () => {
        document.body.innerHTML = `<div class="carbon-panel" id="a"></div>`;
        globalThis.Shiny.setInputValue = vi.fn();

        expect(page.getDefaultRoute()).toBeNull();
        expect(() => page.navigate("a")).not.toThrow();
        expect(globalThis.Shiny.setInputValue).not.toHaveBeenCalled();
        expect(active()).toEqual([]);
    });

    it("copes with a carbon_page() that has no panels", () => {
        mountApp();
        globalThis.Shiny.setInputValue = vi.fn();

        expect(page.getCurrentRoute()).toBeNull();
        expect(() => page.navigate(page.getCurrentRoute())).not.toThrow();
        expect(globalThis.Shiny.setInputValue).toHaveBeenCalledWith("carbon_page", null, { priority: "event" });
    });

    it("uses the default route when the URL has no hash", () => {
        mountApp({ defaultRoute: "b", panels: ["a", "b"] });

        expect(page.getCurrentRoute()).toBe("b");
    });

    it("prefers the URL hash", () => {
        mountApp({ defaultRoute: "a", panels: ["a", "b"] });
        history.replaceState(null, "", "#b");

        expect(page.getCurrentRoute()).toBe("b");
    });

    it("shows only the routed panel and reports the route", () => {
        mountApp({ defaultRoute: "a", panels: ["a", "b"] });
        globalThis.Shiny.setInputValue = vi.fn();

        page.navigate("a");
        page.navigate("b");

        expect(active()).toEqual(["b"]);
        expect(globalThis.Shiny.setInputValue).toHaveBeenLastCalledWith("carbon_page", "b", { priority: "event" });
    });
});
