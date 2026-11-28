# carbon_button ---------------------------------------------------------------

test_that("carbon_button renders a cds-button the binding can find", {
  btn <- carbon_button("go", "Go")

  expect_equal(btn$name, "cds-button")
  expect_equal(attr_of(btn, "id"), "go")
  expect_equal(attr_of(btn, "kind"), "primary")
  expect_equal(attr_of(btn, "size"), "md")
  expect_length(find_tags(btn, "svg"), 0)
  expect_match(as.character(btn), ">Go</cds-button>", fixed = TRUE)
})

test_that("carbon_button passes icon, kind, size and extra attributes", {
  btn <- carbon_button(
    "del", "Delete",
    icon = "trash-can", kind = "danger", size = "lg", disabled = NA
  )

  icon <- find_tags(btn, "svg")
  expect_length(icon, 1)
  expect_equal(attr_of(icon[[1]], "slot"), "icon")
  expect_equal(attr_of(icon[[1]], "width"), "16")
  expect_equal(attr_of(btn, "kind"), "danger")
  expect_equal(attr_of(btn, "size"), "lg")
  expect_true(has_attr(btn, "disabled"))
  expect_match(as.character(btn), "</svg>\\s*Delete\\s*</cds-button>")
})

test_that("carbon_button accepts any Carbon icon, by name or carbon_icon()", {
  by_name <- find_tags(carbon_button("x", "X", icon = "chevron--down"), "svg")[[1]]
  by_tag <- find_tags(carbon_button("x", "X", icon = carbon_icon("chevron--down")), "svg")[[1]]

  expect_equal(attr_of(by_tag, "slot"), "icon")
  expect_equal(as.character(by_name), as.character(by_tag))
})

test_that("carbon_button rejects unknown icons in R", {
  expect_error(carbon_button("x", "X", icon = "trash"), "trash-can")
  expect_error(carbon_button("x", "X", icon = 1), "icon")
})

test_that("carbon_button validates kind and size", {
  expect_error(carbon_button("x", "X", kind = "loud"))
  expect_error(carbon_button("x", "X", size = "huge"))
})

# carbon_select ---------------------------------------------------------------

test_that("carbon_select renders one cds-select-item per choice", {
  sel <- carbon_select(
    "fruit", "Fruit",
    choices = c(Apple = "apple", Banana = "banana"),
    helper_text = "Pick one", placeholder = "Choose"
  )

  expect_equal(sel$name, "cds-select")
  expect_equal(attr_of(sel, "id"), "fruit")
  expect_equal(attr_of(sel, "label-text"), "Fruit")
  expect_equal(attr_of(sel, "helper-text"), "Pick one")
  expect_equal(attr_of(sel, "placeholder"), "Choose")
  expect_equal(attr_of(sel, "size"), "md")

  items <- find_tags(sel, "cds-select-item")
  expect_length(items, 2)
  expect_equal(vapply(items, attr_of, "", "value"), c("apple", "banana"))
  expect_match(as.character(items[[1]]), ">Apple<", fixed = TRUE)
})

test_that("carbon_select marks the selected item and sets value", {
  sel <- carbon_select("fruit", choices = c("a", "b", "c"), selected = "b")

  expect_equal(attr_of(sel, "value"), "b")
  items <- find_tags(sel, "cds-select-item")
  expect_equal(vapply(items, has_attr, logical(1), "selected"), c(FALSE, TRUE, FALSE))
})

test_that("carbon_select uses values as labels for unnamed choices", {
  sel <- carbon_select("x", choices = c("one", "two"))

  expect_match(as.character(sel), '<cds-select-item value="two">two</cds-select-item>', fixed = TRUE)
})

test_that("carbon_select starts on the first choice, like selectInput()", {
  sel <- carbon_select("x", choices = c(One = "one", Two = "two"))

  expect_equal(attr_of(sel, "value"), "one")
  items <- find_tags(sel, "cds-select-item")
  expect_equal(vapply(items, has_attr, logical(1), "selected"), c(TRUE, FALSE))

  # The first choice of grouped choices, too
  grouped <- carbon_select("g", choices = list(Fruit = c("apple", "pear"), Veg = c("leek", "kale")))
  expect_equal(attr_of(grouped, "value"), "apple")
})

