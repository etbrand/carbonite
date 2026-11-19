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

// Carbon's elements only get their layout once this bundle defines them,
// which is after the browser's first paint (the bundle is deferred), so the
// page would flash unstyled: the header select's options as a run of text,
// the nav links in a row, the content squeezed to the left. carbon-page.css
// keeps .carbon-app invisible until <html> has .carbon-ready, so reveal it
// once the Carbon elements in the app have rendered.
//
// This runs on DOMContentLoaded, when the deferred bundle has defined
// every element it's going to, so it waits for those elements' first
// render (Lit's updateComplete), then a frame for the browser to lay them
// out. A cds-* tag that's never defined (e.g. a plain cds-tab-panel) has no
// updateComplete and isn't waited for. If this never finishes, the CSS
// shows the page after 2s anyway. `nextFrame` is for tests.
export function revealWhenReady({
    nextFrame = () => new Promise(resolve => requestAnimationFrame(resolve)),
} = {}) {
    const root = app();
    if (!root) return Promise.resolve();

    const rendering = [...root.querySelectorAll("*")]
        .filter(el => el.localName.startsWith("cds-") && el.updateComplete)
        .map(el => el.updateComplete);
    // allSettled: an element whose render failed shouldn't keep the page
    // hidden
    return Promise.allSettled(rendering)
        .then(nextFrame)
        .then(() => document.documentElement.classList.add("carbon-ready"));
}

document.addEventListener("DOMContentLoaded", () => {
    navigate(getCurrentRoute());
    revealWhenReady();
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
