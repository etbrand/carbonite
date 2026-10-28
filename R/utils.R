sub_id <- function(id, value) {
  paste0(id, "__", gsub("[^A-Za-z0-9_-]", "_", value))
}

normalize_choices <- function(x) {
  if (is.null(names(x))) {
    names(x) <- x
  }
  x
}

# For debugging, prints to stderr so it shows up in the R console
print2 <- function(...) {
  cat(file = stderr(), paste0(..., "\n"))
}