test_that("carbon_select with a placeholder and no selection starts empty", {
  sel <- carbon_select("x", choices = c("one", "two"), placeholder = "Choose")

  expect_false(has_attr(sel, "value"))
  expect_false(any(vapply(find_tags(sel, "cds-select-item"), has_attr, logical(1), "selected")))

  # An explicit selection still wins over the placeholder
  expect_equal(attr_of(carbon_select("x", choices = c("one", "two"), selected = "two", placeholder = "Choose"), "value"), "two")
})

# carbon_text_input -----------------------------------------------------------

test_that("carbon_text_input renders a cds-text-input", {
  txt <- carbon_text_input(
    "name", "Name", size = "sm",
    placeholder = "Jane", helper_text = "Full name"
  )

  expect_equal(txt$name, "cds-text-input")
  expect_equal(attr_of(txt, "id"), "name")
  expect_equal(attr_of(txt, "label"), "Name")
  expect_equal(attr_of(txt, "size"), "sm")
  expect_equal(attr_of(txt, "placeholder"), "Jane")
  expect_equal(attr_of(txt, "helper-text"), "Full name")
})

test_that("carbon_text_input sets an initial value", {
  txt <- carbon_text_input("name", "Name", value = "Jane")

  expect_equal(attr_of(txt, "value"), "Jane")
})

test_that("carbon_text_input omits NULL attributes", {
  txt <- carbon_text_input("name")

  expect_false(has_attr(txt, "value"))
  expect_false(has_attr(txt, "label"))
  expect_false(has_attr(txt, "placeholder"))
  expect_false(has_attr(txt, "helper-text"))
})

# carbon_number_input ---------------------------------------------------------

test_that("carbon_number_input renders value and range attributes", {
  num <- carbon_number_input("n", "N", value = 5, min = 0, max = 10, step = 0.5)

  expect_equal(num$name, "cds-number-input")
  expect_equal(attr_of(num, "id"), "n")
  expect_equal(attr_of(num, "label"), "N")
  expect_equal(attr_of(num, "value"), "5")
  expect_equal(attr_of(num, "min"), "0")
  expect_equal(attr_of(num, "max"), "10")
  expect_equal(attr_of(num, "step"), "0.5")
})

test_that("carbon_number_input has sensible defaults", {
  num <- carbon_number_input("n")

  expect_false(has_attr(num, "value"))
  expect_equal(attr_of(num, "min"), "-100")
  expect_equal(attr_of(num, "max"), "100")
  expect_equal(attr_of(num, "step"), "1")
  expect_equal(attr_of(num, "size"), "md")
  expect_error(carbon_number_input("n", size = "xs"))
})

# carbon_checkbox_group -------------------------------------------------------

test_that("carbon_checkbox_group renders checkboxes with sub-ids", {
  grp <- carbon_checkbox_group(
    "opts", "Options",
    choices = c(Alpha = "a", `Beta Gamma` = "b c"),
    helper_text = "Pick any"
  )

  expect_equal(grp$name, "cds-checkbox-group")
  expect_equal(attr_of(grp, "id"), "opts")
  expect_equal(attr_of(grp, "legend-text"), "Options")
  expect_equal(attr_of(grp, "helper-text"), "Pick any")

  boxes <- find_tags(grp, "cds-checkbox")
  expect_length(boxes, 2)
  expect_equal(vapply(boxes, attr_of, "", "id"), c("opts__a", "opts__b_c"))
  expect_equal(vapply(boxes, attr_of, "", "value"), c("a", "b c"))
  expect_equal(vapply(boxes, attr_of, "", "label-text"), c("Alpha", "Beta Gamma"))
})

