test_that("carbon_file_uploader renders Carbon's button and a hidden Shiny file input", {
  fu <- carbon_file_uploader("data", label = "Upload data", description = "CSV only", accept = ".csv")

  expect_equal(fu$name, "div")
  expect_equal(attr_of(fu, "class"), "carbonite-file-uploader")
  expect_equal(attr_of(fu, "data-size"), "md")
  expect_false(has_attr(fu, "data-multiple"))

  uploader <- find_tags(fu, "cds-file-uploader")[[1]]
  expect_equal(attr_of(uploader, "label-title"), "Upload data")
  expect_equal(attr_of(uploader, "label-description"), "CSV only")

  button <- find_tags(fu, "cds-file-uploader-button")
  expect_length(button, 1)
  expect_equal(attr_of(button[[1]], "accept"), ".csv")
  expect_equal(attr_of(button[[1]], "button-kind"), "primary")
  expect_false(has_attr(button[[1]], "multiple"))
  expect_equal(button[[1]]$children[[1]], "Add file")

  # The input Shiny binds: the same id/name as fileInput() would use
  input <- find_tags(fu, "input")[[1]]
  expect_equal(attr_of(input, "type"), "file")
  expect_equal(attr_of(input, "id"), "data")
  expect_equal(attr_of(input, "name"), "data")
  expect_equal(attr_of(input, "accept"), ".csv")
  expect_true(has_attr(input, "hidden"))

  # Where Shiny's uploader reports progress and errors
  progress <- find_tags(fu, "#data_progress")[[1]]
  expect_match(attr_of(progress, "class"), "shiny-file-input-progress")
  expect_length(find_tags(progress, ".progress-bar"), 1)
})

test_that("multiple, drop zone, and other options", {
  fu <- carbon_file_uploader(
    "imgs", multiple = TRUE, accept = c("image/*", ".pdf"), drop_zone = TRUE,
    size = "sm", disabled = TRUE
  )

  expect_true(has_attr(fu, "data-multiple"))
  expect_equal(attr_of(fu, "data-size"), "sm")
  expect_length(find_tags(fu, "cds-file-uploader-button"), 0)

  drop <- find_tags(fu, "cds-file-uploader-drop-container")[[1]]
  expect_true(has_attr(drop, "multiple"))
  expect_true(has_attr(drop, "disabled"))
  expect_equal(attr_of(drop, "accept"), "image/*,.pdf")
  expect_match(drop$children[[1]], "Drag and drop")
  expect_true(has_attr(find_tags(fu, "cds-file-uploader")[[1]], "disabled"))
  expect_true(has_attr(find_tags(fu, "input")[[1]], "multiple"))
})

test_that("button labels default by mode, and can be set", {
  label_of <- function(fu) find_tags(fu, "cds-file-uploader-button")[[1]]$children[[1]]

  expect_equal(label_of(carbon_file_uploader("a", multiple = TRUE)), "Add files")
  expect_equal(label_of(carbon_file_uploader("a", button_label = "Choose CSV", button_kind = "ghost")), "Choose CSV")
  expect_equal(
    attr_of(find_tags(carbon_file_uploader("a", button_kind = "ghost"), "cds-file-uploader-button")[[1]], "button-kind"),
    "ghost"
  )
})

test_that("Shiny binds the hidden input as a file input", {
  html <- as.character(htmltools::renderTags(carbon_file_uploader("data"))$html)

  expect_match(html, '<input type="file" id="data" name="data"', fixed = TRUE)
})

test_that("carbon_file_uploader validates its arguments", {
  expect_error(carbon_file_uploader("a", multiple = "yes"), "multiple")
  expect_error(carbon_file_uploader("a", drop_zone = NA), "drop_zone")
  expect_error(carbon_file_uploader("a", disabled = 1), "disabled")
  expect_error(carbon_file_uploader("a", accept = 1), "accept")
  expect_error(carbon_file_uploader("a", button_kind = "danger"))
  expect_error(carbon_file_uploader("a", size = "xl"))
})

test_that("the uploader attaches the carbon dependency", {
  deps <- htmltools::findDependencies(carbon_file_uploader("a"))
  expect_true("carbon" %in% vapply(deps, `[[`, character(1), "name"))
})
