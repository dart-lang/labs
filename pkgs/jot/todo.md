# TODO

- [x] script for doc'ing the dart sdk
- [x] script for doc'ing flutter
- [x] support generating package:flutter
- [x] cleaner API for generation
- [ ] support generating the flutter SDK
- [ ] libraries should have a section for symbols exported from other libs
- [ ] classes should have a section for symbols inherited from parent classes
- [ ] use pragmas to control dartdoc specific imports
- [ ] support front-matter for markdown files?
- [ ] switch over to reading the dart sdk libraries declaratively

## Model elements

- [x] item (documentable, backed by an element)
- [x] items
- [x] group and group ordering

## Testing

- [x] tests for LinkedCodeRenderer
- [x] tests for markdown signature feature
- [ ] tests for workspace code
- [ ] tests for api code
- [ ] tests for DartFormat

source code => api => generation?
source code => workspace?
we don't need to test at the html level; is the api model well-formed? can we
separately convert from api to html correctly?

### Language features

- [ ] tests for language features

## Html output

- [x] clean
- [x] small
- [ ] smaller css
- [ ] version the css (from Infima)

## Page layout and nav

- [x] dart script
- [x] full SPA
- [x] convert the left-nav to runtime generated
- [x] manage the scroll during page transitions
- [x] simplify wrappers around DOM
- [ ] ensure items in the left nav scroll into focus on page changes
- [ ] ensure we don't reload a page when navigating within the same page
- [ ] update outline view selection on page scroll

## Search

- [x] simple, comprehensive

## Server

- [x] have a server mode; allow preview of docs, and refreshing will pick up
      file changes and re-generate
- [x] test --serve; we can ping localhost and get expected pages

## Generation

- [x] no args
- [x] cli just supports documenting packages
- [x] more sophisticated use cases (dart sdk, flutter) should use the package as
      a library
- [x] fast
- [ ] configuration via a yaml file

## Fixes

- [x] have a method to convert from an element to a valid in-page ID
- [x] rename the resources directory to prevent namespace conflicts
- [ ] fix issues with top-level vars vs. getters vs setters in the model
- [ ] make sure a field is documented as a field and not as a getter and setter

## Completeness

- [ ] indicate which API members are exports from other libraries
- [ ] correctly determine where to document elements for Flutter (for things
      exported from multiple libraries)
- [ ] determine the export chain length (e.g. symbol A is exported from B, C,
      defined in D)
- [ ] support for dartdoc categories
- [ ] support for resolving qualified (foo.Bar) dartdoc references
- [ ] support for flutter phantom references
- [ ] support for dartdoc macros (`{@template foo-bar}` / `{@macro foo-bar}`)

## Other

- [x] generate a markdown file representing the package's public API
