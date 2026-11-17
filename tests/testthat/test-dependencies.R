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
