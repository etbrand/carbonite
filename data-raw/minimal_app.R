library(shiny)
pkgload::load_all()

ui <- carbonite::carbon_page(
  title = "My App",
  theme = "g10",
  sidebar = carbonite::carbon_sidebar(
    carbonite::carbon_nav_item(
      "overview",
      "Overview"
    ),
    carbonite::carbon_nav_item(
      "reports",
      "Reports"
    ),
    carbonite::carbon_nav_item(
      "admin",
      "Admin"
    )
  ),
  carbonite::carbon_panel(
    "overview",
    h2("Overview")
  ),
  carbonite::carbon_panel(
    "reports",
    #h2("Reports"),
    carbonite::carbon_button(
      "submit",
      "Submit",
      kind = "danger-tertiary"
    ),
    htmltools::tags$br(),
    carbonite::carbon_select(
      "species",
      "Species",
      c(
        Dog = "dog",
        Cat = "cat",
        Bird = "bird"
      ),
      size = "xs"
    )
  ),
  carbonite::carbon_panel(
    "admin",
    h2("Admin")
  )
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
  observeEvent(input$species, {
    print(input$species)
  })
}

shinyApp(ui, server)
