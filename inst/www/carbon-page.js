function navigate(route) {
    showPanel(route);
    Shiny.setInputValue(
        "carbon_page",
        route,
        { priority: "event" }
    );
}

function getDefaultRoute() {
    return document
        .getElementById("carbon-app")
        .dataset
        .defaultRoute;
}

function getCurrentRoute() {
    const route = window.location.hash.substring(1);
    return route || getDefaultRoute();
}

function showPanel(id) {
    document
        .querySelectorAll(".carbon-panel")
        .forEach(el => {
            el.hidden = true;
        });
    const panel = document.getElementById(id);
    if (panel) {
        panel.hidden = false;
    }
}

document.addEventListener(
    "DOMContentLoaded",
    () => {
        const route = getCurrentRoute();
        navigate(getCurrentRoute());
    }
);

window.addEventListener(
    "hashchange",
    () => {
        navigate(getCurrentRoute());
    }
);

document.addEventListener("click", e => {
    const nav = e.target.closest("[data-carbon-nav]");
    if (!nav) return;
    const route = nav.dataset.route;
    location.hash = route;
});