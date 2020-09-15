# Divvun Manager for macOS

[![Build Status](https://github.com/divvun/divvun-installer-macos/workflows/CI/badge.svg)](https://github.com/divvun/divvun-installer-macos/actions)

## Building

`xcodebuild`

## Generating Localisations

This project uses [bbqsrc/strut-icu](https://github.com/bbqsrc/strut-icu) to manage the generation of localisations.

If you make an update to anything in `Sources/Support/LocalisationResources/`, run from the `Pahkat/` directory:

```
strut-icu-generate swift Support/LocalisationResources/base.yaml Support/LocalisationResources/{your other langs}.yaml
-o .
```

## License

GPLv3 — see LICENSE file.
