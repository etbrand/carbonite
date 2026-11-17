# Every exported component should carry the Carbon bundle so it works outside
# `carbon_page()` (e.g. in renderUI(), R Markdown, or another page layout).

expect_carbon_dependency <- function(x) {
  deps <- htmltools::findDependencies(x)
  dep_names <- vapply(deps, `[[`, "", "name")

  expect_true("carbon" %in% dep_names)
}

test_that("input components attach the carbon dependency", {
  expect_carbon_dependency(carbon_button("x", "X"))
  expect_carbon_dependency(carbon_select("x", choices = "a"))
  expect_carbon_dependency(carbon_text_input("x"))
  expect_carbon_dependency(carbon_number_input("x"))
  expect_carbon_dependency(carbon_checkbox_group("x", choices = "a"))
  expect_carbon_dependency(carbon_radio_group("x", choices = "a"))
  expect_carbon_dependency(carbon_dropdown("x", choices = "a"))
  expect_carbon_dependency(carbon_combobox("x", choices = "a"))
  expect_carbon_dependency(carbon_multiselect("x", choices = "a"))
  expect_carbon_dependency(carbon_toggle("x"))
})

test_that("layout and display components attach the carbon dependency", {
  expect_carbon_dependency(carbon_tag("Label"))
  expect_carbon_dependency(carbon_tile("x"))
  expect_carbon_dependency(carbon_button("x", "X", icon = "add"))
  expect_carbon_dependency(carbon_tile("x", href = "#"))
  expect_carbon_dependency(carbon_expandable_tile("s", "b"))
  expect_carbon_dependency(carbon_accordion_item("t", "b"))
  expect_carbon_dependency(carbon_accordion(carbon_accordion_item("t", "b")))
  expect_carbon_dependency(carbon_header())
  expect_carbon_dependency(carbon_sidebar())
  expect_carbon_dependency(carbon_nav_item("home", "Home"))
  expect_carbon_dependency(carbon_tabs("t", carbon_tab("a", "A")))
  expect_carbon_dependency(carbon_grid())
  expect_carbon_dependency(carbon_column(width = 4))
  expect_carbon_dependency(carbon_table(data.frame(a = 1)))
  expect_carbon_dependency(carbon_table(data.frame(a = 1), selection = "multiple", toolbar = carbon_table_toolbar()))
  expect_carbon_dependency(carbon_table_output("tbl"))
  expect_carbon_dependency(carbon_modal("x"))
  expect_carbon_dependency(carbon_modal_close_button())
  expect_carbon_dependency(carbon_inline_notification("x"))
})

test_that("the carbon dependency is only rendered once for many components", {
  ui <- htmltools::tagList(
    carbon_button("a", "A"),
    carbon_button("b", "B"),
    carbon_select("c", choices = "x")
  )

  rendered <- htmltools::renderTags(ui)
  dep_names <- vapply(
    htmltools::resolveDependencies(rendered$dependencies),
    `[[`, "", "name"
  )

  expect_equal(sum(dep_names == "carbon"), 1)
})
