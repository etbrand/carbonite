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
    h2("Reports"),
    carbonite::carbon_tabs(
      "main_tabs",
      carbon_tab(
        value = "overview",
        label = "Overview",
        h3("Overview"),
        p("This is the overview tab."),
        p("It can contain arbitrary Shiny UI elements.")
      ),

      carbon_tab(
        value = "data",
        label = "Data",
        h3("Data"),
        tableOutput("summary_table")
      ),

      carbon_tab(
        value = "settings",
        label = "Settings",
        h3("Settings"),
        textInput("name", "Name"),
        checkboxInput("notifications", "Enable notifications")
      ),

      selected = "overview"
    )
  ),
  carbonite::carbon_panel(
    "admin",
    h2("Admin")
  ),
  default_route = "reports"
)

server <- function(
  input,
  output,
  session
) {}

shinyApp(ui, server)
