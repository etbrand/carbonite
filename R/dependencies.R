carbon_dependency <- function() {
  htmltools::htmlDependency(
    name = "carbon",
    version = "1.0.0",
    src = system.file(
      "www/carbon",
      package = "carbonite"
    ),
    # `defer` so Carbon's elements are defined after the page is parsed:
    # otherwise an element can be upgraded before its children exist, and
    # e.g. `cds-table` caches a null header row and throws on every update.
    script = list(src = "carbonite.min.js", defer = NA),
    stylesheet = "carbonite.min.css"
  )
}

# TODO: Eventually remove this but make sure carbon_page default_route still works

carbon_page_dependency <- function() {
  htmltools::htmlDependency(
    name = "carbon-page",
    version = "0.0.1",
    src = system.file(
      "www",
      package = "carbonite"
    ),
    script = "scratch.js",
    stylesheet = "carbon-page.css"
  )
}
