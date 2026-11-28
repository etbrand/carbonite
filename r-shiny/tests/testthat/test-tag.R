render <- function(x) as.character(htmltools::renderTags(x)$html)

# carbon_tag -------------------------------------------------------------------

test_that("carbon_tag defaults match Carbon's: gray, md", {
  tg <- carbon_tag("Beta")

  expect_equal(tg$name, "cds-tag")
  expect_equal(attr_of(tg, "type"), "gray")
  expect_equal(attr_of(tg, "size"), "md")
  expect_false(has_attr(tg, "disabled"))
  expect_false(has_attr(tg, "id"))
  # The label is the tag's content, which Carbon slots into its label span
  expect_equal(render(tg), '<cds-tag type="gray" size="md">Beta</cds-tag>')
})

test_that("carbon_tag options: type, size, icon, disabled, id, attributes", {
  tg <- carbon_tag(
    "Stable", type = "green", size = "lg", icon = "checkmark--filled",
    disabled = TRUE, id = "status", class = "x"
  )

  expect_equal(attr_of(tg, "type"), "green")
  expect_equal(attr_of(tg, "size"), "lg")
  expect_equal(attr_of(tg, "id"), "status")
  expect_equal(attr_of(tg, "class"), "x")
  expect_true(has_attr(tg, "disabled"))

  icon <- find_tags(tg, "svg")
  expect_length(icon, 1)
  expect_equal(attr_of(icon[[1]], "slot"), "icon")
  expect_match(render(tg), "</svg>\\s*Stable\\s*</cds-tag>$")
})

test_that("carbon_tag accepts every Carbon type and rejects others", {
  for (type in c("cool-gray", "warm-gray", "magenta", "high-contrast", "outline")) {
    expect_equal(attr_of(carbon_tag("x", type = type), "type"), type)
  }
  expect_error(carbon_tag("x", type = "orange"))
  expect_error(carbon_tag("x", size = "xl"))
  expect_error(carbon_tag("x", disabled = "no"), "disabled")
})

test_that("Carbon doesn't show icons on small tags, so warn", {
  expect_warning(carbon_tag("x", size = "sm", icon = "add"), "sm")
  expect_no_warning(carbon_tag("x", size = "sm"))
})

test_that("carbon_tag(dismissible = TRUE) still makes a dismissible tag", {
  tg <- carbon_tag("Filter: active", type = "blue", id = "f", dismissible = TRUE)

  expect_equal(tg$name, "cds-dismissible-tag")
  expect_equal(attr_of(tg, "id"), "f")
  expect_equal(attr_of(tg, "text"), "Filter: active")
  expect_equal(attr_of(tg, "type"), "blue")
})

# Interactive variants ---------------------------------------------------------

test_that("carbon_dismissible_tag puts the label in `text`", {
  tg <- carbon_dismissible_tag("f", "Status: open", type = "blue", size = "sm")

  expect_equal(tg$name, "cds-dismissible-tag")
  expect_equal(attr_of(tg, "id"), "f")
  expect_equal(attr_of(tg, "text"), "Status: open")
  expect_equal(attr_of(tg, "type"), "blue")
  expect_equal(attr_of(tg, "size"), "sm")
  expect_match(render(tg), "size=\"sm\"></cds-dismissible-tag>$")
  expect_error(carbon_dismissible_tag("f", htmltools::strong("x")), "single string")
})

test_that("carbon_selectable_tag has a selected state and no type", {
  off <- carbon_selectable_tag("r", "R")
  on <- carbon_selectable_tag("py", "Python", selected = TRUE, icon = "code", disabled = TRUE)

  expect_equal(off$name, "cds-selectable-tag")
  expect_equal(attr_of(off, "text"), "R")
  expect_false(has_attr(off, "selected"))
  expect_false(has_attr(off, "type"))
  expect_true(has_attr(on, "selected"))
  expect_true(has_attr(on, "disabled"))
  expect_equal(attr_of(find_tags(on, "svg")[[1]], "slot"), "icon")

  expect_error(carbon_selectable_tag("r", "R", selected = NA), "selected")
})

test_that("carbon_operational_tag", {
  tg <- carbon_operational_tag("more", "+3", type = "purple")

  expect_equal(tg$name, "cds-operational-tag")
  expect_equal(attr_of(tg, "id"), "more")
  expect_equal(attr_of(tg, "text"), "+3")
  expect_equal(attr_of(tg, "type"), "purple")
  expect_equal(attr_of(tg, "size"), "md")
})

test_that("tag variants attach the carbon dependency", {
  for (tg in list(
    carbon_tag("x"), carbon_dismissible_tag("a", "x"),
    carbon_selectable_tag("b", "x"), carbon_operational_tag("c", "x")
  )) {
    deps <- htmltools::findDependencies(tg)
    expect_true("carbon" %in% vapply(deps, `[[`, character(1), "name"))
  }
})

# update_carbon_tag ------------------------------------------------------------

test_that("update_carbon_tag sends Carbon property names", {
  session <- fake_session()
  msg <- capture_input_message(
    update_carbon_tag("t", label = "New", type = "red", selected = TRUE, disabled = FALSE, session = session),
    session
  )

  expect_equal(msg$id, "t")
  expect_equal(msg$message, list(text = "New", type = "red", selected = TRUE, disabled = FALSE))
})

test_that("update_carbon_tag sends only what changed, and validates", {
  session <- fake_session()
  msg <- capture_input_message(update_carbon_tag("t", selected = FALSE, session = session), session)
  expect_equal(msg$message, list(selected = FALSE))

  expect_error(update_carbon_tag("t", type = "orange", session = fake_session()))
  expect_error(update_carbon_tag("t", selected = "yes", session = fake_session()), "selected")
  expect_error(update_carbon_tag("t", disabled = NA, session = fake_session()), "disabled")
  expect_error(update_carbon_tag("t", label = c("a", "b"), session = fake_session()), "single string")
})
