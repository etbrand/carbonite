// Hash-based routing between carbon_panel()s in a carbon_page().
//
// This file is part of the bundle every component loads, so it must do
// nothing on pages that aren't a carbon_page() (no #carbon-app), and cope
// with a carbon_page() that has no panels (no default route).

function app() {
    return document.getElementById("carbon-app");
}

export function getDefaultRoute() {
    return app()?.dataset.defaultRoute || null;
}

export function getCurrentRoute() {
    const route = window.location.hash.substring(1);
    return route || getDefaultRoute();
}

export function showPanel(id) {
    document
        .querySelectorAll(".carbon-panel")
        .forEach(el => {
            el.classList.toggle("active", el.id === id);
        });
}

function reportRoute(route) {
    if (window.Shiny?.setInputValue) {
        Shiny.setInputValue("carbon_page", route, { priority: "event" });
    }
}

export function navigate(route) {
    if (!app()) return;

    showPanel(route);
    reportRoute(route);
}

// The first navigate() runs on DOMContentLoaded, before Shiny has connected
// (Shiny.setInputValue doesn't exist yet), so the server never heard the
// starting route. Report it again once connected. Shiny triggers this with
// jQuery, which addEventListener() listeners don't receive.
export function handleShinyConnected() {
    if (app()) reportRoute(getCurrentRoute());
}

window.jQuery?.(document).on("shiny:connected", handleShinyConnected);

// Each panel's id is its route, so the browser treats "#route" as an anchor
// and scrolls the panel to the top of the viewport, hiding the start of the
// page under the fixed header. Every route change starts at the top instead.
function scrollToTop() {
    window.scrollTo(0, 0);
}

document.addEventListener("DOMContentLoaded", () => {
    navigate(getCurrentRoute());
});

// Opening a link like /#about: undo the browser's jump to the panel
window.addEventListener("load", () => {
    if (app() && window.location.hash) scrollToTop();
});

// Back/forward or an edited URL: the browser has already jumped
window.addEventListener("hashchange", () => {
    if (!app()) return;
    navigate(getCurrentRoute());
    scrollToTop();
});

// Nav clicks: pushState updates the URL without the anchor jump (assigning
// location.hash would scroll) and doesn't fire hashchange, so navigate here
document.addEventListener("click", e => {
    const nav = e.target.closest?.("[data-carbon-nav]");
    if (!nav || !app()) return;
    e.preventDefault();

    const route = nav.dataset.route;
    if (window.location.hash !== `#${route}`) {
        history.pushState(null, "", `#${route}`);
    }
    navigate(route);
    scrollToTop();
});
