function navigate(route) {
    showPanel(route);
    if (window.Shiny?.setInputValue) {
        Shiny.setInputValue(
            "carbon_page",
            route,
            { priority: "event" }
        );
    }

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
            el.classList.remove("active");
        });
    const panel = document.getElementById(id);
    if (panel) {
        panel.classList.add("active");
    }
}

document.addEventListener(
    "DOMContentLoaded",
    () => {
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
    e.preventDefault();
    const route = nav.dataset.route;
    location.hash = route;
});