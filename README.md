# Divvun Manager for macOS

[![Build Status](https://github.com/divvun/divvun-installer-macos/workflows/CI/badge.svg)](https://github.com/divvun/divvun-installer-macos/actions)

## Download

- [Stable](https://pahkat.uit.no/divvun-installer/download/divvun-installer?platform=macos)
- [Nightly build](https://pahkat.uit.no/divvun-installer/download/divvun-installer?channel=nightly&platform=macos)

## Building

`xcodebuild`

## Generating Localisations

This project uses [bbqsrc/strut-icu](https://github.com/bbqsrc/strut-icu) to manage the generation of localisations.

If you make an update to anything in `Sources/Support/LocalisationResources/`, run from the `Pahkat/` directory:

```
strut-icu-generate swift Support/LocalisationResources/base.yaml Support/LocalisationResources/{your other langs}.yaml
-o .
```

## Localisation of entries

- language names: [make PR here](https://github.com/bbqsrc/iso639-databases)
- package names/descriptions:
    - keyboards: add entries in `keyboard-XXX/XXX.kbdgen/project.yaml`
    - spellers: add entries in `lang-XXX/manifest.toml.in` (not yet supported)

## Logging
Log files can be bundled and exported in the help menu. It gather log files from Divvun Manager, Pahkatd and MacDivvun.
Since the app is running as user, all log folders need to be accessible by others. (Pahkatd service checks folder permission on every launch)
## License

GPLv3 — see LICENSE file.
