# carbonite (development version)

* `carbon_page()` and `carbon_header()` gain `logo`: a Carbon icon name or a
  tag (an SVG or `img()`) shown before the title. On small screens the header
  shows only the logo. The header title now stays on one line, clipping
  instead of wrapping when the header is narrow.

# carbonite 0.1.0

* Initial CRAN submission.

## Layout

* `carbon_page()`: an application shell with a header, optional side
  navigation (`carbon_sidebar()`, `carbon_nav_item()`, with icons and a
  collapsible rail), and `carbon_panel()`s switched by URL routing.
* `carbon_grid()` and `carbon_column()` for Carbon's responsive grid.
* `carbon_tabs()`, `carbon_accordion()`, `carbon_tile()`,
  `carbon_expandable_tile()`, and `carbon_content_switcher()`.

## Inputs

* Text: `carbon_text_input()`, `carbon_password_input()`,
  `carbon_textarea()`, and `carbon_number_input()`.
* Choices: `carbon_select()`, `carbon_dropdown()`, `carbon_combobox()`,
  `carbon_multiselect()`, `carbon_radio_group()`, `carbon_checkbox_group()`,
  `carbon_toggle()`, and selectable `carbon_structured_list()`s.
* `carbon_slider()`, with a two-handle range mode.
* `carbon_date_picker()`, `carbon_date_range_picker()`, and
  `carbon_time_picker()`.
* `carbon_file_uploader()`, using Shiny's own file upload.
* Actions: `carbon_button()`, `carbon_menu_button()`,
  `carbon_overflow_menu()`, and interactive tags
  (`carbon_dismissible_tag()`, `carbon_selectable_tag()`,
  `carbon_operational_tag()`).
* `update_carbon_*()` functions change inputs from the server.

## Data tables

* `carbon_table()`, `carbon_table_output()`, and `render_carbon_table()`:
  sorting by value, search, row selection with batch actions, pagination,
  expandable rows, and a loading skeleton.

## Feedback and overlays

* `show_carbon_modal()` with `carbon_modal()`.
* `show_carbon_notification()` (toasts) and `carbon_inline_notification()`.
* `carbon_progress_bar()` and `carbon_progress_indicator()`.
* `carbon_popover()` and `carbon_tag()`.

## Icons

* `carbon_icon()` gives any of the Carbon icons as inline SVG, and
  `carbon_icon_names()` searches them.

## Bundled Carbon fixes

Carbon's web components are bundled with fixes for issues that affect them in
Shiny, including date picker minimum and maximum dates, dragging the upper
handle of a range slider, and search in tables where only some rows can be
expanded.
