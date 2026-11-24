## R CMD check results

0 errors | 0 warnings | 0 notes

* This is a new release.

## Notes for the reviewer

* **Bundled third-party code.** The JavaScript, CSS and fonts in
  `inst/www/carbon` are built from third-party npm packages (IBM's Carbon
  web components, Lit, Floating UI, lodash, flatpickr) and IBM Plex fonts.
  Their copyright holders are listed in `inst/COPYRIGHTS`, referred to by
  the `Copyright` field in DESCRIPTION, with the full license texts in
  `inst/licenses/`. IBM, the main copyright holder, is also in `Authors@R`
  (role `cph`).

* **JavaScript sources.** The non-minified sources of `carbonite.min.js` and
  `carbonite.min.css` are in the package's GitHub repository
  (<https://github.com/etbrand/carbonite/tree/main/srcjs>), with the
  instructions to rebuild them in `inst/COPYRIGHTS`. They aren't in the
  tarball, to keep the source package small and free of a non-standard
  top-level directory.

* **`\dontrun{}` examples.** The examples of the `update_carbon_*()`
  functions are in `\dontrun{}` because these functions send messages to a
  running 'shiny' session and can't run outside one. The components'
  constructors have runnable examples, and several help pages include an
  `if (interactive())` example app.

## Test environments

* Windows 11, R 4.6.2 (local)
