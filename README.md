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

## Cleanup MacDivvun

If for some reason [MacDivvun](https://github.com/divvun/macdivvun-service) has been uninstalled or
removed without the help of Divvun Manager, it can't be fixed automatically by it.
To fix a situation like this, do as follows:

- add the following url to the repo list in the Divvun Manager settings: <https://pahkat.uit.no/tools>
- a section **Divvun Tools** should appear at the end of the **All Repositories** listing
- uninstall **MacDivvun Speller Engine** by checkmarking it and run uninstall
- reinstall **MacDivvun Speller Engine** by checkmarking it and run install
- restart your computer

It should really not be necessary to do this. If it happens more than once, try to notice what caused it to happen, and file a bug report in [issues](/divvun-manager-macos/issues).

## License

GPLv3 — see LICENSE file.
