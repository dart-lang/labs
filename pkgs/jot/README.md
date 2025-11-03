[![package:jot](https://github.com/dart-lang/labs/actions/workflows/jot.yml/badge.svg)](https://github.com/dart-lang/labs/actions/workflows/jot.yml)

An experimental documentation generator for Dart.

## What's this?

An experimental documentation generator for Dart; the main design features are:

- fast generation
- output one page per library and per class (instead of a page per symbol)
- output rendered in a SPA web app
- few configuration options for the CLI tool
- designed to be used as a library for sophisticated use cases (documenting the
  Dart SDK, the Flutter SDK, ...)

## Status: experimental

**NOTE**: This package is currently experimental and published under the
[labs.dart.dev](https://dart.dev/dart-team-packages) pub publisher in order to
solicit feedback.

For packages in the labs.dart.dev publisher we generally plan to either graduate
the package into a supported publisher (dart.dev, tools.dart.dev) after a period
of feedback and iteration, or discontinue the package. These packages have a
much higher expected rate of API and breaking changes.

Your feedback is valuable and will help us evolve this package. For general
feedback, suggestions, and comments, please file an issue in the
[bug tracker](https://github.com/dart-lang/labs/issues).

## Command-line usage

```
Generate API documentation for Dart projects.

usage: dart bin/jot.dart <options> [<directory>]

-h, --help             Print this command help.
-o, --output           Configure the output directory.
                       (defaults to "doc/api")
    --[no-]markdown    Include LLM-friendly markdown summaries of the API.
                       (defaults to on)
    --serve=<port>     Serve live docs from the documented package.
                       This serves on localhost and is useful for previewing docs while working on them.
```

## Markdown API summaries

Markdown summaries of the package's libraries are emitted into doc/api.
These are designed for use by agents and LLMs. They are a token dense
representation of the API; for example, for most symbols, the first markdown
sentence of the symbol is used (instead of the full dartdoc text). In a future
version, code examples in the documentation will be preserved as these are
valuable to LLMs.

## Infima and Docusaurus

The CSS page layout for this API generator are sourced from the
[Docusaurus](https://docusaurus.io/) project.
