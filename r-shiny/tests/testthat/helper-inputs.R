# Minimal stand-in for a Shiny session that records input messages, so we can
# assert on exactly what `update_carbon_*()` sends to the JS `receiveMessage()`.
# Like a real module session, `sendInputMessage()` applies `ns` itself, so the
# recorded id is the one that reaches the browser.
fake_session <- function(ns = shiny::NS(NULL)) {
  session <- new.env()
  session$ns <- ns
  session$messages <- list()
  session$sendInputMessage <- function(inputId, message) {
    session$messages[[length(session$messages) + 1]] <- list(
      id = ns(inputId),
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

# A session stand-in for insertUI()/removeUI(): runs flush callbacks straight
# away, in order, and records what they send (`immediate = TRUE` skips
# onFlushed, with the same result).
ui_session <- function() {
  session <- new.env()
  session$singletons <- character()
  session$sent <- list()
  session$onFlushed <- function(callback, once = TRUE) callback()
  session$sendInsertUI <- function(selector, multiple, where, content) {
    session$sent[[length(session$sent) + 1]] <- list(
      type = "insert", selector = selector, where = where, html = content$html
    )
  }
  session$sendRemoveUI <- function(selector, multiple) {
    session$sent[[length(session$sent) + 1]] <- list(
      type = "remove", selector = selector, multiple = multiple
    )
  }
  session
}
