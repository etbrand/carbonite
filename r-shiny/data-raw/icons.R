# Build the Carbon icon data used by carbon_icon() (saved to R/sysdata.rda).
#
# Run from the R package root (r-shiny/) after installing or updating @carbon/icons
# in the repository's srcjs/ (`cd ../srcjs && npm install`):
#
#   Rscript data-raw/icons.R
#
# The source is @carbon/icons' metadata.json, which holds, for every icon,
# the SVG descriptor Carbon generates for each size (32, 24, 20, 16). Most
# sizes reuse the 32px artwork scaled down; some icons have separate
# small-size artwork, which is why every size is kept.

metadata_path <- "../srcjs/node_modules/@carbon/icons/metadata.json"
package_path <- "../srcjs/node_modules/@carbon/icons/package.json"

stopifnot(file.exists(metadata_path))

metadata <- jsonlite::read_json(metadata_path, simplifyVector = FALSE)
icons_version <- jsonlite::read_json(package_path)$version

escape_attr <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("\"", "&quot;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

# One descriptor node ({elem, attrs, content}) as SVG markup.
node_to_svg <- function(node) {
  attrs <- node$attrs
  attr_text <- if (length(attrs)) {
    paste0(" ", names(attrs), "=\"", escape_attr(unlist(attrs)), "\"", collapse = "")
  } else {
    ""
  }
  inner <- paste(vapply(node$content, node_to_svg, character(1)), collapse = "")

  if (nzchar(inner)) {
    sprintf("<%s%s>%s</%s>", node$elem, attr_text, inner, node$elem)
  } else {
    sprintf("<%s%s/>", node$elem, attr_text)
  }
}

sizes <- c(16L, 20L, 24L, 32L)

variant_rows <- lapply(metadata$icons, function(icon) {
  outputs <- icon$output
  output_sizes <- vapply(outputs, function(o) as.character(o$descriptor$size), character(1))

  rows <- lapply(sizes, function(size) {
    output <- outputs[output_sizes == as.character(size)]

    # A few icons exist only as a "glyph" (e.g. small carets): use it at
    # every size.
    if (!length(output)) {
      output <- outputs[output_sizes == "glyph"]
    }
    if (!length(output)) {
      return(NULL)
    }

    descriptor <- output[[1]]$descriptor
    data.frame(
      name = icon$name,
      size = size,
      view_box = descriptor$attrs$viewBox,
      svg = paste(vapply(descriptor$content, node_to_svg, character(1)), collapse = "")
    )
  })

  do.call(rbind, rows)
})

icon_variants <- do.call(rbind, variant_rows)

icon_index <- data.frame(
  name = vapply(metadata$icons, `[[`, character(1), "name"),
  friendly_name = vapply(metadata$icons, function(i) i$friendlyName %||% i$name, character(1)),
  aliases = vapply(
    metadata$icons,
    function(i) paste(unlist(i$aliases), collapse = "|"),
    character(1)
  ),
  category = vapply(metadata$icons, function(i) i$category %||% NA_character_, character(1)),
  deprecated = vapply(metadata$icons, function(i) isTRUE(i$deprecated), logical(1))
)

stopifnot(
  !anyDuplicated(icon_index$name),
  all(icon_index$name %in% icon_variants$name),
  !anyNA(icon_variants$svg)
)

# Most icons use the same artwork at every size (2705 of 2775 in @carbon/icons
# 11.89), so store each distinct artwork once, with the sizes it's for:
# `sizes` is e.g. "16,20,24,32". All in one data frame, rather than one per
# icon, whose attributes would add as much as the artwork. This keeps the
# package small.
artworks <- aggregate(
  size ~ name + view_box + svg,
  data = icon_variants,
  FUN = function(s) paste(sort(s), collapse = ",")
)
names(artworks)[names(artworks) == "size"] <- "sizes"

stopifnot(
  # Every icon still has exactly one artwork for each size
  all(table(unlist(lapply(seq_len(nrow(artworks)), function(i) {
    paste(artworks$name[[i]], strsplit(artworks$sizes[[i]], ",")[[1]])
  }))) == 1),
  nrow(icon_variants) == sum(lengths(strsplit(artworks$sizes, ",")))
)

artworks <- artworks[order(match(artworks$name, icon_index$name)), ]
rownames(artworks) <- NULL

carbon_icon_data <- list(
  version = icons_version,
  index = icon_index,
  artworks = artworks[c("name", "sizes", "view_box", "svg")]
)

save(carbon_icon_data, file = "R/sysdata.rda", compress = "xz")

message(sprintf(
  "Saved %d icons from @carbon/icons %s to R/sysdata.rda (%.0f KB).",
  nrow(icon_index),
  icons_version,
  file.size("R/sysdata.rda") / 1024
))
