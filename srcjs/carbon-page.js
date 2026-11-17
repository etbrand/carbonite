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

export function navigate(route) {
    if (!app()) return;

    showPanel(route);
    if (window.Shiny?.setInputValue) {
        Shiny.setInputValue("carbon_page", route, { priority: "event" });
    }
}

document.addEventListener("DOMContentLoaded", () => {
    navigate(getCurrentRoute());
});

window.addEventListener("hashchange", () => {
    navigate(getCurrentRoute());
});

document.addEventListener("click", e => {
    const nav = e.target.closest?.("[data-carbon-nav]");
    if (!nav || !app()) return;
    e.preventDefault();
    location.hash = nav.dataset.route;
});
