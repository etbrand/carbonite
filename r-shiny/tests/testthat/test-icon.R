test_that("carbon_icon() renders an inline svg from the bundled data", {
  icon <- carbon_icon("add")
  html <- as.character(icon)

  expect_equal(icon$name, "svg")
  expect_equal(attr_of(icon, "viewBox"), "0 0 32 32")
  expect_equal(attr_of(icon, "width"), "16")
  expect_equal(attr_of(icon, "height"), "16")
  expect_equal(attr_of(icon, "fill"), "currentColor")
  expect_equal(attr_of(icon, "aria-hidden"), "true")
  expect_false(has_attr(icon, "role"))
  # Same path data Carbon's own add/16 module uses
  expect_match(html, '<path d="M17 15 17 8 15 8 15 15 8 15 8 17 15 17 15 24 17 24 17 17 24 17 24 15z"/>', fixed = TRUE)
})

test_that("carbon_icon() uses Carbon's size-specific artwork", {
  small <- carbon_icon("checkmark--filled", size = 16)
  large <- carbon_icon("checkmark--filled", size = 32)

  expect_equal(attr_of(small, "viewBox"), "0 0 16 16")
  expect_equal(attr_of(large, "viewBox"), "0 0 32 32")
  expect_equal(attr_of(large, "width"), "32")
  expect_false(identical(as.character(small), as.character(large)))
})

test_that("every icon has exactly one artwork for each size", {
  # Artworks are stored once, with the sizes they're for ("16,20,24,32")
  artworks <- carbonite:::carbon_icon_data$artworks
  icon_sizes <- unlist(lapply(seq_len(nrow(artworks)), function(i) {
    paste(artworks$name[[i]], strsplit(artworks$sizes[[i]], ",", fixed = TRUE)[[1]])
  }))
  expected <- as.vector(outer(carbon_icon_names(), c(16, 20, 24, 32), paste))

  expect_setequal(icon_sizes, expected)
  expect_equal(anyDuplicated(icon_sizes), 0)
})

test_that("icons with different small-size artwork use it", {
  artworks <- carbonite:::carbon_icon_data$artworks
  several <- unique(artworks$name[duplicated(artworks$name)])
  expect_true(length(several) > 0)

  icon <- several[[1]]
  expect_false(identical(
    as.character(carbon_icon(icon, size = 16)),
    gsub('width="32" height="32"', 'width="16" height="16"', as.character(carbon_icon(icon, size = 32)), fixed = TRUE)
  ))
})

test_that("carbon_icon() with a title is announced as an image", {
  icon <- carbon_icon("warning", title = "Warning")

  expect_equal(attr_of(icon, "role"), "img")
  expect_false(has_attr(icon, "aria-hidden"))
  expect_match(as.character(icon), "<title>Warning</title>", fixed = TRUE)
})

test_that("carbon_icon() passes extra attributes through", {
  icon <- carbon_icon("add", class = "big", style = "color: red", slot = "icon")

  expect_equal(attr_of(icon, "class"), "carbon-icon big")
  expect_equal(attr_of(icon, "style"), "color: red")
  expect_equal(attr_of(icon, "slot"), "icon")
})

test_that("carbon_icon() validates its arguments", {
  expect_error(carbon_icon("add", size = 18), "size")
  expect_error(carbon_icon("add", title = 1), "title")
  expect_error(carbon_icon(c("add", "edit")), "single icon name")
  expect_error(carbon_icon(""), "single icon name")
})

test_that("unknown icon names suggest close matches and aliases", {
  # typo
  expect_error(carbon_icon("chevron-down"), "chevron--down")
  # alias ("bin" is an alias of trash-can)
  expect_error(carbon_icon("bin"), "trash-can")
  expect_error(carbon_icon("bin"), "carbon_icon_names")
  # substring
  expect_error(carbon_icon("trash"), "trash-can")
  # case
  expect_error(carbon_icon("Add"), "Did you mean \"add\"")
})

test_that("carbon_icon_names() lists and searches icons", {
  all_icons <- carbon_icon_names()

  expect_gt(length(all_icons), 2000)
  expect_true(all(c("add", "edit", "trash-can") %in% all_icons))
  expect_true("trash-can" %in% carbon_icon_names("delete"))
  expect_true(all(grepl("arrow", carbon_icon_names("^arrow--"), fixed = TRUE)))
  expect_length(carbon_icon_names("zzzz-no-such-icon"), 0)
  expect_error(carbon_icon_names(1), "pattern")
})

test_that("every icon renders at every size", {
  # Guards the generated data (data-raw/icons.R)
  for (name in carbon_icon_names()) {
    for (size in c(16, 20, 24, 32)) {
      svg <- carbon_icon(name, size = size)
      if (!nzchar(attr_of(svg, "viewBox"))) fail(paste(name, size))
    }
  }
  succeed()
})