test_that("carbon_checkbox_group checks every selected value", {
  grp <- carbon_checkbox_group("opts", choices = c("a", "b", "c"), selected = c("a", "c"))

  boxes <- find_tags(grp, "cds-checkbox")
  expect_equal(vapply(boxes, has_attr, logical(1), "checked"), c(TRUE, FALSE, TRUE))
  # Boolean attribute: rendered bare, not checked="NA"
  expect_match(as.character(boxes[[1]]), 'value="a" checked>', fixed = TRUE)
})

test_that("carbon_checkbox_group with no selection checks nothing", {
  grp <- carbon_checkbox_group("opts", choices = c("a", "b"))

  boxes <- find_tags(grp, "cds-checkbox")
  expect_false(any(vapply(boxes, has_attr, logical(1), "checked")))
})

# carbon_radio_group ----------------------------------------------------------

test_that("carbon_radio_group renders radios sharing a name", {
  grp <- carbon_radio_group(
    "size", "Size",
    choices = c(Small = "s", Large = "l"),
    selected = "l"
  )

  expect_equal(grp$name, "cds-radio-button-group")
  expect_equal(attr_of(grp, "id"), "size")
  expect_equal(attr_of(grp, "legend-text"), "Size")

  radios <- find_tags(grp, "cds-radio-button")
  expect_length(radios, 2)
  expect_equal(vapply(radios, attr_of, "", "id"), c("size__s", "size__l"))
  expect_equal(vapply(radios, attr_of, "", "name"), c("size", "size"))
  expect_equal(vapply(radios, attr_of, "", "label-text"), c("Small", "Large"))
  expect_equal(vapply(radios, has_attr, logical(1), "checked"), c(FALSE, TRUE))
})

test_that("carbon_radio_group with no selection checks nothing", {
  grp <- carbon_radio_group("size", choices = c("s", "l"))

  radios <- find_tags(grp, "cds-radio-button")
  expect_false(any(vapply(radios, has_attr, logical(1), "checked")))
})

# Extra attributes ------------------------------------------------------------

test_that("input constructors forward ... as attributes", {
  expect_equal(attr_of(carbon_text_input("x", class = "wide"), "class"), "wide")
  expect_equal(attr_of(carbon_select("x", choices = "a", class = "wide"), "class"), "wide")
  expect_equal(attr_of(carbon_number_input("x", class = "wide"), "class"), "wide")
  expect_equal(attr_of(carbon_checkbox_group("x", choices = "a", class = "wide"), "class"), "wide")
  expect_equal(attr_of(carbon_radio_group("x", choices = "a", class = "wide"), "class"), "wide")
})

test_that("carbon_select groups list elements with several choices", {
  sel <- carbon_select(
    "region",
    choices = list("Whole world" = "World", Regions = c("Africa", "Asia"), Antarctica = "Antarctica"),
    selected = "Asia"
  )

  # Opening tags in order: World on its own, the group with its two
  # regions, then Antarctica on its own again
  html <- as.character(sel)
  opening <- regmatches(html, gregexpr("<cds-select-item(-group)? [^>]*>", html))[[1]]
  expect_equal(
    sub(" .*", "", opening),
    c("<cds-select-item", "<cds-select-item-group", "<cds-select-item", "<cds-select-item", "<cds-select-item")
  )
  expect_match(html, '<cds-select-item value="World">Whole world</cds-select-item>', fixed = TRUE)

  group <- find_tags(sel, "cds-select-item-group")[[1]]
  expect_equal(attr_of(group, "label"), "Regions")
  items <- find_tags(group, "cds-select-item")
  expect_equal(vapply(items, attr_of, "", "value"), c("Africa", "Asia"))
  expect_equal(vapply(items, has_attr, logical(1), "selected"), c(FALSE, TRUE))
  expect_equal(attr_of(sel, "value"), "Asia")
})

test_that("carbon_select groups need headings", {
  expect_error(carbon_select("x", choices = list("a", c("b", "c"))), "needs a name")
})

test_that("ungrouped choices render as before", {
  sel <- carbon_select("x", choices = c(A = "a", B = "b"))
  expect_length(find_tags(sel, "cds-select-item-group"), 0)
  expect_length(find_tags(sel, "cds-select-item"), 2)
})
