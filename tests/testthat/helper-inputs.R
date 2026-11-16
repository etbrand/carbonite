# Minimal stand-in for a Shiny session that records input messages, so we can
# assert on exactly what `update_carbon_*()` sends to the JS `receiveMessage()`.
fake_session <- function(ns = shiny::NS(NULL)) {
  session <- new.env()
  session$ns <- ns
  session$messages <- list()
  session$sendInputMessage <- function(inputId, message) {
    session$messages[[length(session$messages) + 1]] <- list(
      id = inputId,
      message = message
    )
  }
  session
}

# Returns the single message sent by `expr`, failing if there isn't exactly one.
capture_input_message <- function(expr, session) {
  force(expr)
  testthat::expect_length(session$messages, 1)
  session$messages[[1]]
}

# All child tags of `tag` matching a CSS selector.
find_tags <- function(tag, selector) {
  unname(htmltools::tagQuery(tag)$find(selector)$selectedTags())
}

attr_of <- function(tag, name) {
  htmltools::tagGetAttribute(tag, name)
}

has_attr <- function(tag, name) {
  htmltools::tagHasAttribute(tag, name)
}
