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

describe("carbon_page initial route", () => {
    it("reports the starting route once Shiny connects", () => {
        mountApp({ defaultRoute: "a", panels: ["a", "b"] });
        history.replaceState(null, "", "#b");
        globalThis.Shiny.setInputValue = vi.fn();

        // Shiny triggers this with jQuery, not as a native DOM event
        jQuery(document).trigger("shiny:connected");

        expect(globalThis.Shiny.setInputValue).toHaveBeenCalledWith("carbon_page", "b", { priority: "event" });
    });

    it("reports the default route when the URL has no hash", () => {
        mountApp({ defaultRoute: "a", panels: ["a", "b"] });
        globalThis.Shiny.setInputValue = vi.fn();

        jQuery(document).trigger("shiny:connected");

        expect(globalThis.Shiny.setInputValue).toHaveBeenCalledWith("carbon_page", "a", { priority: "event" });
    });

    it("does nothing on pages that aren't a carbon_page()", () => {
        document.body.innerHTML = "";
        globalThis.Shiny.setInputValue = vi.fn();

        jQuery(document).trigger("shiny:connected");

        expect(globalThis.Shiny.setInputValue).not.toHaveBeenCalled();
    });
});

describe("carbon_page nav links", () => {
    function mountNav() {
        mountApp({ defaultRoute: "a", panels: ["a", "b"] });
        const link = document.createElement("a");
        link.href = "#b";
        link.dataset.carbonNav = "";
        link.dataset.route = "b";
        link.textContent = "B";
        document.getElementById("carbon-app").prepend(link);
        return link;
    }

    it("routes without assigning location.hash, which would scroll to the panel", () => {
        const link = mountNav();
        globalThis.Shiny.setInputValue = vi.fn();
        const pushState = vi.spyOn(history, "pushState");
        const scrollTo = vi.spyOn(window, "scrollTo").mockImplementation(() => {});

        link.click();

        expect(pushState).toHaveBeenCalledWith(null, "", "#b");
        expect(window.location.hash).toBe("#b");
        expect(active()).toEqual(["b"]);
        expect(globalThis.Shiny.setInputValue).toHaveBeenLastCalledWith("carbon_page", "b", { priority: "event" });
        expect(scrollTo).toHaveBeenCalledWith(0, 0);

        pushState.mockRestore();
        scrollTo.mockRestore();
    });

    it("doesn't add a history entry when the route is already current", () => {
        const link = mountNav();
        history.replaceState(null, "", "#b");
        const pushState = vi.spyOn(history, "pushState");
        vi.spyOn(window, "scrollTo").mockImplementation(() => {});

        link.click();

        expect(pushState).not.toHaveBeenCalled();
        expect(active()).toEqual(["b"]);
        vi.restoreAllMocks();
    });

    it("scrolls to the top when the hash changes another way", () => {
        mountApp({ defaultRoute: "a", panels: ["a", "b"] });
        const scrollTo = vi.spyOn(window, "scrollTo").mockImplementation(() => {});
        history.replaceState(null, "", "#b");

        window.dispatchEvent(new HashChangeEvent("hashchange"));

        expect(active()).toEqual(["b"]);
        expect(scrollTo).toHaveBeenCalledWith(0, 0);
        scrollTo.mockRestore();
    });
});
