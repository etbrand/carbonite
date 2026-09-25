library(shiny)
pkgload::load_all()

ui <- carbon_page(
  title = "Claims Dashboard",

  carbon_nav(
    carbon_nav_item("overview", "Overview"),
    carbon_nav_item("reports", "Reports"),
    carbon_nav_item("admin", "Admin")
  ),

  carbon_panel("overview", h2("Overview")),

  carbon_panel("reports", h2("Reports")),

  carbon_panel("admin", h2("Admin"))
)

server <- function(
  input,
  output,
  session
) {
  output$selection <- renderText({
    paste("Selected:", input$letter)
  })
  observeEvent(input$carbon_page, {
    print(input$carbon_page)
  })
}

shinyApp(ui, server)
