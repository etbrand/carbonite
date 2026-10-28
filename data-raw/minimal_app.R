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
    carbonite::carbon_button(
      "submit2",
      "Submit2"
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
      size = "xs",
      placeholder = "Select species",
      helper_text = "Help me please"
    ),
    carbonite::carbon_text_input(
      "your_text",
      "Your text",
      size = "xs",
      placeholder = "Some placeholder text",
      helper_text = "Write something here"
    ),
    carbonite::carbon_checkbox_group(
      inputId = "animals",
      label = "Favorite Animals",
      choices = c(
        Dog = "dog",
        Cat = "cat",
        Bird = "bird"
      ),
      selected = c("dog", "cat"),
      helper_text = "Select all that apply."
    ),
    carbonite::carbon_number_input(
      inputId = "favorite_number",
      label = "Favorite number",
      size = "sm",
      helper_text = "Help my number"
    ),
    carbonite::carbon_radio_group(
      inputId = "animals2",
      label = "Favorite Animal",
      choices = c(
        Dog = "dog",
        Cat = "cat",
        Bird = "bird"
      ),
      selected = "bird",
      helper_text = "Select only one."
    ),
    carbonite::carbon_dropdown(
      "species2",
      "Species 2",
      c(
        Dog = "dog",
        Cat = "cat",
        Bird = "bird"
      ),
      #size = "xs",
      placeholder = "Choose something",
      helper_text = "Help me please"
    ),
    carbonite::carbon_combobox(
      "species3",
      "Species 3",
      c(
        Dog = "dog",
        Cat = "cat",
        Bird = "bird"
      ),
      placeholder = "Choose something",
      helper_text = "Help me please"
    ),
    carbonite::carbon_multiselect(
      "species4",
      "Species 4",
      c(
        Dog = "dog",
        Cat = "cat",
        Bird = "bird"
      ),
      sort_choices = TRUE,
      placeholder = "Choose something",
      helper_text = "Help me please",
      direction = "top"
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
) {
  observeEvent(
    input$submit,
    {
      print2("Submit:", input$submit)
      carbonite::update_carbon_text_input(
        "your_text",
        "new text",
        placeholder = "FSDLKJF",
        helper_text = "Unhelpful text"
      )
      carbonite::update_carbon_button("submit2", "SMUBIT")
      carbonite::update_carbon_multiselect(
        "species4",
        choices = c(One = "one", Two = "two", Three = "three")
        #,
        #selected = c("two", "three")
      )
      carbonite::update_carbon_number_input(
        "favorite_number",
        10
      )
      carbonite::update_carbon_select(
        "species",
        choices = c(One = "one", Two = "two", Three = "three")
      )
      carbonite::update_carbon_radio_group(
        inputId = "animals2",
        label = "Different Animals",
        choices = c(
          Elephant = "elephant",
          Chipmunk = "chipmunk",
          Snake = "snake"
        ),
        selected = "chipmunk",
        helper_text = "Select whatever.",
        orientation = "vertical"
      )
      carbonite::update_carbon_checkbox_group(
        inputId = "animals",
        label = "Different Animals",
        choices = c(
          Elephant = "elephant",
          Chipmunk = "chipmunk",
          Snake = "snake"
        ),
        selected = c("elephant", "snake"),
        helper_text = "Select whatever.",
        orientation = "horizontal"
      )
    },
    ignoreInit = TRUE
  )
  output$selection <- renderText({
    paste("Selected:", input$letter)
  })
  observeEvent(input$carbon_page, {
    print(input$carbon_page)
  })
  observeEvent(
    input$species4,
    {
      #print(paste("Species", input$species))
      print2("MULTISELECT UPDATED")
      print2(input$species4)
      #print("Done")
      #print2("Done")
    },
    ignoreInit = TRUE,
    ignoreNULL = FALSE
  )
  # observeEvent(input$your_text, {
  #   print2(input$your_text)
  # })
  # observeEvent(input$submit2, {
  #   print2("SUBMIT 2 UPDATED")
  # })
  # observe({
  #   print2(input$animals)
  # })
  # observeEvent(input$favorite_number, {
  #   print2(input$favorite_number)
  #   print2("Number update")
  # })
  # observe({
  #   print2(input$animals2)
  # })
  # observe({
  #   print2(input$species2)
  # })
  # observe({
  #   print2(input$species3)
  # })
  # observe({
  #   print2(input$species4)
  # })
}

shinyApp(ui, server)
