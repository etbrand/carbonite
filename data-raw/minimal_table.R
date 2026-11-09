library(shiny)
pkgload::load_all()

ui <- carbon_page(
  title = "Carbon Table Example",
  sidebar = carbonite::carbon_sidebar(
    carbonite::carbon_nav_item(
      "overview",
      "Overview"
    )
  ),
  carbonite::carbon_panel(
    "overview",
    carbonite::carbon_h1("Carbon H1"),
    htmltools::h1("Normal H1"),
    carbonite::carbon_button("icon_button", "", icon = "edit", kind = "ghost"),
    carbonite::carbon_number_input(
      "rows",
      label = "Rows",
      value = 5,
      min = 1,
      max = 32
    ),
    carbon_table_output(
      "table" #,
      #initial_columns = c(
      #  mpg = "MPG",
      #  cyl = "Cylinders",
      #  hp = "Horsepower",
      #  wt = "Weight"
      #)
    )
  )
)

server <- function(input, output, session) {
  output$table <- carbonite::render_carbon_table({
    Sys.sleep(1)
    carbonite::carbon_table(
      head(mtcars, input$rows),
      columns = list(
        mpg = carbon_column(
          "MPG",
          formatter = \(x) sprintf("%.1f", x),
          sortable = FALSE
        ),
        cyl = "Cylinders",
        hp = carbon_column(
          "Horsepower",
          formatter = \(x) paste0(x, " hp"),
          sortable = TRUE
        ),
        wt = carbon_column("Weight", formatter = \(x) sprintf("%.2f", x))
      ),
      size = "sm",
      sortable = TRUE
    )
  })
}

shinyApp(ui, server)
