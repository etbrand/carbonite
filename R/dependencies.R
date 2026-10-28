carbon_dependency <- function() {
  htmltools::htmlDependency(
    name = "carbon",
    version = "1.0.0",
    src = system.file(
      "www/carbon",
      package = "carbonite"
    ),
    script = "carbonite.min.js",
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
