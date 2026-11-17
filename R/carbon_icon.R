# Icon data (`carbon_icon_data`, in R/sysdata.rda) is generated from
# @carbon/icons by data-raw/icons.R.

.carbon_icon_sizes <- c(16L, 20L, 24L, 32L)

.check_icon_name <- function(name, arg = "name", call = rlang::caller_env()) {
  if (!rlang::is_string(name) || !nzchar(name)) {
    cli::cli_abort("{.arg {arg}} must be a single icon name, like {.val add}.", call = call)
  }

  index <- carbon_icon_data$index
  if (name %in% index$name) {
    return(invisible(name))
  }

  # Suggest, in order: the same name in another case ("Add" -> add), names
  # with it as a whole word ("trash" -> trash-can), icons with it as an
  # alias ("bin" -> trash-can), other names containing it, then near-miss
  # spellings ("chevron-down" -> chevron--down).
  needle <- tolower(name)
  other_case <- index$name[tolower(index$name) == needle]
  word_pattern <- paste0("(^|-)", gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", needle), "(-|$)")
  as_word <- index$name[grepl(word_pattern, index$name)]
  by_alias <- index$name[vapply(
    strsplit(tolower(index$aliases), "|", fixed = TRUE),
    function(aliases) needle %in% aliases,
    logical(1)
  )]
  containing <- index$name[grepl(needle, index$name, fixed = TRUE)]
  containing <- containing[order(nchar(containing))]
  distance <- utils::adist(needle, index$name)[1, ]
  close <- index$name[order(distance)][sort(distance) <= max(1, nchar(needle) %/% 5)]
  suggestions <- utils::head(
    unique(c(other_case, as_word[order(nchar(as_word))], by_alias, containing, close)),
    5
  )

  cli::cli_abort(
    c(
      "Unknown Carbon icon {.val {name}}.",
      if (length(suggestions)) c("i" = "Did you mean {.or {.val {suggestions}}}?"),
      "i" = "Search the icons with {.run carbonite::carbon_icon_names(\"{name}\")}."
    ),
    call = call
  )
}

#' Carbon Icon
#'
#' Create any of the Carbon Design System's icons as an inline SVG. Only the
#' icons you use are sent to the browser.
#'
#' The icon is drawn in the current text colour (\code{fill="currentColor"}),
#' so it follows the surrounding text and the Carbon theme. Browse the icons
#' at \url{https://carbondesignsystem.com/elements/icons/library/}, or search
#' them with \code{carbon_icon_names()}.
#'
#' @param name The icon's name, e.g. \code{"add"}, \code{"trash-can"}, or
#'   \code{"chevron--down"}, as listed by \code{carbon_icon_names()}.
#' @param size The icon size in pixels: \code{16}, \code{20}, \code{24}, or
#'   \code{32}. Carbon draws some icons differently at small sizes.
#' @param title Optional accessible name. Without one, the icon is treated as
#'   decorative and hidden from screen readers.
#' @param ... Additional attributes for the \code{svg} element, e.g.
#'   \code{class} or \code{style}.
#'
#' @return An \code{svg} tag.
#'
#' @seealso \code{\link{carbon_icon_names}}
#'
#' @examples
#' carbon_icon("add")
#'
#' carbon_icon("warning--filled", size = 24, title = "Warning",
#'   style = "color: #da1e28")
#'
#' @export
carbon_icon <- function(name, size = 16, title = NULL, ...) {
  .check_icon_name(name)

  if (!is.numeric(size) || length(size) != 1 || !size %in% .carbon_icon_sizes) {
    cli::cli_abort("{.arg size} must be one of {.val {(.carbon_icon_sizes)}}.")
  }
  if (!is.null(title) && !rlang::is_string(title)) {
    cli::cli_abort("{.arg title} must be a single string or {.code NULL}.")
  }

  variants <- carbon_icon_data$variants[[name]]
  variant <- variants[variants$size == size, ]

  htmltools::tag(
    "svg",
    c(
      list(
        xmlns = "http://www.w3.org/2000/svg",
        viewBox = variant$view_box,
        width = size,
        height = size,
        fill = "currentColor",
        focusable = "false",
        preserveAspectRatio = "xMidYMid meet",
        class = "carbon-icon",
        `aria-hidden` = if (is.null(title)) "true",
        role = if (!is.null(title)) "img"
      ),
      list(...),
      list(
        if (!is.null(title)) htmltools::tags$title(title),
        htmltools::HTML(variant$svg)
      )
    )
  )
}

#' Carbon Icon Names
#'
#' List the names of the icons available to \code{carbon_icon()}, optionally
#' filtered by a search term.
#'
#' @param pattern Optional search term (a regular expression, matched
#'   case-insensitively) against each icon's name, display name, and aliases.
#'   For example, \code{"delete"} finds \code{"trash-can"}.
#'
#' @return A character vector of icon names.
#'
#' @seealso \code{\link{carbon_icon}}
#'
#' @examples
#' head(carbon_icon_names())
#'
#' carbon_icon_names("arrow")
#'
#' carbon_icon_names("delete")
#'
#' @export
carbon_icon_names <- function(pattern = NULL) {
  index <- carbon_icon_data$index

  if (is.null(pattern)) {
    return(index$name)
  }
  if (!rlang::is_string(pattern)) {
    cli::cli_abort("{.arg pattern} must be a single string or {.code NULL}.")
  }

  haystack <- paste(index$name, index$friendly_name, index$aliases, sep = "|")
  index$name[grepl(pattern, haystack, ignore.case = TRUE)]
}

# An icon for a component's `icon` slot, from a name or a carbon_icon().
.slot_icon <- function(icon, slot = "icon", size = 16, arg = "icon", call = rlang::caller_env()) {
  if (is.character(icon)) {
    .check_icon_name(icon, arg = arg, call = call)
    return(carbon_icon(icon, size = size, slot = slot))
  }
  if (inherits(icon, "shiny.tag") && identical(icon$name, "svg")) {
    return(htmltools::tagAppendAttributes(icon, slot = slot))
  }

  cli::cli_abort(
    "{.arg {arg}} must be an icon name or a {.fn carbon_icon}.",
    call = call
  )
}
