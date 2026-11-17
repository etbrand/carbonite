render <- function(x) as.character(htmltools::renderTags(x)$html)

menu_items <- function() {
  list(
    carbon_menu_item("edit", "Edit", icon = "edit", shortcut = "Ctrl+E"),
    carbon_menu_divider(),
    carbon_menu_item("delete", "Delete", danger = TRUE, disabled = TRUE)
  )
}

# Items ------------------------------------------------------------------------

test_that("carbon_menu_item maps its options to cds-menu-item", {
  item <- carbon_menu_item("edit", "Edit", icon = "edit", shortcut = "Ctrl+E")

  expect_equal(item$name, "cds-menu-item")
  expect_equal(attr_of(item, "label"), "Edit")
  expect_equal(attr_of(item, "data-value"), "edit")
  expect_equal(attr_of(item, "shortcut"), "Ctrl+E")
  expect_false(has_attr(item, "kind"))
  expect_false(has_attr(item, "disabled"))
  expect_equal(attr_of(find_tags(item, "svg")[[1]], "slot"), "render-icon")
})

test_that("carbon_menu_item: label defaults to value; danger and disabled", {
  item <- carbon_menu_item("delete", danger = TRUE, disabled = TRUE)

  expect_equal(attr_of(item, "label"), "delete")
  expect_equal(attr_of(item, "kind"), "danger")
  expect_true(has_attr(item, "disabled"))
  expect_length(find_tags(item, "svg"), 0)

  expect_error(carbon_menu_item(""), "value")
  expect_error(carbon_menu_item(c("a", "b")), "value")
  expect_error(carbon_menu_item(1), "value")
  expect_error(carbon_menu_item("a", disabled = "no"), "disabled")
  expect_error(carbon_menu_item("a", danger = NA), "danger")
  expect_error(carbon_menu_item("a", icon = "not-an-icon"), "Unknown Carbon icon")
})

test_that("carbon_menu_divider and carbon_submenu", {
  expect_equal(carbon_menu_divider()$name, "cds-menu-item-divider")

  sub <- carbon_submenu("Export as", carbon_menu_item("csv", "CSV"), icon = "export")

  expect_equal(sub$name, "cds-menu-item")
  expect_equal(attr_of(sub, "label"), "Export as")
  expect_false(has_attr(sub, "data-value"))

  # Carbon's menu item draws the submenu's cds-menu; the slot takes a group
  group <- find_tags(sub, "cds-menu-item-group")[[1]]
  expect_equal(attr_of(group, "slot"), "submenu")
  expect_equal(attr_of(group, "label"), "Export as")
  expect_equal(attr_of(find_tags(group, "cds-menu-item")[[1]], "data-value"), "csv")
  expect_length(find_tags(sub, "cds-menu"), 0)

  expect_error(carbon_submenu("x", htmltools::div()), "Menu items")
})

# Menu button ------------------------------------------------------------------

test_that("carbon_menu_button wraps its items in a cds-menu", {
  mb <- carbon_menu_button("actions", "Actions", menu_items())

  expect_equal(mb$name, "cds-menu-button")
  expect_equal(attr_of(mb, "id"), "actions")
  expect_equal(attr_of(mb, "class"), "carbonite-menu")
  expect_equal(attr_of(mb, "label"), "Actions")
  expect_equal(attr_of(mb, "kind"), "primary")
  expect_equal(attr_of(mb, "size"), "lg")
  expect_equal(attr_of(mb, "menu-alignment"), "bottom")
  expect_false(has_attr(mb, "disabled"))

  menu <- htmltools::tagQuery(mb)$children("cds-menu")$selectedTags()
  expect_length(menu, 1)
  expect_equal(attr_of(menu[[1]], "label"), "Actions")
  expect_length(find_tags(mb, "cds-menu > cds-menu-item"), 2)
  expect_length(find_tags(mb, "cds-menu > cds-menu-item-divider"), 1)
})

test_that("carbon_menu_button options, and items as separate arguments or NULL", {
  mb <- carbon_menu_button(
    "m", "More",
    carbon_menu_item("a"),
    NULL,
    htmltools::tagList(carbon_menu_item("b"), carbon_menu_item("c")),
    kind = "ghost", size = "sm", menu_alignment = "top-end", disabled = TRUE
  )

  expect_equal(attr_of(mb, "kind"), "ghost")
  expect_equal(attr_of(mb, "size"), "sm")
  expect_equal(attr_of(mb, "menu-alignment"), "top-end")
  expect_true(has_attr(mb, "disabled"))
  expect_equal(
    vapply(find_tags(mb, "cds-menu-item"), attr_of, character(1), "data-value"),
    c("a", "b", "c")
  )
})

test_that("menus validate their items", {
  expect_error(carbon_menu_button("m", "M"), "at least one item")
  expect_error(carbon_menu_button("m", "M", htmltools::div()), "Menu items")
  expect_error(carbon_menu_button("m", "M", "text"), "Menu items")
  expect_error(
    carbon_menu_button("m", "M", carbon_menu_item("a"), carbon_submenu("S", carbon_menu_item("a"))),
    "unique"
  )
  expect_error(carbon_menu_button("m", "M", carbon_menu_item("a"), kind = "secondary"))
  expect_error(carbon_menu_button("m", "M", carbon_menu_item("a"), disabled = "no"), "disabled")
})

# Overflow menu ----------------------------------------------------------------

test_that("carbon_overflow_menu uses Carbon's cds-menu mode and an icon", {
  om <- carbon_overflow_menu("row", menu_items())

  expect_equal(om$name, "cds-overflow-menu")
  expect_equal(attr_of(om, "id"), "row")
  expect_equal(attr_of(om, "class"), "carbonite-menu")
  expect_equal(attr_of(om, "label"), "Options")
  expect_equal(attr_of(om, "size"), "md")
  expect_equal(attr_of(om, "menu-alignment"), "bottom-start")
  expect_true(has_attr(om, "enable-v12-overflowmenu"))

  icon <- htmltools::tagQuery(om)$children("svg")$selectedTags()
  expect_length(icon, 1)
  expect_equal(attr_of(icon[[1]], "slot"), "icon")

  expect_length(htmltools::tagQuery(om)$children("cds-menu")$children("cds-menu-item")$selectedTags(), 2)
})

test_that("carbon_overflow_menu options", {
  om <- carbon_overflow_menu(
    "row", carbon_menu_item("a"),
    label = "Row actions", icon = "overflow-menu--horizontal", size = "sm", disabled = TRUE
  )

  expect_equal(attr_of(om, "label"), "Row actions")
  expect_equal(attr_of(om, "size"), "sm")
  expect_true(has_attr(om, "disabled"))
  expect_error(carbon_overflow_menu("row"), "at least one item")
  expect_error(carbon_overflow_menu("row", carbon_menu_item("a"), icon = "nope"), "Unknown Carbon icon")
})

# Update -----------------------------------------------------------------------

test_that("update_carbon_menu sends label and disabled", {
  session <- fake_session()
  msg <- capture_input_message(update_carbon_menu("m", label = "More", disabled = TRUE, session = session), session)

  expect_equal(msg$id, "m")
  expect_equal(msg$message, list(label = "More", disabled = TRUE))

  session <- fake_session()
  msg <- capture_input_message(update_carbon_menu("m", disabled = FALSE, session = session), session)
  expect_equal(msg$message, list(disabled = FALSE))

  expect_error(update_carbon_menu("m", disabled = "no", session = fake_session()), "disabled")
})
