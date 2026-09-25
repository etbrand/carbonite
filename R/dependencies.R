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

carbon_page_dependency <- function() {
  htmltools::htmlDependency(
    name = "carbon-page",
    version = "0.0.1",
    src = system.file(
      "www",
      package = "carbonite"
    ),
    script = "carbon-page.js",
    stylesheet = "carbon-page.css"
  )
}
