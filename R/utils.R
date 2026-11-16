.sub_id <- function(id, value) {
  paste0(id, "__", gsub("[^A-Za-z0-9_-]", "_", value))
}

# Attach the Carbon JS/CSS bundle so components work outside `carbon_page()`.
# htmltools de-duplicates dependencies by name, so the bundle loads only once.
.with_carbon_dependency <- function(x) {
  htmltools::attachDependencies(x, carbon_dependency(), append = TRUE)
}

.build_carbon_tag <- function(name, attribs) {
  .with_carbon_dependency(htmltools::tag(name, attribs))
}

.normalize_choices <- function(x) {
  if (is.null(names(x))) {
    names(x) <- x
  }
  x
}

# For debugging, prints to stderr so it shows up in the R console
print2 <- function(...) {
  cat(file = stderr(), paste0(..., "\n"))
}
