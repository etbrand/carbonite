test_that("carbon_dependency returns valid htmlDependency", {
  dep <- carbon_dependency()
  expect_s3_class(dep, "html_dependency")
  expect_equal(dep$name, "carbon")
  expect_match(
    htmltools::renderDependencies(list(dep), srcType = "file"),
    '<script src="[^"]*carbonite.min.js" defer></script>'
  )
})

test_that("Bundled JS files actually exist in inst/www", {
  # system.file points to the files in the package directory
  js_path <- system.file("www/carbon/carbonite.min.js", package = "carbonite")

  expect_true(
    file.exists(js_path),
    info = "Bundle carbonite.min.js is missing. Run npm run build!"
  )
})

test_that("every file a dependency loads exists in the installed package", {
  for (dep in list(carbon_dependency(), carbon_page_dependency())) {
    files <- c(
      vapply(dep$script, function(s) if (is.list(s)) s$src else s, character(1)),
      unlist(dep$stylesheet)
    )
    expect_true(length(files) > 0)
    for (file in files) {
      expect_true(file.exists(file.path(dep$src$file, file)), label = paste(dep$name, file))
    }
  }
})
