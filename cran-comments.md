## R CMD check results

0 errors | 0 warnings | 0 notes

* This is a new release.

## Notes for the reviewer

* **Installed size.** The installed package is about 6 MB, of which 5.2 MB is
  in `inst/www`: the bundled 'Carbon Design System' web components
  (`carbonite.min.js`, 3.5 MB) and the IBM Plex font files Carbon's styles
  use (1.5 MB). The package's components need them in the browser, and
  they're served locally so apps work offline and without a CDN.

* **Bundled third-party code.** The JavaScript, CSS and fonts in
  `inst/www/carbon` are built from third-party npm packages (IBM's Carbon
  web components, Lit, Floating UI, lodash, flatpickr) and IBM Plex fonts.
  Their copyright holders are listed in `Authors@R` (role `cph`) and in
  `inst/COPYRIGHTS`, with the full license texts in `inst/licenses/`.

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
